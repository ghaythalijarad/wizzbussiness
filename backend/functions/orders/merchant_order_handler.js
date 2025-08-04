const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand, QueryCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const { ApiGatewayManagementApiClient, PostToConnectionCommand } = require('@aws-sdk/client-apigatewaymanagementapi');
const { createResponse } = require('../auth/utils');

// Environment variables
const ORDERS_TABLE = process.env.ORDERS_TABLE;
const MERCHANT_ENDPOINTS_TABLE = process.env.MERCHANT_ENDPOINTS_TABLE || 'order-receiver-merchant-endpoints-dev';

// Initialize AWS clients
const dynamoDbClient = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);
const sns = new SNSClient({ region: process.env.AWS_REGION || 'us-east-1' });

/**
 * Merchant Order Handler - Handles merchant-specific order operations
 * Following the ecosystem architecture plan
 */
exports.handler = async (event) => {
    console.log('Merchant Order Handler - Event:', JSON.stringify(event, null, 2));

    const { httpMethod, path, pathParameters, headers, body } = event;

    // Handle Base64 encoded request body
    let requestBody = body;
    if (event.isBase64Encoded && requestBody) {
        try {
            requestBody = Buffer.from(requestBody, 'base64').toString('utf-8');
            console.log('🔍 Decoded Base64 body:', requestBody);
        } catch (decodeError) {
            console.error('Failed to decode Base64 body:', decodeError);
            return createResponse(400, { success: false, message: 'Invalid Base64 request body' });
        }
    }
    
    console.log('🔍 Final request body:', requestBody);

    try {
        // Route based on endpoint (updated for new path structure)
        if (httpMethod === 'GET' && path.includes('/merchant/orders/') && pathParameters?.businessId) {
            return await handleGetOrdersForBusiness(pathParameters.businessId, event.queryStringParameters);
        }

        if (httpMethod === 'PUT' && path.includes('/merchant/order/') && path.includes('/confirm')) {
            const orderId = pathParameters?.orderId;
            return await handleAcceptOrder(orderId, JSON.parse(requestBody || '{}'));
        }

        if (httpMethod === 'PUT' && path.includes('/merchant/order/') && path.includes('/reject')) {
            const orderId = pathParameters?.orderId;
            return await handleRejectOrder(orderId, JSON.parse(requestBody || '{}'));
        }

        if (httpMethod === 'PUT' && path.includes('/merchant/order/') && path.includes('/status')) {
            const orderId = pathParameters?.orderId;
            return await handleUpdateOrderStatus(orderId, JSON.parse(requestBody || '{}'));
        }

        if (httpMethod === 'POST' && path.includes('/merchants/') && path.includes('/device-token')) {
            const merchantId = pathParameters?.merchantId;
            return await handleRegisterDeviceToken(merchantId, JSON.parse(requestBody || '{}'));
        }

        if (httpMethod === 'POST' && path.includes('/webhooks/orders')) {
            // Receive orders from Central Platform
            console.log('🔍 Webhook body before parsing:', requestBody);
            
            if (!requestBody || requestBody.trim() === '') {
                return createResponse(400, { success: false, message: 'Empty request body' });
            }
            
            let orderData;
            try {
                orderData = JSON.parse(requestBody);
            } catch (parseError) {
                console.error('JSON parse error:', parseError);
                console.error('Body that failed to parse:', requestBody);
                return createResponse(400, { success: false, message: 'Invalid JSON in request body' });
            }
            
            return await handleIncomingOrder(orderData);
        }

        return createResponse(404, { success: false, message: 'Endpoint not found' });

    } catch (error) {
        console.error('Error in merchant order handler:', error);
        return createResponse(500, { success: false, message: 'Internal server error' });
    }
};

/**
 * Get orders for a specific business/merchant
 */
async function handleGetOrdersForBusiness(businessId, queryParams) {
    try {
        const status = queryParams?.status;

        // Use StoreIdIndex for efficient querying
        let params = {
            TableName: ORDERS_TABLE,
            IndexName: 'StoreIdIndex',
            KeyConditionExpression: 'storeId = :storeId',
            ExpressionAttributeValues: {
                ':storeId': businessId  // businessId parameter is actually the storeId
            }
        };

        // Add status filter if provided
        if (status) {
            params.FilterExpression = '#status = :status';
            params.ExpressionAttributeNames = { '#status': 'status' };
            params.ExpressionAttributeValues[':status'] = status;
        }

        console.log('Querying orders for storeId:', businessId, 'with params:', JSON.stringify(params, null, 2));
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
        } else if (status === 'preparing') {
            eventType = 'ORDER_PREPARING';
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
        const timestamp = new Date().toISOString();

        const params = {
            TableName: MERCHANT_ENDPOINTS_TABLE,
            Item: {
                merchantId,
                endpointType: 'mobile_push',
                deviceToken,
                platform,
                isActive: true,
                registeredAt: timestamp,
                updatedAt: timestamp
            }
        };

        await dynamodb.send(new PutCommand(params));

        return createResponse(200, {
            success: true,
            message: 'Device token registered successfully'
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

        // TODO: Replace with EventBridge when implemented
        console.log('📤 Publishing order status update:', message);

        // For now, just log. Later implement SNS/EventBridge:
        // await sns.publish({
        //     TopicArn: process.env.ORDER_EVENTS_TOPIC_ARN,
        //     Message: JSON.stringify(message),
        //     MessageAttributes: {
        //         eventType: { DataType: 'String', StringValue: eventType },
        //         orderId: { DataType: 'String', StringValue: order.orderId }
        //     }
        // }).promise();

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
        // Get merchant endpoints (FCM tokens, WebSocket connections)
        // Use scan since we don't have MerchantIdIndex yet
        const params = {
            TableName: MERCHANT_ENDPOINTS_TABLE,
            FilterExpression: 'merchantId = :merchantId AND isActive = :active',
            ExpressionAttributeValues: {
                ':merchantId': businessId,
                ':active': true
            }
        };

        console.log('🔍 Scanning for merchant endpoints:', params);
        const result = await dynamodb.send(new ScanCommand(params));
        const endpoints = result.Items;
        
        console.log('🔍 Found endpoints for merchant:', businessId, 'Count:', endpoints.length);

        // Send notifications to all active endpoints
        for (const endpoint of endpoints) {
            if (endpoint.endpointType === 'mobile_push') {
                await sendPushNotification(endpoint, notification);
            } else if (endpoint.endpointType === 'websocket') {
                await sendWebSocketMessage(endpoint, notification);
            }
        }

    } catch (error) {
        console.error('Error notifying merchant:', error);
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

        console.log('🔌 WebSocket message sent successfully:', { connectionId: endpoint.connectionId, notification });

    } catch (error) {
        if (error.statusCode === 410) {
            // Connection is stale, remove from database
            console.log('🔌 Stale WebSocket connection, removing:', endpoint.connectionId);
            await removeStaleWebSocketConnection(endpoint);
        } else {
            console.error('Error sending WebSocket message:', error);
        }
    }
}

/**
 * Remove stale WebSocket connection from database
 */
async function removeStaleWebSocketConnection(endpoint) {
    try {
        await dynamodb.send(new UpdateCommand({
            TableName: MERCHANT_ENDPOINTS_TABLE,
            Key: {
                merchantId: endpoint.merchantId,
                endpointType: 'websocket'
            },
            UpdateExpression: 'SET isActive = :inactive',
            ExpressionAttributeValues: {
                ':inactive': false
            }
        }));

        console.log('🔌 Removed stale WebSocket connection for merchant:', endpoint.merchantId);
    } catch (error) {
        console.error('Error removing stale WebSocket connection:', error);
    }
}
