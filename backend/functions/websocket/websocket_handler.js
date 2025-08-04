const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, ScanCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');
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

        if (!merchantId) {
            return { statusCode: 400, body: 'Missing merchantId parameter' };
        }

        // Store connection in DynamoDB
        const params = {
            TableName: process.env.MERCHANT_ENDPOINTS_TABLE,
            Item: {
                merchantId,
                endpointType: 'websocket',
                connectionId,
                isActive: true,
                connectedAt: new Date().toISOString(),
                updatedAt: new Date().toISOString()
            }
        };

        await dynamodb.send(new PutCommand(params));

        console.log(`🔌 WebSocket connected: ${connectionId} for merchant: ${merchantId}`);

        // Send welcome message
        await sendMessageToConnection(connectionId, {
            type: 'CONNECTION_ESTABLISHED',
            message: 'Connected to order notifications',
            timestamp: new Date().toISOString()
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

        // Remove connection from DynamoDB - use scan instead of query with index
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

        console.log(`🔌 WebSocket disconnected: ${connectionId}`);

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
