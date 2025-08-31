const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, UpdateCommand, DeleteCommand, GetCommand, QueryCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');
const { ApiGatewayManagementApiClient, PostToConnectionCommand } = require('@aws-sdk/client-apigatewaymanagementapi');
const { WebSocketConnectionsAdapter } = require('./websocket_table_adapter');

const dynamoDbClient = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

// Initialize WebSocket connections adapter for schema compatibility
const connectionsAdapter = new WebSocketConnectionsAdapter(
    process.env.WEBSOCKET_CONNECTIONS_TABLE || 'WizzUser_websocket_connections_dev'
);

const apiGatewayManagementApi = new ApiGatewayManagementApiClient({
    region: process.env.AWS_REGION || 'us-east-1',
    endpoint: process.env.WEBSOCKET_ENDPOINT
});

/**
 * Professional WebSocket Management System
 * 
 * Connection Types:
 * 1. REAL: CONNECTION#${connectionId} - Actual WebSocket channels for real-time messaging
 * 2. VIRTUAL: CONNECTION#VIRTUAL#${businessId}#${userId} - Login tracking for business presence
 * 
 * Features:
 * - Dual connection management (real WebSocket + login tracking)
 * - Professional stale connection cleanup
 * - Online/offline status integration
 * - Connection monitoring and heartbeat management
 * - Comprehensive error handling and logging
 */

/**
 * Handle WebSocket connection establishment
 */
async function handleConnect(event) {
    try {
        const connectionId = event.requestContext.connectionId;
        const merchantId = event.queryStringParameters?.merchantId;
        const businessId = event.queryStringParameters?.businessId;
        const userId = event.queryStringParameters?.userId;
        const entityType = event.queryStringParameters?.entityType || 'merchant';

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

        // Store connection in merchant endpoints table (backward compatibility)
        if (effectiveMerchantId && process.env.MERCHANT_ENDPOINTS_TABLE) {
            try {
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
            } catch (error) {
                console.warn('⚠️ Could not store in merchant endpoints table (table may not exist):', error.message);
            }
        }

        // Store connection in primary websocket connections table using adapter
        await connectionsAdapter.createConnection({
            connectionId,
            entityType,
            userId: effectiveUserId,
            businessId: effectiveMerchantId,
            connectedAt: currentTime,
            ttl,
            isActive: true,
            connectionType: 'REAL',
            lastHeartbeat: currentTime
        });
        console.log(`✅ Stored real WebSocket connection in unified tracking table`);

        console.log(`🔌 WebSocket connected: ${connectionId} for ${entityType}: ${effectiveUserId}${effectiveMerchantId ? ` (business: ${effectiveMerchantId})` : ''}`);

        // Send welcome message
        await sendMessageToConnection(connectionId, {
            type: 'CONNECTION_ESTABLISHED',
            message: `Connected to ${entityType === 'merchant' ? 'merchant' : 'customer'} notifications`,
            timestamp: currentTime,
            entityType,
            connectionId,
            ...(effectiveMerchantId && { businessId: effectiveMerchantId })
        });

        return { statusCode: 200, body: 'Connected' };

    } catch (error) {
        console.error('Error handling WebSocket connection:', error);
        return { statusCode: 500, body: 'Failed to connect' };
    }
}

/**
 * Handle WebSocket disconnection with professional cleanup
 */
async function handleDisconnect(event) {
    try {
        const connectionId = event.requestContext.connectionId;
        console.log(`🔌 WebSocket disconnecting: ${connectionId}`);

        // Remove connection from primary WebSocket connections table using adapter
        await connectionsAdapter.deleteConnection(connectionId);
        console.log(`✅ Successfully cleaned up real WebSocket connection: ${connectionId}`);

        // Also clean up from merchant endpoints table for backward compatibility
        try {
            const merchantParams = {
                TableName: process.env.MERCHANT_ENDPOINTS_TABLE,
                FilterExpression: 'connectionId = :connectionId',
                ExpressionAttributeValues: {
                    ':connectionId': connectionId
                }
            };

            const result = await dynamodb.send(new ScanCommand(merchantParams));
            if (result.Items && result.Items.length > 0) {
                const item = result.Items[0];
                await dynamodb.send(new DeleteCommand({
                    TableName: process.env.MERCHANT_ENDPOINTS_TABLE,
                    Key: {
                        merchantId: item.merchantId,
                        endpointType: 'websocket'
                    }
                }));
                console.log(`✅ Cleaned up merchant endpoints table for: ${connectionId}`);
            }
        } catch (merchantError) {
            console.warn('Warning: Could not clean up merchant endpoints table:', merchantError.message);
        }

        return { statusCode: 200, body: 'Disconnected' };

    } catch (error) {
        console.error('Error handling WebSocket disconnection:', error);
        return { statusCode: 500, body: 'Failed to disconnect' };
    }
}

/**
 * Send message to specific WebSocket connection with stale connection handling
 */
async function sendMessageToConnection(connectionId, message) {
    try {
        await apiGatewayManagementApi.send(new PostToConnectionCommand({
            ConnectionId: connectionId,
            Data: Buffer.from(JSON.stringify(message)),
        }));

        // Update last activity timestamp
        await updateConnectionHeartbeat(connectionId);

        console.log(`🔌 Message sent to connection ${connectionId}: ${message.type || 'unknown'}`);

    } catch (error) {
        if (error.statusCode === 410 || error.name === 'GoneException') {
            // Connection is stale, remove from database
            console.log(`🔌 Stale connection detected, removing: ${connectionId}`);
            await removeStaleConnection(connectionId);
        } else {
            console.error('Error sending WebSocket message:', error);
            throw error;
        }
    }
}

/**
 * Update connection heartbeat timestamp
 */
async function updateConnectionHeartbeat(connectionId) {
    try {
        await connectionsAdapter.updateHeartbeat(connectionId);
    } catch (error) {
        console.warn('Warning: Could not update connection heartbeat:', error.message);
    }
}

/**
 * Send message to all active connections for a merchant/business
 */
async function sendMessageToMerchant(merchantId, message) {
    try {
        // Get all active real WebSocket connections for the merchant
        const connections = await getActiveConnectionsForBusiness(merchantId);
        
        if (connections.length === 0) {
            console.log(`📭 No active WebSocket connections found for merchant: ${merchantId}`);
            return;
        }

        // Send message to all active connections
        const promises = connections.map(connection =>
            sendMessageToConnection(connection.connectionId, {
                ...message,
                businessId: merchantId,
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
 * Get all active real WebSocket connections for a business
 */
async function getActiveConnectionsForBusiness(businessId) {
    try {
        // Use adapter to get business connections with REAL connection type
        const activeConnections = await connectionsAdapter.getBusinessConnections(businessId, 'REAL');

        return activeConnections;
    } catch (error) {
        console.error('Error getting active connections for business:', error);
        return [];
    }
}

/**
 * Remove stale connection from all tables
 */
async function removeStaleConnection(connectionId) {
    try {
        // Remove from primary WebSocket connections table using adapter
        await connectionsAdapter.deleteConnection(connectionId);

        // Remove from merchant endpoints table (backward compatibility)
        const merchantParams = {
            TableName: process.env.MERCHANT_ENDPOINTS_TABLE,
            FilterExpression: 'connectionId = :connectionId',
            ExpressionAttributeValues: {
                ':connectionId': connectionId
            }
        };

        const result = await dynamodb.send(new ScanCommand(merchantParams));
        if (result.Items && result.Items.length > 0) {
            const item = result.Items[0];
            await dynamodb.send(new DeleteCommand({
                TableName: process.env.MERCHANT_ENDPOINTS_TABLE,
                Key: {
                    merchantId: item.merchantId,
                    endpointType: 'websocket'
                }
            }));
        }

        console.log(`🔌 Removed stale connection: ${connectionId}`);

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

        // Update heartbeat for this connection
        await updateConnectionHeartbeat(connectionId);

        // Handle different message types
        switch (message.type) {
            case 'PING':
                await sendMessageToConnection(connectionId, {
                    type: 'PONG',
                    timestamp: new Date().toISOString()
                });
                break;

            case 'HEARTBEAT':
                await sendMessageToConnection(connectionId, {
                    type: 'HEARTBEAT_ACK',
                    timestamp: new Date().toISOString()
                });
                break;

            case 'SUBSCRIBE_ORDERS':
                // Subscribe to order updates (could implement filtering here)
                await sendMessageToConnection(connectionId, {
                    type: 'SUBSCRIBED',
                    message: 'Subscribed to order updates',
                    businessId: message.businessId
                });
                break;

            case 'STATUS_UPDATE':
                // Handle business status updates
                if (message.businessId && message.status) {
                    await handleBusinessStatusUpdate(message.businessId, message.status, connectionId);
                }
                break;

            case 'MERCHANT_STATUS_UPDATE':
                // Handle merchant online/offline status changes from toggle
                if (message.businessId && message.status && message.userId) {
                    await handleMerchantStatusUpdate(
                        message.businessId, 
                        message.userId, 
                        message.status, 
                        connectionId
                    );
                }
                break;

            case 'BUSINESS_STATUS_UPDATE':
                // Handle business status updates for actual subscription pattern
                if (message.businessId && message.status && message.userId) {
                    await handleBusinessStatusSubscriptionUpdate(
                        message.businessId, 
                        message.userId, 
                        message.status, 
                        connectionId
                    );
                }
                break;

            case 'MERCHANT_LOGOUT':
                // Handle merchant logout - set all subscriptions to inactive
                if (message.businessId && message.userId) {
                    await handleMerchantLogout(
                        message.businessId,
                        message.userId,
                        connectionId
                    );
                }
                break;

            default:
                console.log('Unknown message type:', message.type);
                await sendMessageToConnection(connectionId, {
                    type: 'ERROR',
                    message: 'Unknown message type',
                    originalType: message.type
                });
        }

        return { statusCode: 200, body: 'Message processed' };

    } catch (error) {
        console.error('Error handling WebSocket message:', error);
        return { statusCode: 500, body: 'Failed to process message' };
    }
}

/**
 * Handle business status updates from WebSocket
 */
async function handleBusinessStatusUpdate(businessId, status, connectionId) {
    try {
        // Update business accepting orders status
        const updateParams = {
            TableName: process.env.BUSINESSES_TABLE || 'order-receiver-businesses-dev',
            Key: {
                businessId: businessId
            },
            UpdateExpression: 'SET acceptingOrders = :status, lastStatusUpdate = :timestamp',
            ExpressionAttributeValues: {
                ':status': status === 'online',
                ':timestamp': new Date().toISOString()
            }
        };

        await dynamodb.send(new UpdateCommand(updateParams));

        // Send confirmation back to the connection
        await sendMessageToConnection(connectionId, {
            type: 'STATUS_UPDATED',
            businessId: businessId,
            status: status,
            timestamp: new Date().toISOString()
        });

        console.log(`✅ Business status updated via WebSocket: ${businessId} -> ${status}`);

    } catch (error) {
        console.error('Error updating business status:', error);
        await sendMessageToConnection(connectionId, {
            type: 'ERROR',
            message: 'Failed to update business status',
            businessId: businessId
        });
    }
}

/**
 * Handle merchant online/offline status updates from toggle
 * Updates both business table and shared WebSocket subscription table
 */
async function handleMerchantStatusUpdate(businessId, userId, status, connectionId) {
    try {
        const isOnline = status === 'online';
        const timestamp = new Date().toISOString();
        
        // 1. Update business accepting orders status
        const businessUpdateParams = {
            TableName: process.env.BUSINESSES_TABLE || 'order-receiver-businesses-dev',
            Key: {
                businessId: businessId
            },
            UpdateExpression: 'SET acceptingOrders = :status, lastStatusUpdate = :timestamp',
            ExpressionAttributeValues: {
                ':status': isOnline,
                ':timestamp': timestamp
            }
        };

        await dynamodb.send(new UpdateCommand(businessUpdateParams));

        // 2. Update or create subscription in shared WebSocket subscription table
        const subscriptionId = `merchant_${businessId}_${userId}`;
        const subscriptionUpdateParams = {
            TableName: process.env.WEBSOCKET_SUBSCRIPTIONS_TABLE || 'WizzUser_websocket_subscriptions_dev',
            Key: {
                subscriptionId: subscriptionId
            },
            UpdateExpression: 'SET entityType = :entityType, entityId = :entityId, userId = :userId, #status = :status, topic = :topic, lastUpdate = :timestamp, isActive = :isActive',
            ExpressionAttributeNames: {
                '#status': 'status'
            },
            ExpressionAttributeValues: {
                ':entityType': 'merchant',
                ':entityId': businessId,
                ':userId': userId,
                ':status': status,
                ':topic': `merchant_status_${businessId}`,
                ':timestamp': timestamp,
                ':isActive': isOnline
            }
        };

        await dynamodb.send(new UpdateCommand(subscriptionUpdateParams));

        // 3. Broadcast status change to customers app via shared infrastructure
        await broadcastMerchantStatusChange(businessId, status, timestamp);

        // 4. Send confirmation back to the merchant
        await sendMessageToConnection(connectionId, {
            type: 'MERCHANT_STATUS_UPDATED',
            businessId: businessId,
            status: status,
            timestamp: timestamp,
            message: isOnline ? 'Restaurant is now online and accepting orders' : 'Restaurant is now offline - orders are paused'
        });

        console.log(`✅ Merchant status updated: ${businessId} -> ${status} (subscription: ${subscriptionId})`);

    } catch (error) {
        console.error('Error updating merchant status:', error);
        await sendMessageToConnection(connectionId, {
            type: 'ERROR',
            message: 'Failed to update merchant status',
            businessId: businessId,
            error: error.message
        });
    }
}

/**
 * Handle business status updates for the actual subscription pattern used by the app
 * Updates the business_status subscription that actually exists
 */
async function handleBusinessStatusSubscriptionUpdate(businessId, userId, status, connectionId) {
    try {
        const isOnline = status === 'online';
        const timestamp = new Date().toISOString();
        
        console.log(`🔄 Business status subscription update: ${businessId} -> ${status} (user: ${userId})`);
        
        // 1. Update business accepting orders status
        const businessUpdateParams = {
            TableName: process.env.BUSINESSES_TABLE || 'order-receiver-businesses-dev',
            Key: {
                businessId: businessId
            },
            UpdateExpression: 'SET acceptingOrders = :status, lastStatusUpdate = :timestamp',
            ExpressionAttributeValues: {
                ':status': isOnline,
                ':timestamp': timestamp
            }
        };

        await dynamodb.send(new UpdateCommand(businessUpdateParams));

        // 2. Find and update the actual subscription record using the business_status pattern
        // Search for subscriptions with businessId and userId matching
        const findSubscriptionParams = {
            TableName: process.env.WEBSOCKET_SUBSCRIPTIONS_TABLE || 'WizzUser_websocket_subscriptions_dev',
            FilterExpression: 'businessId = :businessId AND userId = :userId AND subscriptionType = :subType',
            ExpressionAttributeValues: {
                ':businessId': businessId,
                ':userId': userId,
                ':subType': 'business_status'
            }
        };

        const scanResult = await dynamodb.send(new ScanCommand(findSubscriptionParams));
        
        if (scanResult.Items && scanResult.Items.length > 0) {
            // Update each matching subscription
            const updatePromises = scanResult.Items.map(async (subscription) => {
                const updateParams = {
                    TableName: process.env.WEBSOCKET_SUBSCRIPTIONS_TABLE || 'WizzUser_websocket_subscriptions_dev',
                    Key: {
                        subscriptionId: subscription.subscriptionId
                    },
                    UpdateExpression: 'SET isActive = :isActive',
                    ExpressionAttributeValues: {
                        ':isActive': isOnline
                    }
                };
                
                return dynamodb.send(new UpdateCommand(updateParams));
            });
            
            await Promise.all(updatePromises);
            console.log(`✅ Updated ${scanResult.Items.length} business_status subscription(s) for ${businessId}`);
        } else {
            console.log(`⚠️ No business_status subscriptions found for ${businessId} and user ${userId}`);
        }

        // 3. Send confirmation back to the merchant
        await sendMessageToConnection(connectionId, {
            type: 'BUSINESS_STATUS_UPDATED',
            businessId: businessId,
            status: status,
            timestamp: timestamp,
            message: isOnline ? 'Restaurant is now online and accepting orders' : 'Restaurant is now offline - orders are paused'
        });

        console.log(`✅ Business status subscription updated: ${businessId} -> ${status}`);

    } catch (error) {
        console.error('Error updating business status subscription:', error);
        await sendMessageToConnection(connectionId, {
            type: 'ERROR',
            message: 'Failed to update business status subscription',
            businessId: businessId,
            error: error.message
        });
    }
}

/**
 * Handle merchant logout - set business offline and subscriptions inactive
 * This ensures that when merchant logs out, they appear offline to customers
 */
async function handleMerchantLogout(businessId, userId, connectionId) {
    try {
        const timestamp = new Date().toISOString();
        
        console.log(`🚪 Processing merchant logout: ${businessId} (user: ${userId})`);
        
        // 1. Set business to offline/not accepting orders
        const businessUpdateParams = {
            TableName: process.env.BUSINESSES_TABLE || 'WhizzMerchants_Businesses',
            Key: {
                businessId: businessId
            },
            UpdateExpression: 'SET acceptingOrders = :offline, lastStatusUpdate = :timestamp',
            ExpressionAttributeValues: {
                ':offline': false,
                ':timestamp': timestamp
            }
        };

        await dynamodb.send(new UpdateCommand(businessUpdateParams));
        console.log(`✅ Business set to offline: ${businessId}`);

        // 2. Set all business_status subscriptions to inactive
        const findSubscriptionParams = {
            TableName: process.env.WEBSOCKET_SUBSCRIPTIONS_TABLE || 'WizzUser_websocket_subscriptions_dev',
            FilterExpression: 'businessId = :businessId AND userId = :userId AND subscriptionType = :subType',
            ExpressionAttributeValues: {
                ':businessId': businessId,
                ':userId': userId,
                ':subType': 'business_status'
            }
        };

        const scanResult = await dynamodb.send(new ScanCommand(findSubscriptionParams));
        
        if (scanResult.Items && scanResult.Items.length > 0) {
            const updatePromises = scanResult.Items.map(async (subscription) => {
                const updateParams = {
                    TableName: process.env.WEBSOCKET_SUBSCRIPTIONS_TABLE || 'WizzUser_websocket_subscriptions_dev',
                    Key: {
                        subscriptionId: subscription.subscriptionId
                    },
                    UpdateExpression: 'SET isActive = :inactive, lastUpdate = :timestamp',
                    ExpressionAttributeValues: {
                        ':inactive': false,
                        ':timestamp': timestamp
                    }
                };
                
                return dynamodb.send(new UpdateCommand(updateParams));
            });
            
            await Promise.all(updatePromises);
            console.log(`✅ Set ${scanResult.Items.length} subscription(s) to inactive for ${businessId}`);
        }

        // 3. Broadcast logout status to customer apps
        await broadcastMerchantStatusChange(businessId, 'offline', timestamp);

        // 4. Send confirmation back to the merchant
        await sendMessageToConnection(connectionId, {
            type: 'MERCHANT_LOGOUT_CONFIRMED',
            businessId: businessId,
            status: 'offline',
            timestamp: timestamp,
            message: 'Logout processed - restaurant is now offline'
        });

        console.log(`✅ Merchant logout processed: ${businessId} -> offline`);

    } catch (error) {
        console.error('Error processing merchant logout:', error);
        await sendMessageToConnection(connectionId, {
            type: 'ERROR',
            message: 'Failed to process merchant logout',
            businessId: businessId,
            error: error.message
        });
    }
}

/**
 * Handle merchant logout - set all subscriptions to inactive
 */
async function handleMerchantLogout(businessId, userId, connectionId) {
    try {
        const timestamp = new Date().toISOString();
        
        console.log(`🔄 Merchant logout: ${businessId} (user: ${userId})`);
        
        // 1. Find and update all subscriptions for the merchant
        const findSubscriptionParams = {
            TableName: process.env.WEBSOCKET_SUBSCRIPTIONS_TABLE || 'WizzUser_websocket_subscriptions_dev',
            FilterExpression: 'businessId = :businessId AND userId = :userId',
            ExpressionAttributeValues: {
                ':businessId': businessId,
                ':userId': userId
            }
        };

        const scanResult = await dynamodb.send(new ScanCommand(findSubscriptionParams));
        
        if (scanResult.Items && scanResult.Items.length > 0) {
            // Update each matching subscription
            const updatePromises = scanResult.Items.map(async (subscription) => {
                const updateParams = {
                    TableName: process.env.WEBSOCKET_SUBSCRIPTIONS_TABLE || 'WizzUser_websocket_subscriptions_dev',
                    Key: {
                        subscriptionId: subscription.subscriptionId
                    },
                    UpdateExpression: 'SET isActive = :isActive, lastUpdate = :timestamp',
                    ExpressionAttributeValues: {
                        ':isActive': false,
                        ':timestamp': timestamp
                    }
                };
                
                return dynamodb.send(new UpdateCommand(updateParams));
            });
            
            await Promise.all(updatePromises);
            console.log(`✅ Updated ${scanResult.Items.length} subscription(s) to inactive for ${businessId}`);
        } else {
            console.log(`⚠️ No subscriptions found for ${businessId} and user ${userId}`);
        }

        // 2. Send confirmation back to the merchant
        await sendMessageToConnection(connectionId, {
            type: 'MERCHANT_LOGOUT_CONFIRMED',
            businessId: businessId,
            timestamp: timestamp,
            message: 'Merchant has been logged out and all subscriptions set to inactive'
        });

        console.log(`✅ Merchant logout processed: ${businessId}`);

    } catch (error) {
        console.error('Error processing merchant logout:', error);
        await sendMessageToConnection(connectionId, {
            type: 'ERROR',
            message: 'Failed to process merchant logout',
            businessId: businessId,
            error: error.message
        });
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
 * Broadcast merchant status change to customers app via shared WebSocket infrastructure
 * This notifies customers app about restaurant availability changes
 */
async function broadcastMerchantStatusChange(businessId, status, timestamp) {
    try {
        // Get all customer app subscriptions that should be notified about this merchant
        const customerSubscriptionsParams = {
            TableName: process.env.WEBSOCKET_SUBSCRIPTIONS_TABLE || 'WizzUser_websocket_subscriptions_dev',
            IndexName: 'topic-createdAt-index', // Use the existing GSI
            KeyConditionExpression: 'topic = :topic',
            ExpressionAttributeValues: {
                ':topic': `merchant_status_${businessId}` // Customers subscribe to specific merchant status updates
            }
        };

        const subscriptionsResult = await dynamodb.send(new QueryCommand(customerSubscriptionsParams));
        
        if (subscriptionsResult.Items && subscriptionsResult.Items.length > 0) {
            // Create broadcast message for customers app
            const broadcastMessage = {
                type: 'MERCHANT_STATUS_CHANGE',
                data: {
                    merchantId: businessId,
                    status: status,
                    timestamp: timestamp,
                    isAcceptingOrders: status === 'online'
                }
            };

            // Get active WebSocket connections for customer apps that are subscribed
            const connectionPromises = subscriptionsResult.Items.map(async (subscription) => {
                try {
                    // Get active WebSocket connections for this user/customer
                    const connectionsParams = {
                        TableName: process.env.WEBSOCKET_CONNECTIONS_TABLE || 'WizzUser_websocket_connections_dev',
                        IndexName: 'userId-topic-index', // Use the existing GSI
                        KeyConditionExpression: 'userId = :userId',
                        FilterExpression: 'entityType = :entityType AND isActive = :isActive',
                        ExpressionAttributeValues: {
                            ':userId': subscription.userId,
                            ':entityType': 'customer',
                            ':isActive': true
                        }
                    };

                    const connectionsResult = await dynamodb.send(new QueryCommand(connectionsParams));
                    
                    if (connectionsResult.Items && connectionsResult.Items.length > 0) {
                        // Send message to all active customer connections
                        const sendPromises = connectionsResult.Items.map(connection =>
                            sendMessageToConnection(connection.connectionId, broadcastMessage)
                        );
                        
                        await Promise.allSettled(sendPromises);
                        console.log(`📤 Sent merchant status update to ${connectionsResult.Items.length} customer connections for user ${subscription.userId}`);
                    }
                } catch (connectionError) {
                    console.warn(`Warning: Could not send to user ${subscription.userId}:`, connectionError.message);
                }
            });

            await Promise.allSettled(connectionPromises);
            console.log(`🔔 Merchant status broadcast completed for ${businessId}: ${subscriptionsResult.Items.length} subscribers notified`);
        } else {
            console.log(`ℹ️ No customer subscriptions found for merchant ${businessId}`);
        }

    } catch (error) {
        console.error('Error broadcasting merchant status change:', error);
        // Don't throw error - this is a notification feature, not critical for main functionality
    }
}

/**
 * Clean up stale connections (can be called periodically)
 */
async function cleanupStaleConnections() {
    try {
        console.log('🧹 Starting stale connection cleanup...');

        // Get all REAL connections using adapter
        const connections = await connectionsAdapter.getAllConnections(
            'connectionType = :connType',
            { ':connType': 'REAL' }
        );

        // Check for expired connections
        const currentTime = Math.floor(Date.now() / 1000);
        const expiredConnections = connections.filter(conn => 
            conn.ttl && conn.ttl < currentTime
        );

        console.log(`Found ${expiredConnections.length} expired connections out of ${connections.length} total`);

        // Remove expired connections
        for (const connection of expiredConnections) {
            await removeStaleConnection(connection.connectionId);
        }

        console.log(`✅ Cleaned up ${expiredConnections.length} stale connections`);
        return expiredConnections.length;

    } catch (error) {
        console.error('Error during stale connection cleanup:', error);
        return 0;
    }
}

/**
 * Get comprehensive business connection status
 */
async function getBusinessConnectionStatus(businessId) {
    try {
        // Get real WebSocket connections
        const realConnections = await getActiveConnectionsForBusiness(businessId);

        // Get login tracking connections (virtual connections)
        const allConnections = await connectionsAdapter.getBusinessConnections(businessId);
        const activeLoginConnections = allConnections.filter(conn => 
            conn.isLoginTracking === true
        );

        // Get business settings
        const businessParams = {
            TableName: process.env.BUSINESSES_TABLE || 'order-receiver-businesses-dev',
            Key: {
                businessId: businessId
            },
            ProjectionExpression: 'acceptingOrders, lastStatusUpdate'
        };

        const businessResult = await dynamodb.send(new GetCommand(businessParams));
        const businessData = businessResult.Item || {};

        return {
            businessId,
            hasRealTimeConnection: realConnections.length > 0,
            realConnectionsCount: realConnections.length,
            hasLoginTracking: activeLoginConnections.length > 0,
            loginTrackingCount: activeLoginConnections.length,
            acceptingOrders: businessData.acceptingOrders || false,
            lastStatusUpdate: businessData.lastStatusUpdate,
            overallStatus: determineOverallBusinessStatus(
                realConnections.length > 0,
                activeLoginConnections.length > 0,
                businessData.acceptingOrders || false
            ),
            connectionDetails: {
                realConnections: realConnections.map(conn => ({
                    connectionId: conn.connectionId,
                    connectedAt: conn.connectedAt,
                    lastHeartbeat: conn.lastHeartbeat
                })),
                loginTracking: activeLoginConnections.map(conn => ({
                    trackingId: conn.connectionId,
                    connectedAt: conn.connectedAt,
                    userId: conn.userId
                }))
            }
        };

    } catch (error) {
        console.error('Error getting business connection status:', error);
        return {
            businessId,
            hasRealTimeConnection: false,
            realConnectionsCount: 0,
            hasLoginTracking: false,
            loginTrackingCount: 0,
            acceptingOrders: false,
            overallStatus: 'offline',
            error: error.message
        };
    }
}

/**
 * Determine overall business status based on connection types and settings
 */
function determineOverallBusinessStatus(hasRealConnection, hasLoginTracking, acceptingOrders) {
    if (hasRealConnection && acceptingOrders) {
        return 'online'; // Fully operational
    } else if (hasLoginTracking && acceptingOrders) {
        return 'available'; // Available but no real-time connection
    } else if (hasLoginTracking || hasRealConnection) {
        return 'logged_in'; // Logged in but not accepting orders
    } else {
        return 'offline'; // No connections
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
    cleanupStaleConnections,
    getBusinessConnectionStatus,
    getActiveConnectionsForBusiness,
    removeStaleConnection,
    updateConnectionHeartbeat
};
