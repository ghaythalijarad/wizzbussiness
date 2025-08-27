const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, UpdateCommand, GetCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');
const jwt = require('jsonwebtoken');

// Import WebSocket service
const WebSocketService = require('../websocket/websocket_service');

const dynamoDbClient = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
};

/**
 * Business Online Status Handler
 * 
 * Professional WebSocket-integrated business status management
 * 
 * Endpoints:
 * - PUT /businesses/{businessId}/status - Toggle online/offline status
 * - GET /businesses/{businessId}/status - Get current status
 * - POST /businesses/{businessId}/heartbeat - Update connection heartbeat
 * - GET /businesses/status/bulk - Get status for multiple businesses
 */

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

/**
 * Handle business status toggle (online/offline)
 */
async function handleBusinessStatusToggle(event) {
    try {
        const { businessId } = event.pathParameters;
        const authHeader = event.headers.Authorization || event.headers.authorization;
        const userId = getUserIdFromToken(authHeader);

        if (!userId) {
            return createResponse(401, {
                success: false,
                message: 'Invalid or missing authorization token'
            });
        }

        // Parse request body
        let bodyString = event.body || '{}';
        if (event.isBase64Encoded) {
            bodyString = Buffer.from(bodyString, 'base64').toString('utf-8');
        }

        const body = JSON.parse(bodyString);
        const { status, source } = body;

        if (!businessId || !status) {
            return createResponse(400, {
                success: false,
                message: 'Business ID and status are required'
            });
        }

        const isOnline = status === 'online' || status === true;

        console.log(`🔄 Business status toggle: ${businessId} -> ${isOnline ? 'online' : 'offline'} (user: ${userId})`);

        // Use WebSocket service to set business availability
        const result = await WebSocketService.setBusinessAvailability(
            businessId, 
            userId, 
            isOnline,
            {
                source: source || 'manual_toggle'
            }
        );

        // Get updated comprehensive status
        const comprehensiveStatus = await WebSocketService.getBusinessStatus(businessId);

        console.log(`✅ Business status updated successfully: ${businessId}`);

        return createResponse(200, {
            success: true,
            message: `Business status updated to ${isOnline ? 'online' : 'offline'}`,
            businessId: businessId,
            status: isOnline ? 'online' : 'offline',
            acceptingOrders: isOnline,
            ...comprehensiveStatus,
            updateResult: result
        });

    } catch (error) {
        console.error('Error toggling business status:', error);
        return createResponse(500, {
            success: false,
            message: 'Failed to update business status',
            error: error.message
        });
    }
}

/**
 * Get current business status
 */
async function handleGetBusinessStatus(event) {
    try {
        const { businessId } = event.pathParameters;
        const authHeader = event.headers.Authorization || event.headers.authorization;
        const userId = getUserIdFromToken(authHeader);

        if (!userId) {
            return createResponse(401, {
                success: false,
                message: 'Invalid or missing authorization token'
            });
        }

        if (!businessId) {
            return createResponse(400, {
                success: false,
                message: 'Business ID is required'
            });
        }

        console.log(`📊 Getting business status: ${businessId}`);

        // Get comprehensive status using WebSocket service
        const status = await WebSocketService.getBusinessStatus(businessId);

        return createResponse(200, {
            success: true,
            ...status,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Error getting business status:', error);
        return createResponse(500, {
            success: false,
            message: 'Failed to get business status',
            error: error.message
        });
    }
}

/**
 * Update business heartbeat
 */
async function handleBusinessHeartbeat(event) {
    try {
        const { businessId } = event.pathParameters;
        const authHeader = event.headers.Authorization || event.headers.authorization;
        const userId = getUserIdFromToken(authHeader);

        if (!userId) {
            return createResponse(401, {
                success: false,
                message: 'Invalid or missing authorization token'
            });
        }

        // Parse request body
        let bodyString = event.body || '{}';
        if (event.isBase64Encoded) {
            bodyString = Buffer.from(bodyString, 'base64').toString('utf-8');
        }

        const body = JSON.parse(bodyString);
        const { connectionId } = body;

        if (!businessId || !connectionId) {
            return createResponse(400, {
                success: false,
                message: 'Business ID and connection ID are required'
            });
        }

        console.log(`💓 Updating heartbeat: ${businessId} (connection: ${connectionId})`);

        // Update connection heartbeat
        const heartbeatResult = await WebSocketService.updateConnectionHeartbeat(connectionId);

        return createResponse(200, {
            success: true,
            message: 'Heartbeat updated successfully',
            businessId: businessId,
            connectionId: connectionId,
            heartbeatResult: heartbeatResult,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Error updating business heartbeat:', error);
        return createResponse(500, {
            success: false,
            message: 'Failed to update heartbeat',
            error: error.message
        });
    }
}

/**
 * Get status for multiple businesses (bulk operation)
 */
async function handleBulkBusinessStatus(event) {
    try {
        const authHeader = event.headers.Authorization || event.headers.authorization;
        const userId = getUserIdFromToken(authHeader);

        if (!userId) {
            return createResponse(401, {
                success: false,
                message: 'Invalid or missing authorization token'
            });
        }

        // Parse request body for business IDs
        let bodyString = event.body || '{}';
        if (event.isBase64Encoded) {
            bodyString = Buffer.from(bodyString, 'base64').toString('utf-8');
        }

        const body = JSON.parse(bodyString);
        const { businessIds } = body;

        if (!businessIds || !Array.isArray(businessIds) || businessIds.length === 0) {
            return createResponse(400, {
                success: false,
                message: 'Array of business IDs is required'
            });
        }

        console.log(`📊 Getting bulk business status for ${businessIds.length} businesses`);

        // Get status for each business
        const statusPromises = businessIds.map(async (businessId) => {
            try {
                const status = await WebSocketService.getBusinessStatus(businessId);
                return {
                    businessId,
                    success: true,
                    ...status
                };
            } catch (error) {
                console.error(`Error getting status for business ${businessId}:`, error);
                return {
                    businessId,
                    success: false,
                    error: error.message,
                    overallStatus: 'error'
                };
            }
        });

        const results = await Promise.all(statusPromises);

        // Categorize results
        const successful = results.filter(r => r.success);
        const failed = results.filter(r => !r.success);

        return createResponse(200, {
            success: true,
            message: `Retrieved status for ${successful.length}/${businessIds.length} businesses`,
            totalRequested: businessIds.length,
            successful: successful.length,
            failed: failed.length,
            businesses: results,
            timestamp: new Date().toISOString()
        });

    } catch (error) {
        console.error('Error getting bulk business status:', error);
        return createResponse(500, {
            success: false,
            message: 'Failed to get bulk business status',
            error: error.message
        });
    }
}

/**
 * Get legacy business online status (backward compatibility)
 */
async function getBusinessOnlineStatus(businessId) {
    try {
        const status = await WebSocketService.getBusinessStatus(businessId);
        
        return {
            isOnline: status.overallStatus === 'online',
            acceptingOrders: status.acceptingOrders,
            hasActiveConnection: status.connections.realTime.connected,
            hasLoginTracking: status.connections.loginTracking.active,
            lastStatusUpdate: status.lastStatusUpdate,
            overallStatus: status.overallStatus
        };

    } catch (error) {
        console.error('Error getting business online status:', error);
        return {
            isOnline: false,
            acceptingOrders: false,
            hasActiveConnection: false,
            hasLoginTracking: false,
            error: error.message
        };
    }
}

/**
 * Main handler
 */
exports.handler = async (event) => {
    console.log('🔧 Business Online Status Handler - Event:', JSON.stringify(event, null, 2));

    // Handle preflight CORS requests
    if (event.httpMethod === 'OPTIONS') {
        return createResponse(200, { message: 'CORS preflight successful' });
    }

    try {
        const { httpMethod, resource, path } = event;
        const actualPath = path || resource;

        // Route to appropriate handler
        if (actualPath.includes('/businesses/') && actualPath.includes('/status') && httpMethod === 'PUT') {
            return await handleBusinessStatusToggle(event);
        }
        
        if (actualPath.includes('/businesses/') && actualPath.includes('/status') && httpMethod === 'GET') {
            return await handleGetBusinessStatus(event);
        }
        
        if (actualPath.includes('/businesses/') && actualPath.includes('/heartbeat') && httpMethod === 'POST') {
            return await handleBusinessHeartbeat(event);
        }
        
        if (actualPath.includes('/businesses/status/bulk') && httpMethod === 'POST') {
            return await handleBulkBusinessStatus(event);
        }

        return createResponse(404, {
            success: false,
            message: 'Endpoint not found',
            path: actualPath,
            method: httpMethod
        });

    } catch (error) {
        console.error('Handler error:', error);
        return createResponse(500, {
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};

// Export additional functions for backward compatibility
module.exports.getBusinessOnlineStatus = getBusinessOnlineStatus;
