const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand, QueryCommand, ScanCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const { ApiGatewayManagementApiClient, PostToConnectionCommand } = require('@aws-sdk/client-apigatewaymanagementapi');
const { CognitoIdentityProviderClient, GetUserCommand } = require('@aws-sdk/client-cognito-identity-provider');

// Local utility functions (copied from ../auth/utils.js to avoid import issues in SAM build)
function createResponse(statusCode, body) {
    return {
        statusCode,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        body: JSON.stringify(body)
    };
}

// Environment variables
const ORDERS_TABLE = process.env.ORDERS_TABLE;
const MERCHANT_ENDPOINTS_TABLE = process.env.MERCHANT_ENDPOINTS_TABLE || 'WhizzMerchants_MerchantEndpoints';
const WEBSOCKET_CONNECTIONS_TABLE = process.env.WEBSOCKET_CONNECTIONS_TABLE;
const TIMEOUT_LOGS_TABLE = process.env.TIMEOUT_LOGS_TABLE;
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;

// --- Contextual logging helpers ---
function buildRequestContext(event) {
    const requestId = event?.requestContext?.requestId || event?.headers?.['x-request-id'] || `req-${Date.now()}`;
    const correlationId = event?.headers?.['x-correlation-id'] || event?.headers?.['x-correlationid'] || requestId;
    const businessId = event?.pathParameters?.businessId || event?.queryStringParameters?.businessId || undefined;
    const orderId = event?.pathParameters?.orderId || undefined;
    return { requestId, correlationId, businessId, orderId, routeKey: event?.routeKey, rawPath: event?.rawPath || event?.path };
}
function logCTX(ctx, msg, extra) {
    const base = `CTX | requestId=${ctx.requestId} corrId=${ctx.correlationId}` + (ctx.businessId ? ` businessId=${ctx.businessId}` : '') + (ctx.orderId ? ` orderId=${ctx.orderId}` : '') + (ctx.rawPath ? ` path=${ctx.rawPath}` : '');
    if (extra) {
        console.log(base + ' | ' + msg, extra);
    } else {
        console.log(base + ' | ' + msg);
    }
}
function logBizResolution(stage, details) {
    console.log(`BUSINESS_RESOLUTION | stage=${stage} |`, details);
}
// -----------------------------------

// Initialize AWS clients
const dynamoDbClient = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);
const sns = new SNSClient({ region: process.env.AWS_REGION || 'us-east-1' });
const cognito = new CognitoIdentityProviderClient({ region: process.env.COGNITO_REGION || 'us-east-1' });

/**
 * Check if business is accepting orders by checking the acceptingOrders field
 * This is the primary and only source of truth for order acceptance
 */
async function isBusinessOnline(businessId) {
    const ctx = { businessId };
    try {
        // Check the acceptingOrders field in the businesses table
        const BUSINESSES_TABLE = process.env.BUSINESSES_TABLE || 'WhizzMerchants_Businesses';
        if (!process.env.BUSINESSES_TABLE) {
            console.log(`⚠️ ENV BUSINESSES_TABLE not set, using default ${BUSINESSES_TABLE}`);
        }
        const businessParams = {
            TableName: BUSINESSES_TABLE,
            Key: {
                businessId: businessId
            },
            ProjectionExpression: 'acceptingOrders, lastStatusUpdate'
        };

        logBizResolution('lookup_business_acceptingOrders', { table: BUSINESSES_TABLE, businessId });
        const businessResult = await dynamodb.send(new GetCommand(businessParams));
        const business = businessResult.Item;

        if (!business) {
            logBizResolution('business_not_found', { businessId });
            console.log(`Business ${businessId} not found in businesses table ${BUSINESSES_TABLE}`);
            return false;
        }

        const isAcceptingOrders = business.acceptingOrders ?? false;
        logBizResolution('business_status_evaluated', { businessId, acceptingOrders: isAcceptingOrders, lastStatusUpdate: business.lastStatusUpdate });
        console.log(`Business ${businessId} accepting orders: ${isAcceptingOrders} (lastStatusUpdate: ${business.lastStatusUpdate})`);

        return isAcceptingOrders;
    } catch (error) {
        console.error('Error checking business accepting orders status:', error);
        // In case of error, default to offline to prevent order acceptance
        return false;
    }
}

/**
 * Merchant Order Handler - Handles merchant-specific order operations
 * Following the ecosystem architecture plan
 */
exports.handler = async (event) => {
    const ctx = buildRequestContext(event);
    logCTX(ctx, 'Merchant Order Handler invoked');
    console.log('Merchant Order Handler - Event (basic):', JSON.stringify({
        requestId: ctx.requestId,
        path: event.rawPath || event.path,
        method: event.httpMethod,
        hasHeaders: !!event.headers,
        hasQS: !!event.queryStringParameters
    }));

    const debugHeaders = event?.queryStringParameters?.debugHeaders === '1';
    if (debugHeaders) {
        try {
            const masked = {};
            for (const [k, v] of Object.entries(event.headers || {})) {
                if (/authorization|access-token/i.test(k)) {
                    if (typeof v === 'string') {
                        const val = v.trim();
                        masked[k] = val.length > 14 ? `${val.substring(0, 7)}...${val.substring(val.length - 7)}(len=${val.length})` : val;
                    } else {
                        masked[k] = v;
                    }
                } else {
                    masked[k] = v;
                }
            }
            console.log('🔍 DebugHeaders enabled. Incoming headers (masked):', JSON.stringify(masked, null, 2));
        } catch (e) {
            console.log('⚠️ Failed to mask headers for debug:', e);
        }
    }

    console.log('Merchant Order Handler - Event:', JSON.stringify(event, null, 2));

    const { httpMethod, path, pathParameters, headers, body } = event;

    // Handle Base64 encoded request body
    let requestBody = body;
    if (event.isBase64Encoded && requestBody) {
        try {
            requestBody = Buffer.from(requestBody, 'base64').toString('utf-8');
            logCTX(ctx, 'Decoded Base64 body');
            console.log('🔍 Decoded Base64 body:', requestBody);
        } catch (decodeError) {
            console.error('Failed to decode Base64 body:', decodeError);
            return createResponse(400, { success: false, message: 'Invalid Base64 request body', requestId: ctx.requestId });
        }
    }

    console.log('🔍 Final request body:', requestBody);

    try {
        // Handle public endpoints that don't require authentication
        if (httpMethod === 'POST' && path.includes('/webhooks/orders')) {
            logCTX(ctx, 'Route matched incoming central platform order webhook (public)');
            console.log('🔍 Webhook body before parsing:', requestBody);

            if (!requestBody || requestBody.trim() === '') {
                return createResponse(400, { success: false, message: 'Empty request body', requestId: ctx.requestId });
            }

            let orderData;
            try {
                orderData = JSON.parse(requestBody);
            } catch (parseError) {
                console.error('JSON parse error:', parseError);
                console.error('Body that failed to parse:', requestBody);
                return createResponse(400, { success: false, message: 'Invalid JSON in request body', requestId: ctx.requestId });
            }

            return await handleIncomingOrder(orderData);
        }

        // Extract access token from Authorization header for authenticated endpoints
        let authHeader = headers?.Authorization || headers?.authorization;
        let accessToken;

        // Handle both "Bearer token" and direct token formats
        if (authHeader) {
            if (authHeader.startsWith('Bearer ')) {
                accessToken = authHeader.slice('Bearer '.length).trim();
                logCTX(ctx, 'Using Bearer token format');
            } else {
                // Direct token without Bearer prefix (for AWS API Gateway Cognito Authorizer)
                accessToken = authHeader.trim();
                logCTX(ctx, 'Using direct token format');
            }
        } else {
            // Fallback to Access-Token header (case-insensitive)
            const accessTokenHeaderKey = Object.keys(headers || {}).find(k => k.toLowerCase() === 'access-token');
            if (accessTokenHeaderKey) {
                const raw = headers[accessTokenHeaderKey];
                if (typeof raw === 'string' && raw.trim().length > 0) {
                    accessToken = raw.trim();
                    logCTX(ctx, 'Using fallback Access-Token header');
                }
            }
        }

        if (!accessToken) {
            logCTX(ctx, 'Missing or invalid authorization token (Authorization Bearer or Access-Token)');
            return createResponse(401, { success: false, message: 'Missing or invalid authorization token', requestId: ctx.requestId });
        }

        // Optional debug log for token length only
        if (debugHeaders) {
            console.log(`🔐 Token length=${accessToken.length}`);
        }

        logCTX(ctx, 'Extracted access token for authentication');

        // Use dual authentication approach (supports both ID tokens from API Gateway and direct Access tokens)
        const businessId = await getBusinessId(event, cognito, dynamodb, ctx);
        if (!businessId) {
            logCTX(ctx, 'Failed to get business ID from authentication');
            return createResponse(401, { success: false, message: 'Authentication failed - could not determine business ID', requestId: ctx.requestId });
        }

        logCTX(ctx, 'Authentication successful', { businessId });

        logCTX(ctx, 'Authentication successful', { businessId });

        // Route based on endpoint (updated for new path structure)
        if (httpMethod === 'GET' && path.includes('/merchant/orders/') && pathParameters?.businessId) {
            logCTX(ctx, 'Route matched get orders for business');
            // Use authenticated businessId instead of path parameter for security
            return await handleGetOrdersForBusiness(businessId, event.queryStringParameters);
        }

        if (httpMethod === 'GET' && path.includes('/businesses/') && path.includes('/orders') && pathParameters?.businessId) {
            logCTX(ctx, 'Route matched get orders for business (alternative path)');
            // Use authenticated businessId instead of path parameter for security
            return await handleGetOrdersForBusiness(businessId, event.queryStringParameters);
        }

        if (httpMethod === 'PUT' && path.includes('/merchant/order/') && path.includes('/confirm')) {
            const orderId = pathParameters?.orderId;
            logCTX({ ...ctx, orderId }, 'Route matched confirm order');
            return await handleAcceptOrder(orderId, JSON.parse(requestBody || '{}'));
        }

        if (httpMethod === 'PUT' && path.includes('/merchant/order/') && path.includes('/reject')) {
            const orderId = pathParameters?.orderId;
            logCTX({ ...ctx, orderId }, 'Route matched reject order');
            return await handleRejectOrder(orderId, JSON.parse(requestBody || '{}'));
        }

        if (httpMethod === 'PUT' && path.includes('/merchant/order/') && path.includes('/status')) {
            const orderId = pathParameters?.orderId;
            logCTX({ ...ctx, orderId }, 'Route matched update order status');
            return await handleUpdateOrderStatus(orderId, JSON.parse(requestBody || '{}'));
        }

        if (httpMethod === 'POST' && path.includes('/merchants/') && path.includes('/device-token')) {
            const merchantId = pathParameters?.merchantId;
            logCTX({ ...ctx, businessId: merchantId }, 'Route matched register device token');
            return await handleRegisterDeviceToken(merchantId, JSON.parse(requestBody || '{}'));
        }

        if (httpMethod === 'POST' && path.includes('/merchant/order/') && path.includes('/timeout-log')) {
            const orderId = pathParameters?.orderId;
            logCTX({ ...ctx, orderId }, 'Route matched timeout log');
            return await handleTimeoutLog(orderId, JSON.parse(requestBody || '{}'));
        }

        logCTX(ctx, 'No route matched');
        return createResponse(404, { success: false, message: 'Endpoint not found', requestId: ctx.requestId });

    } catch (error) {
        console.error('Error in merchant order handler:', error);
        return createResponse(500, { success: false, message: 'Internal server error', requestId: ctx.requestId });
    }
};

/**
 * Get orders for a specific business/merchant
 */
async function handleGetOrdersForBusiness(businessId, queryParams) {
    try {
        const status = queryParams?.status;

        // Use BusinessIdIndex for efficient querying
        let params = {
            TableName: ORDERS_TABLE,
            IndexName: 'BusinessIdIndex',
            KeyConditionExpression: 'businessId = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessId
            }
        };

        // Add status filter if provided
        if (status) {
            params.FilterExpression = '#status = :status';
            params.ExpressionAttributeNames = { '#status': 'status' };
            params.ExpressionAttributeValues[':status'] = status;
        }

        console.log('Querying orders for businessId:', businessId, 'with params:', JSON.stringify(params, null, 2));
        const result = await dynamodb.send(new QueryCommand(params));

        return createResponse(200, {
            success: true,
            orders: result.Items,
            count: result.Items.length
        });

    } catch (error) {
        console.error('Error getting orders for business:', error);
        return createResponse(500, { success: false, message: 'Failed to get orders' });
    }
}

/**
 * Accept an order (Merchant accepts order from Customer)
 * This will trigger notifications to Driver App and update Central Platform
 */
async function handleAcceptOrder(orderId, data) {
    try {
        const { estimatedPreparationTime } = data;
        const timestamp = new Date().toISOString();

        // Update order status to 'confirmed'
        const updateParams = {
            TableName: ORDERS_TABLE,
            Key: { orderId },
            UpdateExpression: 'SET #status = :status, updatedAt = :timestamp, estimatedPreparationTime = :prepTime',
            ExpressionAttributeNames: { '#status': 'status' },
            ExpressionAttributeValues: {
                ':status': 'confirmed',
                ':timestamp': timestamp,
                ':prepTime': estimatedPreparationTime || 30
            },
            ReturnValues: 'ALL_NEW'
        };

        const result = await dynamodb.send(new UpdateCommand(updateParams));
        const updatedOrder = result.Attributes;

        // TODO: Emit OrderStatusUpdated event for Driver App
        await publishOrderStatusUpdate(updatedOrder, 'ORDER_CONFIRMED');

        // TODO: Notify Central Platform
        await notifyCentralPlatform(updatedOrder, 'confirmed');

        return createResponse(200, {
            success: true,
            message: 'Order confirmed successfully',
            order: updatedOrder
        });

    } catch (error) {
        console.error('Error accepting order:', error);
        return createResponse(500, { success: false, message: 'Failed to accept order' });
    }
}

/**
 * Reject an order
 */
async function handleRejectOrder(orderId, data) {
    try {
        const { reason } = data;
        const timestamp = new Date().toISOString();

        const updateParams = {
            TableName: ORDERS_TABLE,
            Key: { orderId },
            UpdateExpression: 'SET #status = :status, updatedAt = :timestamp, rejectionReason = :reason',
            ExpressionAttributeNames: { '#status': 'status' },
            ExpressionAttributeValues: {
                ':status': 'rejected',
                ':timestamp': timestamp,
                ':reason': reason || 'No reason provided'
            },
            ReturnValues: 'ALL_NEW'
        };

        const result = await dynamodb.send(new UpdateCommand(updateParams));
        const updatedOrder = result.Attributes;

        // Notify Customer App and Central Platform
        await publishOrderStatusUpdate(updatedOrder, 'ORDER_REJECTED');
        await notifyCentralPlatform(updatedOrder, 'rejected');

        return createResponse(200, {
            success: true,
            message: 'Order rejected successfully',
            order: updatedOrder
        });

    } catch (error) {
        console.error('Error rejecting order:', error);
        return createResponse(500, { success: false, message: 'Failed to reject order' });
    }
}

/**
 * Update order status (preparing, ready, etc.)
 */
async function handleUpdateOrderStatus(orderId, data) {
    try {
        const { status, notes } = data;
        const timestamp = new Date().toISOString();

        const updateParams = {
            TableName: ORDERS_TABLE,
            Key: { orderId },
            UpdateExpression: 'SET #status = :status, updatedAt = :timestamp',
            ExpressionAttributeNames: { '#status': 'status' },
            ExpressionAttributeValues: {
                ':status': status,
                ':timestamp': timestamp
            }
        };

        if (notes) {
            updateParams.UpdateExpression += ', notes = :notes';
            updateParams.ExpressionAttributeValues[':notes'] = notes;
        }

        updateParams.ReturnValues = 'ALL_NEW';

        const result = await dynamodb.send(new UpdateCommand(updateParams));
        const updatedOrder = result.Attributes;

        // Emit appropriate events based on status
        let eventType = 'ORDER_STATUS_UPDATED';
        if (status === 'ready') {
            eventType = 'ORDER_READY_FOR_PICKUP';
        }

        await publishOrderStatusUpdate(updatedOrder, eventType);
        await notifyCentralPlatform(updatedOrder, status);

        return createResponse(200, {
            success: true,
            message: 'Order status updated successfully',
            order: updatedOrder
        });

    } catch (error) {
        console.error('Error updating order status:', error);
        return createResponse(500, { success: false, message: 'Failed to update order status' });
    }
}

/**
 * Register device token for push notifications (Mobile app)
 */
async function handleRegisterDeviceToken(merchantId, data) {
    try {
        const { deviceToken, platform } = data; // platform: 'ios' | 'android'
        if (!deviceToken || !platform) {
            return createResponse(400, { success: false, message: 'deviceToken and platform required' });
        }
        const timestamp = new Date().toISOString();
        const ttl = Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60); // 30 days

        // Unified table schema for device token
        const item = {
            PK: `DEVICE#${deviceToken}`,
            SK: `DEVICE#${deviceToken}`,
            GSI1PK: `BUSINESS#${merchantId}`,
            GSI1SK: `DEVICE#${deviceToken}`,
            entityType: 'mobile_push',
            endpointType: 'mobile_push', // legacy field for compatibility
            merchantId,
            businessId: merchantId,
            deviceToken,
            platform,
            isActive: true,
            registeredAt: timestamp,
            updatedAt: timestamp,
            ttl
        };

        await dynamodb.send(new PutCommand({
            TableName: WEBSOCKET_CONNECTIONS_TABLE,
            Item: item
        }));

        return createResponse(200, {
            success: true,
            message: 'Device token registered in unified table'
        });

    } catch (error) {
        console.error('Error registering device token:', error);
        return createResponse(500, { success: false, message: 'Failed to register device token' });
    }
}

/**
 * Handle incoming order from Central Platform
 * This is called by your Central Platform when a customer places an order
 */
async function handleIncomingOrder(orderData) {
    try {
        const {
            orderId,
            businessId,
            customerId,
            customerName,
            customerPhone,
            deliveryAddress,
            items,
            totalAmount,
            notes,
            platformOrderId
        } = orderData;

        logBizResolution('incoming_order_business_status_check', { businessId, orderId });
        // Check if business is online before accepting the order
        const businessOnline = await isBusinessOnline(businessId);

        if (!businessOnline) {
            console.log(`❌ Order ${orderId} rejected - Business ${businessId} is offline`);
            return createResponse(423, {
                success: false,
                message: 'Business is currently offline and cannot accept orders',
                orderId,
                businessId,
                status: 'rejected_offline'
            });
        }

        console.log(`✅ Business ${businessId} is online - proceeding with order ${orderId}`);

        const timestamp = new Date().toISOString();

        // Store order in DynamoDB
        const order = {
            orderId,
            businessId,
            customerId,
            customerName,
            customerPhone,
            deliveryAddress,
            items,
            totalAmount: parseFloat(totalAmount),
            status: 'pending',
            notes: notes || '',
            platformOrderId, // Reference to order in Central Platform
            createdAt: timestamp,
            updatedAt: timestamp
        };

        await dynamodb.send(new PutCommand({
            TableName: ORDERS_TABLE,
            Item: order
        }));

        // Notify Merchant App about new order via WebSocket and Push
        await notifyMerchant(businessId, {
            type: 'NEW_ORDER',
            orderId,
            customerName,
            totalAmount,
            message: `New order from ${customerName}`,
            data: order
        });

        return createResponse(201, {
            success: true,
            message: 'Order received and processed successfully',
            orderId
        });

    } catch (error) {
        console.error('Error handling incoming order:', error);
        return createResponse(500, { success: false, message: 'Failed to process incoming order' });
    }
}

/**
 * Publish order status update event (for EventBridge/SNS)
 */
async function publishOrderStatusUpdate(order, eventType) {
    try {
        const message = {
            eventType,
            orderId: order.orderId,
            businessId: order.businessId,
            customerId: order.customerId,
            status: order.status,
            timestamp: new Date().toISOString(),
            orderData: order
        };

        console.log('📤 Publishing order status update to SNS:', message);

        // For now, just log. Later implement SNS/EventBridge:
        await sns.send(new PublishCommand({
            TopicArn: process.env.ORDER_EVENTS_TOPIC_ARN,
            Message: JSON.stringify(message),
            MessageAttributes: {
                eventType: { DataType: 'String', StringValue: eventType },
                orderId: { DataType: 'String', StringValue: order.orderId }
            }
        }));

    } catch (error) {
        console.error('Error publishing order status update:', error);
    }
}

/**
 * Notify Central Platform about order status changes
 */
async function notifyCentralPlatform(order, status) {
    try {
        // TODO: Implement HTTP callback to your Central Platform
        const notification = {
            orderId: order.orderId,
            platformOrderId: order.platformOrderId,
            businessId: order.businessId,
            status,
            timestamp: new Date().toISOString()
        };

        console.log('📤 Notifying Central Platform:', notification);

        // Later implement HTTP POST to Central Platform:
        // const response = await axios.post(process.env.CENTRAL_PLATFORM_WEBHOOK_URL, notification);

    } catch (error) {
        console.error('Error notifying central platform:', error);
    }
}

/**
 * Notify merchant about new orders or updates
 */
async function notifyMerchant(businessId, notification) {
    try {
        // Query unified table GSI1 for all active endpoints (websocket + mobile_push)
        const queryParams = {
            TableName: WEBSOCKET_CONNECTIONS_TABLE,
            IndexName: 'GSI1',
            KeyConditionExpression: 'GSI1PK = :pk',
            ExpressionAttributeValues: { ':pk': `BUSINESS#${businessId}` }
        };

        const result = await dynamodb.send(new QueryCommand(queryParams));
        const endpoints = (result.Items || []).filter(i => i.entityType === 'mobile_push' || i.entityType === 'merchant');

        console.log('🔍 Unified endpoints for merchant', businessId, 'total:', endpoints.length);

        for (const endpoint of endpoints) {
            if (endpoint.entityType === 'mobile_push' && endpoint.isActive !== false) {
                await sendPushNotification(endpoint, notification);
            } else if (endpoint.entityType === 'merchant' && endpoint.connectionId) {
                await sendWebSocketMessage(endpoint, notification);
            }
        }
    } catch (error) {
        console.error('Error notifying merchant (unified):', error);
    }
}

/**
 * Send push notification to mobile app
 */
async function sendPushNotification(endpoint, notification) {
    try {
        // TODO: Implement FCM/APNS push notification
        console.log('📱 Sending push notification:', { endpoint: endpoint.deviceToken, notification });

    } catch (error) {
        console.error('Error sending push notification:', error);
    }
}

/**
 * Send WebSocket message
 */
async function sendWebSocketMessage(endpoint, notification) {
    try {
        const apiGatewayManagementApi = new ApiGatewayManagementApiClient({
            region: process.env.AWS_REGION || 'us-east-1',
            endpoint: process.env.WEBSOCKET_ENDPOINT
        });

        const message = {
            type: 'ORDER_NOTIFICATION',
            notification: notification,
            timestamp: new Date().toISOString()
        };

        await apiGatewayManagementApi.send(new PostToConnectionCommand({
            ConnectionId: endpoint.connectionId,
            Data: JSON.stringify(message)
        }));

        console.log('🔌 WebSocket message sent (unified):', { connectionId: endpoint.connectionId });

    } catch (error) {
        if (error.statusCode === 410) {
            console.log('🔌 Stale WebSocket connection, deleting unified item:', endpoint.connectionId);
            try {
                await dynamodb.send(new DeleteCommand({
                    TableName: WEBSOCKET_CONNECTIONS_TABLE,
                    Key: { PK: endpoint.PK || `CONNECTION#${endpoint.connectionId}`, SK: endpoint.SK || `CONNECTION#${endpoint.connectionId}` }
                }));
            } catch (e) { console.error('Failed deleting stale unified connection', e.message); }
        } else {
            console.error('Error sending WebSocket message (unified):', error);
        }
    }
}

/**
 * Remove stale WebSocket connection from database
 */
async function removeStaleWebSocketConnection(endpoint) {
    // Legacy function retained; now directly deletes from unified table
    try {
        await dynamodb.send(new DeleteCommand({
            TableName: WEBSOCKET_CONNECTIONS_TABLE,
            Key: { PK: endpoint.PK || `CONNECTION#${endpoint.connectionId}`, SK: endpoint.SK || `CONNECTION#${endpoint.connectionId}` }
        }));
        console.log('🔌 Removed stale unified WebSocket connection for merchant:', endpoint.merchantId || endpoint.businessId);
    } catch (error) {
        console.error('Error removing stale unified WebSocket connection:', error);
    }
}

/**
 * Log timeout events for orders
 */
async function handleTimeoutLog(orderId, requestData) {
    try {
        console.log('⏰ Logging timeout event for order:', orderId, 'Data:', requestData);

        const { timeoutType, businessId, remainingSeconds, alertLevel } = requestData;

        if (!timeoutType || !businessId) {
            return createResponse(400, {
                success: false,
                message: 'Missing required fields: timeoutType and businessId'
            });
        }

        // Validate timeout type
        const validTimeoutTypes = ['firstAlert', 'urgentAlert', 'autoReject'];
        if (!validTimeoutTypes.includes(timeoutType)) {
            return createResponse(400, {
                success: false,
                message: 'Invalid timeout type. Must be: firstAlert, urgentAlert, or autoReject'
            });
        }

        // Create timeout log entry
        const timestamp = new Date().toISOString();
        const ttl = Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60); // 30 days TTL

        const timeoutLogItem = {
            orderId,
            timestamp,
            businessId,
            timeoutType,
            alertLevel: alertLevel || timeoutType,
            remainingSeconds: remainingSeconds || 0,
            deviceTimestamp: new Date().toISOString(),
            ttl
        };

        await dynamodb.send(new PutCommand({
            TableName: TIMEOUT_LOGS_TABLE,
            Item: timeoutLogItem
        }));

        console.log('⏰ Successfully logged timeout event:', timeoutLogItem);

        return createResponse(200, {
            success: true,
            message: 'Timeout event logged successfully',
            data: {
                orderId,
                timeoutType,
                timestamp
            }
        });

    } catch (error) {
        console.error('❌ Error logging timeout event:', error);
        return createResponse(500, {
            success: false,
            message: 'Failed to log timeout event',
            error: error.message
        });
    }
}

// Get business ID using dual authentication approach (supports both ID tokens from API Gateway and direct Access tokens)
async function getBusinessId(event, cognito, dynamodb, context) {
    try {
        // Method 1: Try to get user info from API Gateway authorizer context (when using ID tokens)
        const claims = event.requestContext?.authorizer?.claims;
        if (claims && claims.email) {
            logCTX(context, 'Using ID token claims from API Gateway authorizer');
            const email = claims.email.toLowerCase().trim();

            // Query businesses by email
            const queryParams = {
                TableName: process.env.BUSINESSES_TABLE || 'WhizzMerchants_Businesses',
                IndexName: 'email-index',
                KeyConditionExpression: 'email = :email',
                ExpressionAttributeValues: { ':email': email }
            };

            const result = await dynamodb.send(new QueryCommand(queryParams));
            if (result.Items && result.Items.length > 0) {
                const businessId = result.Items[0].businessId;
                logCTX(context, 'Found business ID from ID token claims', { email, businessId });
                return businessId;
            }
        }

        // Method 2: Fallback to Cognito GetUserCommand (when using access tokens directly)
        logCTX(context, 'Falling back to Cognito GetUserCommand approach');

        const authHeader = event.headers?.Authorization || event.headers?.authorization;
        if (!authHeader) {
            logCTX(context, 'No authorization header found');
            return null;
        }

        let accessToken = authHeader;
        if (authHeader.startsWith('Bearer ')) {
            accessToken = authHeader.substring(7);
        }

        const userInfo = await getUserInfoFromToken(cognito, accessToken);
        if (!userInfo || !userInfo.UserAttributes) {
            logCTX(context, 'Failed to get user info from access token');
            return null;
        }

        const emailAttribute = userInfo.UserAttributes.find(attr => attr.Name === 'email');
        if (!emailAttribute || !emailAttribute.Value) {
            logCTX(context, 'No email found in access token user info');
            return null;
        }

        const email = emailAttribute.Value.toLowerCase().trim();
        logCTX(context, 'Got user info from access token', { email });

        // Query businesses by email
        const queryParams = {
            TableName: process.env.BUSINESSES_TABLE || 'WhizzMerchants_Businesses',
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': email }
        };

        const result = await dynamodb.send(new QueryCommand(queryParams));
        if (result.Items && result.Items.length > 0) {
            const businessId = result.Items[0].businessId;
            logCTX(context, 'Found business ID from access token', { email, businessId });
            return businessId;
        }

        logCTX(context, 'No business found for email', { email });
        return null;

    } catch (error) {
        logCTX(context, 'Error in getBusinessId', { error: error.message });
        console.error('Error in getBusinessId:', error);
        return null;
    }
}

// Helper function to get user info from access token
async function getUserInfoFromToken(cognito, accessToken) {
    try {
        const params = {
            AccessToken: accessToken
        };
        const result = await cognito.send(new GetUserCommand(params));
        return result;
    } catch (error) {
        console.error('Error getting user info from token:', error);
        return null;
    }
}
