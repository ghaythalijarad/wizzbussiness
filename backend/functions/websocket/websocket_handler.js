const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, DeleteCommand, QueryCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
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
        const businessId = event.queryStringParameters?.businessId;
        const userId = event.queryStringParameters?.userId;
        const entityType = event.queryStringParameters?.entityType || (businessId ? 'merchant' : 'user');

        if (!businessId && !userId) {
            console.log('❌ Missing required parameters:', { businessId, userId });
            return { statusCode: 400, body: 'Missing businessId or userId parameter' };
        }

        const currentTime = new Date().toISOString();
        const ttl = Math.floor(Date.now() / 1000) + 3600;

        console.log('🔌 WebSocket connection attempt', { connectionId, businessId, userId, entityType });

        // Deduplicate via GSI1 (BUSINESS#<id>)
        if (businessId) {
            const existingConnections = await dynamodb.send(new QueryCommand({
                TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE,
                IndexName: 'GSI1',
                KeyConditionExpression: 'GSI1PK = :pk',
                ExpressionAttributeValues: { ':pk': `BUSINESS#${businessId}` },
                FilterExpression: 'attribute_not_exists(isStale)'
            }));

            for (const oldConn of existingConnections.Items || []) {
                if (oldConn.connectionId !== connectionId) {
                    try {
                        await dynamodb.send(new UpdateCommand({
                            TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE,
                            Key: { PK: oldConn.PK, SK: oldConn.SK },
                            UpdateExpression: 'SET isStale = :s, staleMarkedAt = :t',
                            ExpressionAttributeValues: { ':s': true, ':t': currentTime }
                        }));
                        await dynamodb.send(new DeleteCommand({
                            TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE,
                            Key: { PK: oldConn.PK, SK: oldConn.SK }
                        }));
                        console.log('🧹 Removed stale duplicate', oldConn.connectionId);
                    } catch (e) {
                        console.error('❌ Failed stale removal', oldConn.connectionId, e.message);
                    }
                }
            }
        }

        // Unified table write only
        const item = {
            PK: `CONNECTION#${connectionId}`,
            SK: `CONNECTION#${connectionId}`,
            connectionId,
            entityType,
            connectedAt: currentTime,
            ttl,
            userId: userId || businessId,
            ...(businessId ? { businessId: businessId, GSI1PK: `BUSINESS#${businessId}`, GSI1SK: `CONNECTION#${connectionId}` } : { GSI1PK: `USER#${userId}`, GSI1SK: `CONNECTION#${connectionId}` })
        };

        try {
            await dynamodb.send(new PutCommand({ TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE, Item: item }));
        } catch (putErr) {
            console.error('❌ Failed to store connection item', {
                message: putErr.message,
                name: putErr.name,
                table: process.env.WEBSOCKET_CONNECTIONS_TABLE,
                connectionId,
                hasBusinessId: !!businessId,
                region: process.env.AWS_REGION,
                stack: putErr.stack?.split('\n').slice(0, 5).join('\n')
            });
            throw putErr; // bubble to outer catch -> 500
        }
        console.log('✅ Stored unified connection');

        await sendMessageToConnection(connectionId, { type: 'CONNECTION_ESTABLISHED', connectionId, timestamp: currentTime, entityType, ...(businessId && { businessId: businessId }) });

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
async function sendMessageToMerchant(businessId, message) {
    try {
        const queryRes = await dynamodb.send(new QueryCommand({
            TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE,
            IndexName: 'GSI1',
            KeyConditionExpression: 'GSI1PK = :pk',
            ExpressionAttributeValues: { ':pk': `BUSINESS#${businessId}` },
            FilterExpression: 'attribute_not_exists(isStale)'
        }));
        const connections = queryRes.Items || [];
        await Promise.all(connections.map(c => sendMessageToConnection(c.connectionId, { ...message, timestamp: new Date().toISOString() })));
        console.log(`🔌 Message sent to ${connections.length} unified connections for business ${businessId}`);
    } catch (error) {
        console.error('Error sending message to merchant:', error);
    }
}

/**
 * Broadcast message to multiple merchants
 */
async function broadcastToMerchants(businessIds, message) {
    try {
        const promises = businessIds.map(businessId =>
            sendMessageToMerchant(businessId, message)
        );

        await Promise.all(promises);

        console.log(`🔌 Broadcast sent to ${businessIds.length} merchants`);

    } catch (error) {
        console.error('Error broadcasting to merchants:', error);
    }
}

/**
 * Remove stale connection from database
 */
async function removeStaleConnection(connectionId) {
    try {
        // Direct delete by known PK/SK
        await dynamodb.send(new DeleteCommand({
            TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE,
            Key: { PK: `CONNECTION#${connectionId}`, SK: `CONNECTION#${connectionId}` }
        }));
        console.log('🔌 Removed stale unified connection', connectionId);
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

        // Support both 'action' and legacy 'type'
        const action = message.action || message.type;
        const topic = message.topic;

        // Legacy topic prefix shim
        let effectiveTopic = topic;
        if (topic && topic.startsWith('restaurant:')) {
            const mapped = topic.replace('restaurant:', 'business:');
            console.log('⚠️ Deprecation: legacy topic prefix restaurant: -> business:', { legacy: topic, mapped });
            effectiveTopic = mapped;
        } else if (topic && topic.startsWith('merchant:')) {
            const mapped = topic.replace('merchant:', 'business:');
            console.log('⚠️ Deprecation: legacy topic prefix merchant: -> business:', { legacy: topic, mapped });
            effectiveTopic = mapped;
        }

        switch (action) {
            case 'PING':
            case 'ping':
                await sendMessageToConnection(connectionId, { type: 'PONG', timestamp: new Date().toISOString() });
                break;
            case 'SUBSCRIBE_ORDERS':
                await sendMessageToConnection(connectionId, { type: 'SUBSCRIBED', message: 'Subscribed to order updates' });
                break;
            case 'subscribe': {
                await sendMessageToConnection(connectionId, { action: 'subscribed', topic: effectiveTopic, ...(effectiveTopic !== topic ? { legacyTopic: topic } : {}) });
                break;
            }
            case 'unsubscribe': {
                await sendMessageToConnection(connectionId, { action: 'unsubscribed', topic: effectiveTopic, ...(effectiveTopic !== topic ? { legacyTopic: topic } : {}) });
                break;
            }
            default:
                console.log('Unknown message action/type:', action);
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
