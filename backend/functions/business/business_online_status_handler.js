const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand, UpdateCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');

const dynamoClient = new DynamoDBClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoClient);

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, PUT, POST, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Amz-Date, X-Api-Key, X-Amz-Security-Token',
};

/**
 * Get business online status by checking real WebSocket connections and acceptingOrders field
 */
const getBusinessOnlineStatus = async (businessId) => {
    try {
        // 1. Check for real WebSocket connections (not virtual ones)
        const connectionParams = {
            TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE,
            IndexName: 'GSI1',
            KeyConditionExpression: 'GSI1PK = :businessPK',
            FilterExpression: 'entityType = :merchantType AND attribute_not_exists(isVirtualConnection)',
            ExpressionAttributeValues: {
                ':businessPK': `BUSINESS#${businessId}`,
                ':merchantType': 'merchant'
            }
        };

        const connectionResult = await dynamodb.send(new QueryCommand(connectionParams));

        // Check if any real connections are still valid (not expired)
        const currentTime = Math.floor(Date.now() / 1000);
        const activeRealConnections = connectionResult.Items?.filter(item =>
            item.ttl && item.ttl > currentTime && !item.isVirtualConnection
        ) || [];

        const hasActiveRealConnections = activeRealConnections.length > 0;

        // 2. Check acceptingOrders field in businesses table (primary source of truth)
        const businessParams = {
            TableName: process.env.BUSINESSES_TABLE || 'order-receiver-businesses-dev',
            Key: {
                businessId: businessId
            },
            ProjectionExpression: 'acceptingOrders, lastStatusUpdate'
        };

        const businessResult = await dynamodb.send(new GetCommand(businessParams));
        const business = businessResult.Item;

        const acceptingOrders = business?.acceptingOrders ?? false;

        console.log(`Business ${businessId} status: hasActiveRealConnections=${hasActiveRealConnections}, acceptingOrders=${acceptingOrders}`);

        return {
            isOnline: hasActiveRealConnections,
            acceptingOrders: acceptingOrders,
            activeConnections: activeRealConnections.length,
            lastConnected: activeRealConnections.length > 0 ?
                activeRealConnections[0].connectedAt : null,
            lastStatusUpdate: business?.lastStatusUpdate || null,
            connections: activeRealConnections.map(conn => ({
                connectionId: conn.connectionId,
                connectedAt: conn.connectedAt,
                userId: conn.userId
            }))
        };
    } catch (error) {
        console.error('Error getting business online status:', error);
        throw error;
    }
};

/**
 * Get multiple businesses online status
 */
const getMultipleBusinessesStatus = async (businessIds) => {
    try {
        const statusPromises = businessIds.map(businessId =>
            getBusinessOnlineStatus(businessId).then(status => ({
                businessId,
                ...status
            }))
        );

        return await Promise.all(statusPromises);
    } catch (error) {
        console.error('Error getting multiple businesses status:', error);
        throw error;
    }
};

/**
 * Update business heartbeat
 */
const updateBusinessHeartbeat = async (businessId, userId, connectionId) => {
    try {
        const currentTime = Math.floor(Date.now() / 1000);
        const ttl = currentTime + 300; // 5 minutes from now

        const params = {
            TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE,
            Key: {
                PK: `CONNECTION#${connectionId}`,
                SK: `CONNECTION#${connectionId}`
            },
            UpdateExpression: 'SET connectedAt = :timestamp, ttl = :ttl, lastHeartbeat = :heartbeat',
            ExpressionAttributeValues: {
                ':timestamp': new Date().toISOString(),
                ':ttl': ttl,
                ':heartbeat': new Date().toISOString()
            }
        };

        await dynamodb.send(new UpdateCommand(params));

        return {
            businessId,
            userId,
            connectionId,
            heartbeatTime: new Date().toISOString(),
            ttl
        };
    } catch (error) {
        console.error('Error updating business heartbeat:', error);
        throw error;
    }
};

/**
 * Set business online/offline status
 * Updates the acceptingOrders field in the businesses table (primary source of truth)
 */
const setBusinessOnlineStatus = async (businessId, userId, isOnline) => {
    try {
        console.log('--- Inside setBusinessOnlineStatus ---');
        console.log('Arguments:', { businessId, userId, isOnline });

        // Update acceptingOrders field in businesses table - this is the primary source of truth
        const businessUpdateParams = {
            TableName: process.env.BUSINESSES_TABLE || 'order-receiver-businesses-dev',
            Key: {
                businessId: businessId
            },
            UpdateExpression: 'SET acceptingOrders = :acceptingOrders, lastStatusUpdate = :timestamp',
            ExpressionAttributeValues: {
                ':acceptingOrders': isOnline,
                ':timestamp': new Date().toISOString()
            }
        };

        console.log(`🔄 Updating business ${businessId} acceptingOrders field to ${isOnline}`);
        await dynamodb.send(new UpdateCommand(businessUpdateParams));
        console.log(`✅ Successfully updated acceptingOrders to ${isOnline} for business ${businessId}`);

        return {
            businessId,
            userId,
            isOnline: isOnline,
            acceptingOrders: isOnline,
            statusSetAt: new Date().toISOString()
        };
    } catch (error) {
        console.error('Error setting business online status:', error);
        throw error;
    }
};

exports.handler = async (event) => {
    try {
        console.log('Business Online Status Event:', JSON.stringify(event, null, 2));
        console.log('Raw body:', event.body);
        console.log('Is base64 encoded:', event.isBase64Encoded);

        const httpMethod = event.httpMethod;
        const pathParameters = event.pathParameters || {};
        const queryStringParameters = event.queryStringParameters || {};

        switch (httpMethod) {
            case 'GET': {
                if (event.resource === '/businesses/{businessId}/online-status') {
                    // Get single business online status
                    const { businessId } = pathParameters;

                    if (!businessId) {
                        return {
                            statusCode: 400,
                            headers: corsHeaders,
                            body: JSON.stringify({
                                error: 'Business ID is required'
                            })
                        };
                    }

                    const status = await getBusinessOnlineStatus(businessId);

                    return {
                        statusCode: 200,
                        headers: corsHeaders,
                        body: JSON.stringify({
                            businessId,
                            ...status,
                            estimatedResponseTime: status.isOnline ? '2-5 minutes' : 'Offline'
                        })
                    };
                } else if (event.resource === '/businesses/nearby/online') {
                    // Get multiple businesses online status
                    const businessIds = queryStringParameters.businessIds ?
                        queryStringParameters.businessIds.split(',') : [];

                    if (businessIds.length === 0) {
                        return {
                            statusCode: 400,
                            headers: corsHeaders,
                            body: JSON.stringify({
                                error: 'Business IDs are required as comma-separated values'
                            })
                        };
                    }

                    const businessesStatus = await getMultipleBusinessesStatus(businessIds);

                    return {
                        statusCode: 200,
                        headers: corsHeaders,
                        body: JSON.stringify({
                            businesses: businessesStatus,
                            totalBusinesses: businessesStatus.length,
                            onlineBusinesses: businessesStatus.filter(b => b.isOnline).length
                        })
                    };
                }
                break;
            }

            case 'PUT': {
                if (event.resource === '/businesses/{businessId}/heartbeat') {
                    // Update business heartbeat
                    const { businessId } = pathParameters;
                    const body = JSON.parse(event.body || '{}');
                    const { userId, connectionId } = body;

                    if (!businessId || !userId || !connectionId) {
                        return {
                            statusCode: 400,
                            headers: corsHeaders,
                            body: JSON.stringify({
                                error: 'Business ID, user ID, and connection ID are required'
                            })
                        };
                    }

                    const heartbeatResult = await updateBusinessHeartbeat(businessId, userId, connectionId);

                    return {
                        statusCode: 200,
                        headers: corsHeaders,
                        body: JSON.stringify({
                            message: 'Heartbeat updated successfully',
                            data: heartbeatResult
                        })
                    };
                } else if (event.resource === '/businesses/{businessId}/status') {
                    // Set business online/offline status
                    const { businessId } = pathParameters;

                    // Handle base64 encoded body if needed
                    let bodyString = event.body || '{}';
                    if (event.isBase64Encoded) {
                        bodyString = Buffer.from(bodyString, 'base64').toString('utf-8');
                    }

                    const body = JSON.parse(bodyString);
                    const { userId, status } = body;

                    if (!businessId || !userId || !status) {
                        return {
                            statusCode: 400,
                            headers: corsHeaders,
                            body: JSON.stringify({
                                error: 'Business ID, user ID, and status are required'
                            })
                        };
                    }

                    // Convert status string to boolean
                    const isOnline = status.toLowerCase() === 'online';
                    const statusResult = await setBusinessOnlineStatus(businessId, userId, isOnline);

                    return {
                        statusCode: 200,
                        headers: corsHeaders,
                        body: JSON.stringify({
                            status: isOnline ? 'ONLINE' : 'OFFLINE',
                            message: `Business status updated to ${isOnline ? 'online' : 'offline'}`,
                            data: statusResult
                        })
                    };
                }
                break;
            }

            case 'OPTIONS':
                return {
                    statusCode: 200,
                    headers: corsHeaders,
                    body: ''
                };

            default:
                return {
                    statusCode: 405,
                    headers: corsHeaders,
                    body: JSON.stringify({
                        error: 'Method not allowed'
                    })
                };
        }

        return {
            statusCode: 404,
            headers: corsHeaders,
            body: JSON.stringify({
                error: 'Endpoint not found'
            })
        };

    } catch (error) {
        console.error('Handler error:', error);
        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({
                error: 'Internal server error',
                message: error.message
            })
        };
    }
};
