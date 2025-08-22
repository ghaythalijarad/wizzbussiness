const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand, UpdateCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');
const jwt = require('jsonwebtoken');

const dynamoClient = new DynamoDBClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoClient);

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, PUT, POST, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Amz-Date, X-Api-Key, X-Amz-Security-Token',
};

const HEARTBEAT_GRACE_SECONDS = parseInt(process.env.HEARTBEAT_GRACE_SECONDS || '180'); // 3 minutes
const AUTO_OFFLINE_ENFORCE = (process.env.AUTO_OFFLINE_ENFORCE || 'true') === 'true';

// Structured logging helper
function logEvent(component, event, details = {}) {
    console.log(JSON.stringify({ component, event, timestamp: new Date().toISOString(), ...details }));
}

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
            TableName: process.env.BUSINESSES_TABLE || 'WhizzMerchants_Businesses',
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
async function updateBusinessHeartbeat(businessId, userId, connectionId) { // rename kept for compatibility
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
}

/**
 * Set business online/offline status
 * Updates the acceptingOrders field in the businesses table (primary source of truth)
 */
const setBusinessOnlineStatus = async (businessId, userId, isOnline) => {
    try {
        console.log('--- Inside setBusinessOnlineStatus ---');
        console.log('Arguments:', { businessId, userId, isOnline });

        // If attempting to go ONLINE, ensure there is at least one active real connection
        if (isOnline) {
            const status = await getBusinessOnlineStatus(businessId);
            if (!status.isOnline) { // status.isOnline reflects presence of active real connections
                logEvent('businessStatus', 'online_blocked_no_active_connections', { businessId, userId });
                return {
                    blocked: true,
                    reason: 'NO_ACTIVE_CONNECTIONS',
                    message: 'Cannot set ONLINE: no active merchant WebSocket connections detected. Connect the app (WebSocket) first.'
                };
            }
        }

        // Update acceptingOrders field in businesses table - this is the primary source of truth
        const businessUpdateParams = {
            TableName: process.env.BUSINESSES_TABLE || 'WhizzMerchants_Businesses',
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
        logEvent('businessStatus', 'status_updated', { businessId, userId, isOnline });

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

/**
 * Verify user has access to the specified business
 */
const verifyBusinessAccess = async (userId, businessId) => {
    try {
        const params = {
            TableName: process.env.BUSINESSES_TABLE || 'WhizzMerchants_Businesses',
            Key: { businessId: businessId }
        };

        const result = await dynamodb.send(new GetCommand(params));

        if (!result.Item) {
            console.log(`❌ Business ${businessId} not found`);
            return false;
        }

        // Check if user is the owner or has access
        const business = result.Item;
        const hasAccess = business.ownerId === userId ||
            business.cognitoUserId === userId ||
            business.adminUsers?.includes(userId) ||
            business.staffUsers?.includes(userId);

        console.log(`🔐 Business access check for ${userId}: ${hasAccess}`);
        console.log(`🏢 Business ownerId: ${business.ownerId}`);
        console.log(`🏢 Business cognitoUserId: ${business.cognitoUserId}`);
        return hasAccess;
    } catch (error) {
        console.error('❌ Error verifying business access:', error);
        return false;
    }
};

async function autoOfflineIfStale(businessId) {
    try {
        // Fetch current status + connections
        const status = await getBusinessOnlineStatus(businessId);
        if (!status.acceptingOrders) return { changed: false, reason: 'already_offline' };
        // If acceptingOrders true but no active connections and lastConnected older than grace -> set offline
        if (!status.isOnline) {
            const businessParams = { TableName: process.env.BUSINESSES_TABLE || 'WhizzMerchants_Businesses', Key: { businessId } };
            const businessResult = await dynamodb.send(new GetCommand(businessParams));
            const lastStatusUpdate = businessResult.Item?.lastStatusUpdate ? new Date(businessResult.Item.lastStatusUpdate).getTime() : 0;
            const nowMs = Date.now();
            if ((nowMs - lastStatusUpdate) / 1000 > HEARTBEAT_GRACE_SECONDS) {
                if (!AUTO_OFFLINE_ENFORCE) {
                    logEvent('businessStatus', 'auto_offline_skipped', { businessId, grace: HEARTBEAT_GRACE_SECONDS });
                    return { changed: false, reason: 'enforcement_disabled' };
                }
                await dynamodb.send(new UpdateCommand({
                    TableName: process.env.BUSINESSES_TABLE || 'WhizzMerchants_Businesses',
                    Key: { businessId },
                    UpdateExpression: 'SET acceptingOrders = :off, lastStatusUpdate = :ts, autoOfflineReason = :r',
                    ExpressionAttributeValues: { ':off': false, ':ts': new Date().toISOString(), ':r': 'HEARTBEAT_MISSED' }
                }));
                logEvent('businessStatus', 'auto_offline_applied', { businessId, reason: 'HEARTBEAT_MISSED' });
                return { changed: true, reason: 'HEARTBEAT_MISSED' };
            }
        }
        return { changed: false, reason: 'conditions_not_met' };
    } catch (e) {
        console.error('autoOfflineIfStale error', e);
        return { changed: false, reason: 'error' };
    }
}

exports.handler = async (event) => {
    try {
        console.log('Business Online Status Event:', JSON.stringify(event, null, 2));
        console.log('Raw body:', event.body);
        console.log('Is base64 encoded:', event.isBase64Encoded);

        const httpMethod = event.httpMethod;
        const pathParameters = event.pathParameters || {};
        const queryStringParameters = event.queryStringParameters || {};

        // Handle preflight CORS requests
        if (httpMethod === 'OPTIONS') {
            return {
                statusCode: 200,
                headers: corsHeaders,
                body: ''
            };
        }

        // Extract user information from JWT token for authenticated endpoints
        const authHeader = event.headers.Authorization || event.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return {
                statusCode: 401,
                headers: corsHeaders,
                body: JSON.stringify({ error: 'Authorization token required' })
            };
        }

        const token = authHeader.substring(7);
        let decodedToken;

        try {
            decodedToken = jwt.decode(token);
            console.log('🔐 Decoded token:', decodedToken);
        } catch (error) {
            console.error('❌ Token decode error:', error);
            return {
                statusCode: 401,
                headers: corsHeaders,
                body: JSON.stringify({ error: 'Invalid authorization token' })
            };
        }

        const userId = decodedToken.sub || decodedToken['cognito:username'];
        if (!userId) {
            return {
                statusCode: 401,
                headers: corsHeaders,
                body: JSON.stringify({ error: 'User ID not found in token' })
            };
        }

        console.log(`👤 User ID: ${userId}`);

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

                    // Verify user has access to this business
                    const hasAccess = await verifyBusinessAccess(userId, businessId);
                    if (!hasAccess) {
                        return {
                            statusCode: 403,
                            headers: corsHeaders,
                            body: JSON.stringify({ error: 'Access denied to this business' })
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

                    // Verify user has access to at least one of these businesses
                    let hasAccessToAny = false;
                    for (const businessId of businessIds) {
                        const hasAccess = await verifyBusinessAccess(userId, businessId);
                        if (hasAccess) {
                            hasAccessToAny = true;
                            break;
                        }
                    }

                    if (!hasAccessToAny) {
                        return {
                            statusCode: 403,
                            headers: corsHeaders,
                            body: JSON.stringify({ error: 'Access denied to these businesses' })
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
                    const { userId: bodyUserId, connectionId } = body;

                    if (!businessId || !bodyUserId || !connectionId) {
                        return {
                            statusCode: 400,
                            headers: corsHeaders,
                            body: JSON.stringify({
                                error: 'Business ID, user ID, and connection ID are required'
                            })
                        };
                    }

                    // Verify user has access to this business
                    const hasAccess = await verifyBusinessAccess(userId, businessId);
                    if (!hasAccess) {
                        return {
                            statusCode: 403,
                            headers: corsHeaders,
                            body: JSON.stringify({ error: 'Access denied to this business' })
                        };
                    }

                    const heartbeatResult = await updateBusinessHeartbeat(businessId, bodyUserId, connectionId);
                    // After updating heartbeat, optionally re-evaluate stale auto-offline (no-op if connections present)
                    // (Could add metrics increment here)
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
                    const { userId: bodyUserId, status } = body;

                    if (!businessId || !bodyUserId || !status) {
                        return {
                            statusCode: 400,
                            headers: corsHeaders,
                            body: JSON.stringify({
                                error: 'Business ID, user ID, and status are required'
                            })
                        };
                    }

                    // Verify user has access to this business
                    const hasAccess = await verifyBusinessAccess(userId, businessId);
                    if (!hasAccess) {
                        return {
                            statusCode: 403,
                            headers: corsHeaders,
                            body: JSON.stringify({ error: 'Access denied to this business' })
                        };
                    }

                    // Convert status string to boolean
                    const isOnline = status.toLowerCase() === 'online';
                    const statusResult = await setBusinessOnlineStatus(businessId, bodyUserId, isOnline);

                    if (statusResult.blocked) {
                        return {
                            statusCode: 409,
                            headers: corsHeaders,
                            body: JSON.stringify({
                                status: 'BLOCKED',
                                code: statusResult.reason,
                                message: statusResult.message
                            })
                        };
                    }

                    if (!statusResult.blocked && !isOnline) {
                        // When going offline manually we can log explicit action
                        logEvent('businessStatus', 'manual_offline', { businessId, userId: bodyUserId });
                    }

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

        // Before 404 return, attempt passive auto-offline for any status queries (optional)
        if (event.resource === '/businesses/{businessId}/online-status' && event.pathParameters?.businessId) {
            await autoOfflineIfStale(event.pathParameters.businessId);
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
