const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, ScanCommand, DeleteCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const { ApiGatewayManagementApiClient, PostToConnectionCommand } = require('@aws-sdk/client-apigatewaymanagementapi');

const dynamoDbClient = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);
const apiGatewayManagementApi = new ApiGatewayManagementApiClient({
    region: process.env.AWS_REGION || 'us-east-1',
    endpoint: process.env.WEBSOCKET_ENDPOINT
});

/**
 * WebSocket Service for Real-time Merchant Notifications
 * Handles WebSocket connections for web-based merchant apps
 */

/**
 * Handle WebSocket connection
 */
async function handleConnect(event) {
    try {
        const connectionId = event.requestContext.connectionId;
        const merchantId = event.queryStringParameters?.merchantId;
        const businessId = event.queryStringParameters?.businessId;
        const userId = event.queryStringParameters?.userId;
        const entityType = event.queryStringParameters?.entityType || 'user'; // 'user' for customers, 'merchant' for merchants

        // For merchants, use merchantId or businessId as the identifier
        const effectiveMerchantId = merchantId || businessId;
        const effectiveUserId = userId || effectiveMerchantId;

        if (!effectiveMerchantId && !effectiveUserId) {
            console.log('❌ Missing required parameters:', { merchantId, businessId, userId });
            return { statusCode: 400, body: 'Missing merchantId, businessId, or userId parameter' };
        }

        const currentTime = new Date().toISOString();
        const ttl = Math.floor(Date.now() / 1000) + 3600; // 1 hour TTL

        console.log(`🔌 WebSocket connection attempt:`, {
            connectionId,
            merchantId,
            businessId,
            userId,
            entityType,
            effectiveMerchantId,
            effectiveUserId
        });

        // Store connection in merchant endpoints table (existing logic)
        if (effectiveMerchantId) {
            const merchantParams = {
                TableName: process.env.MERCHANT_ENDPOINTS_TABLE,
                Item: {
                    merchantId: effectiveMerchantId,
                    endpointType: 'websocket',
                    connectionId,
                    isActive: true,
                    connectedAt: currentTime,
                    updatedAt: currentTime
                }
            };
            await dynamodb.send(new PutCommand(merchantParams));
            console.log(`✅ Stored connection in merchant endpoints table for merchant: ${effectiveMerchantId}`);
        }

        // Store connection in websocket connections table (unified tracking)
        const websocketParams = {
            TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE,
            Item: {
                PK: `CONNECTION#${connectionId}`,
                SK: `CONNECTION#${connectionId}`,
                connectionId,
                entityType,
                connectedAt: currentTime,
                ttl,
                userId: effectiveUserId,
                ...(effectiveMerchantId && {
                    businessId: effectiveMerchantId,
                    GSI1PK: `BUSINESS#${effectiveMerchantId}`,
                    GSI1SK: `CONNECTION#${connectionId}`
                }),
                ...(effectiveUserId && !effectiveMerchantId && {
                    GSI1PK: `USER#${effectiveUserId}`,
                    GSI1SK: `CONNECTION#${connectionId}`
                })
            }
        };

        await dynamodb.send(new PutCommand(websocketParams));
        console.log(`✅ Stored connection in WebSocket connections table`);

        console.log(`🔌 WebSocket connected: ${connectionId} for ${entityType}: ${effectiveUserId}${effectiveMerchantId ? ` (business: ${effectiveMerchantId})` : ''}`);

        // Send welcome message
        await sendMessageToConnection(connectionId, {
            type: 'CONNECTION_ESTABLISHED',
            message: `Connected to ${entityType === 'merchant' ? 'merchant' : 'customer'} notifications`,
            timestamp: currentTime,
            entityType,
            ...(effectiveMerchantId && { businessId: effectiveMerchantId })
        });

        return { statusCode: 200, body: 'Connected' };

    } catch (error) {
        console.error('Error handling WebSocket connection:', error);
        return { statusCode: 500, body: 'Failed to connect' };
    }
}

/**
 * Handle WebSocket disconnection
 */
async function handleDisconnect(event) {
    try {
        const connectionId = event.requestContext.connectionId;
        console.log(`🔌 WebSocket disconnecting: ${connectionId}`);

        // The primary and unified table is WEBSOCKET_CONNECTIONS_TABLE.
        // We only need to clean up the connection from this table.
        // The old MERCHANT_ENDPOINTS_TABLE is legacy and its cleanup logic was flawed,
        // causing errors that prevented the main table cleanup.

        // Remove connection from the primary websocket connections table
        const deleteParams = {
            TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE,
            Key: {
                PK: `CONNECTION#${connectionId}`,
                SK: `CONNECTION#${connectionId}`
            }
        };

        await dynamodb.send(new DeleteCommand(deleteParams));

        console.log(`✅ Successfully cleaned up connection from primary table: ${connectionId}`);

        return { statusCode: 200, body: 'Disconnected' };

    } catch (error) {
        console.error('Error handling WebSocket disconnection:', error);
        return { statusCode: 500, body: 'Failed to disconnect' };
    }
}

/**
 * Send message to specific WebSocket connection
 */
async function sendMessageToConnection(connectionId, message) {
    try {
        await apiGatewayManagementApi.send(new PostToConnectionCommand({
            ConnectionId: connectionId,
            Data: Buffer.from(JSON.stringify(message)),
        }));

        console.log(`🔌 Message sent to connection ${connectionId}`);

    } catch (error) {
        if (error.statusCode === 410) {
            // Connection is stale, remove from database
            console.log(`🔌 Stale connection removed: ${connectionId}`);
            await removeStaleConnection(connectionId);
        } else {
            console.error('Error sending WebSocket message:', error);
        }
    }
}

/**
 * Send message to all connections for a merchant
 */
async function sendMessageToMerchant(merchantId, message) {
    try {
        // Get active WebSocket connections for merchant
        const params = {
            TableName: process.env.MERCHANT_ENDPOINTS_TABLE,
            FilterExpression: 'merchantId = :merchantId AND endpointType = :type AND isActive = :active',
            ExpressionAttributeValues: {
                ':merchantId': merchantId,
                ':type': 'websocket',
                ':active': true
            }
        };

        const result = await dynamodb.send(new ScanCommand(params));
        const connections = result.Items;

        // Send message to all connections
        const promises = connections.map(connection =>
            sendMessageToConnection(connection.connectionId, {
                ...message,
                timestamp: new Date().toISOString()
            })
        );

        await Promise.all(promises);

        console.log(`🔌 Message sent to ${connections.length} connections for merchant ${merchantId}`);

    } catch (error) {
        console.error('Error sending message to merchant:', error);
    }
}

/**
 * Broadcast message to multiple merchants
 */
async function broadcastToMerchants(merchantIds, message) {
    try {
        const promises = merchantIds.map(merchantId =>
            sendMessageToMerchant(merchantId, message)
        );

        await Promise.all(promises);

        console.log(`🔌 Broadcast sent to ${merchantIds.length} merchants`);

    } catch (error) {
        console.error('Error broadcasting to merchants:', error);
    }
}

/**
 * Remove stale connection from database
 */
async function removeStaleConnection(connectionId) {
    try {
        const params = {
            TableName: process.env.MERCHANT_ENDPOINTS_TABLE,
            FilterExpression: 'connectionId = :connectionId',
            ExpressionAttributeValues: {
                ':connectionId': connectionId
            }
        };

        const result = await dynamodb.send(new ScanCommand(params));

        if (result.Items.length > 0) {
            const item = result.Items[0];
            await dynamodb.send(new DeleteCommand({
                TableName: process.env.MERCHANT_ENDPOINTS_TABLE,
                Key: {
                    merchantId: item.merchantId,
                    endpointType: 'websocket'
                }
            }));
        }

        console.log(`🔌 Removed stale connection for: ${connectionId}`);

    } catch (error) {
        console.error('Error removing stale connection:', error);
    }
}

/**
 * Handle incoming WebSocket messages
 */
async function handleMessage(event) {
    try {
        const connectionId = event.requestContext.connectionId;
        const message = JSON.parse(event.body);

        console.log(`🔌 Received message from ${connectionId}:`, message);

        // Handle different message types
        switch (message.type) {
            case 'PING':
                await sendMessageToConnection(connectionId, {
                    type: 'PONG',
                    timestamp: new Date().toISOString()
                });
                break;

            case 'SUBSCRIBE_ORDERS':
                // Subscribe to order updates (could implement filtering here)
                await sendMessageToConnection(connectionId, {
                    type: 'SUBSCRIBED',
                    message: 'Subscribed to order updates'
                });
                break;

            default:
                console.log('Unknown message type:', message.type);
        }

        return { statusCode: 200, body: 'Message processed' };

    } catch (error) {
        console.error('Error handling WebSocket message:', error);
        return { statusCode: 500, body: 'Failed to process message' };
    }
}

/**
 * Main handler for WebSocket events
 */
async function handler(event) {
    const routeKey = event.requestContext.routeKey;

    console.log(`🔌 WebSocket event: ${routeKey}`, {
        connectionId: event.requestContext.connectionId,
        eventType: event.requestContext.eventType
    });

    switch (routeKey) {
        case '$connect':
            return await handleConnect(event);
        case '$disconnect':
            return await handleDisconnect(event);
        case '$default':
            return await handleMessage(event);
        default:
            console.log('Unknown route:', routeKey);
            return { statusCode: 404, body: 'Route not found' };
    }
}

module.exports = {
    handler,
    handleConnect,
    handleDisconnect,
    handleMessage,
    sendMessageToConnection,
    sendMessageToMerchant,
    broadcastToMerchants,
    removeStaleConnection
};
