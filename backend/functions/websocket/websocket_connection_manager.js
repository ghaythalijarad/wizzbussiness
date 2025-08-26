const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, QueryCommand, DeleteCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');
const jwt = require('jsonwebtoken');

const dynamoDbClient = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
};

// Helper function to create response
function createResponse(statusCode, body) {
    return {
        statusCode,
        headers: corsHeaders,
        body: JSON.stringify(body),
    };
}

// Helper function to extract user ID from token
function getUserIdFromToken(authHeader) {
    try {
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return null;
        }
        
        const token = authHeader.substring(7);
        const decoded = jwt.decode(token);
        return decoded?.sub || decoded?.['cognito:username'] || null;
    } catch (error) {
        console.error('Error decoding token:', error);
        return null;
    }
}

module.exports.handler = async (event) => {
    console.log('WebSocket Connection Manager Handler:', JSON.stringify(event, null, 2));
    
    const { httpMethod, path, headers } = event;

    if (httpMethod === 'OPTIONS') {
        return createResponse(204, {});
    }

    try {
        // Handle virtual connection creation (POST /websocket/virtual-connection)
        if (path === '/websocket/virtual-connection' && httpMethod === 'POST') {
            const authHeader = headers.authorization || headers.Authorization;
            const userId = getUserIdFromToken(authHeader);
            
            if (!userId) {
                return createResponse(401, {
                    success: false,
                    message: 'Invalid or missing authorization token'
                });
            }

            const body = JSON.parse(event.body || '{}');
            const { connectionId, businessId, entityType, isVirtualConnection, connectedAt, ttl, source } = body;

            if (!connectionId || !businessId || !entityType) {
                return createResponse(400, {
                    success: false,
                    message: 'Missing required fields: connectionId, businessId, entityType'
                });
            }

            // Create virtual connection entry in the websocket connections table
            const connectionItem = {
                PK: `CONNECTION#${connectionId}`,
                SK: `CONNECTION#${connectionId}`,
                connectionId,
                entityType,
                connectedAt: connectedAt || new Date().toISOString(),
                ttl: ttl || Math.floor(Date.now() / 1000) + 3600, // 1 hour default
                userId: userId,
                isVirtualConnection: true,
                source: source || 'app_login',
                lastActivity: new Date().toISOString(),
                isActive: true,
                businessId: businessId,
                GSI1PK: `BUSINESS#${businessId}`,
                GSI1SK: `CONNECTION#${connectionId}`
            };

            await dynamodb.send(new PutCommand({
                TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE || 'wizzgo-dev-wss-onconnect',
                Item: connectionItem
            }));

            console.log(`✅ Virtual WebSocket connection created for business login: ${businessId}`);

            return createResponse(200, {
                success: true,
                message: 'Virtual WebSocket connection created successfully',
                connectionId: connectionId,
                businessId: businessId
            });
        }

        // Handle business connections removal (DELETE /websocket/business-connections)
        if (path === '/websocket/business-connections' && httpMethod === 'DELETE') {
            const authHeader = headers.authorization || headers.Authorization;
            const userId = getUserIdFromToken(authHeader);
            
            if (!userId) {
                return createResponse(401, {
                    success: false,
                    message: 'Invalid or missing authorization token'
                });
            }

            const body = JSON.parse(event.body || '{}');
            const { businessId, source } = body;

            if (!businessId) {
                return createResponse(400, {
                    success: false,
                    message: 'Missing required field: businessId'
                });
            }

            // Query all connections for this business
            const queryParams = {
                TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE || 'wizzgo-dev-wss-onconnect',
                IndexName: 'GSI1',
                KeyConditionExpression: 'GSI1PK = :businessPK',
                FilterExpression: 'userId = :userId OR attribute_not_exists(userId)',
                ExpressionAttributeValues: {
                    ':businessPK': `BUSINESS#${businessId}`,
                    ':userId': userId
                }
            };

            const queryResult = await dynamodb.send(new QueryCommand(queryParams));
            const connectionsToDelete = queryResult.Items || [];

            // Delete each connection
            let deletedCount = 0;
            for (const connection of connectionsToDelete) {
                try {
                    await dynamodb.send(new DeleteCommand({
                        TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE || 'wizzgo-dev-wss-onconnect',
                        Key: {
                            PK: connection.PK,
                            SK: connection.SK
                        }
                    }));
                    deletedCount++;
                } catch (deleteError) {
                    console.error('Error deleting connection:', connection.PK, deleteError);
                }
            }

            console.log(`✅ Removed ${deletedCount} WebSocket connections for business logout: ${businessId}`);

            return createResponse(200, {
                success: true,
                message: `Successfully removed ${deletedCount} WebSocket connections`,
                businessId: businessId,
                deletedCount: deletedCount,
                source: source || 'app_logout'
            });
        }

        // Handle listing business connections (GET /websocket/business-connections)
        if (path === '/websocket/business-connections' && httpMethod === 'GET') {
            const authHeader = headers.authorization || headers.Authorization;
            const userId = getUserIdFromToken(authHeader);
            
            if (!userId) {
                return createResponse(401, {
                    success: false,
                    message: 'Invalid or missing authorization token'
                });
            }

            const businessId = event.queryStringParameters?.businessId;

            if (!businessId) {
                return createResponse(400, {
                    success: false,
                    message: 'Missing query parameter: businessId'
                });
            }

            // Query all connections for this business
            const queryParams = {
                TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE || 'wizzgo-dev-wss-onconnect',
                IndexName: 'GSI1',
                KeyConditionExpression: 'GSI1PK = :businessPK',
                ExpressionAttributeValues: {
                    ':businessPK': `BUSINESS#${businessId}`
                }
            };

            const queryResult = await dynamodb.send(new QueryCommand(queryParams));
            const connections = queryResult.Items || [];

            // Filter active connections and enrich with metadata
            const currentTime = Math.floor(Date.now() / 1000);
            const activeConnections = connections.filter(conn => {
                return conn.ttl && conn.ttl > currentTime && conn.isActive !== false;
            });

            return createResponse(200, {
                success: true,
                businessId: businessId,
                totalConnections: connections.length,
                activeConnections: activeConnections.length,
                connections: activeConnections.map(conn => ({
                    connectionId: conn.connectionId,
                    entityType: conn.entityType,
                    connectedAt: conn.connectedAt,
                    isVirtual: conn.isVirtualConnection || false,
                    source: conn.source || 'unknown',
                    userId: conn.userId,
                    lastActivity: conn.lastActivity
                }))
            });
        }

        return createResponse(404, {
            success: false,
            message: 'Endpoint not found',
            path: path,
            method: httpMethod
        });

    } catch (error) {
        console.error('Error in WebSocket Connection Manager:', error);
        return createResponse(500, {
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};
