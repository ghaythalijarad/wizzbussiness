#!/usr/bin/env node

const WebSocket = require('ws');
const axios = require('axios');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

// Configuration
const API_BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const WEBSOCKET_BASE_URL = 'wss://uhb1o9jggg.execute-api.us-east-1.amazonaws.com/dev';
const TEST_BUSINESS_ID = 'business_123'; // Default test business ID
const TIMEOUT_MS = 30000; // 30 seconds timeout

// AWS Configuration
const dynamoDbClient = new DynamoDBClient({ region: 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

class RealtimeNotificationTester {
    constructor() {
        this.webSocket = null;
        this.receivedNotifications = [];
        this.ordersReceived = [];
        this.testResults = {
            websocketConnection: false,
            orderWebhook: false,
            realtimeNotification: false,
            notificationContent: false,
            orderInDatabase: false
        };
    }

    /**
     * Run comprehensive real-time notification test
     */
    async runTest(businessId = TEST_BUSINESS_ID) {
        console.log('🚀 Starting Real-time Notification Test');
        console.log('=====================================');
        console.log(`📍 Business ID: ${businessId}`);
        console.log(`🌐 WebSocket URL: ${WEBSOCKET_BASE_URL}`);
        console.log(`🔗 API URL: ${API_BASE_URL}`);
        console.log('');

        try {
            // Step 1: Establish WebSocket connection
            await this.connectWebSocket(businessId);
            
            // Step 2: Wait for connection to stabilize
            await this.delay(2000);
            
            // Step 3: Send test order via webhook
            const orderId = await this.sendTestOrder(businessId);
            
            if (orderId) {
                // Step 4: Wait for real-time notification
                console.log('⏳ Waiting for real-time notification...');
                await this.waitForNotification(orderId, 15000);
                
                // Step 5: Verify order in database
                await this.verifyOrderInDatabase(orderId);
            }
            
            // Step 6: Check merchant endpoints
            await this.checkMerchantEndpoints(businessId);
            
            // Generate test report
            this.generateTestReport();
            
        } catch (error) {
            console.error('❌ Test failed with error:', error.message);
            this.generateTestReport();
        } finally {
            // Cleanup
            if (this.webSocket) {
                this.webSocket.close();
            }
        }
    }

    /**
     * Establish WebSocket connection
     */
    async connectWebSocket(businessId) {
        return new Promise((resolve, reject) => {
            console.log('🔌 Step 1: Establishing WebSocket connection...');
            
            const wsUrl = `${WEBSOCKET_BASE_URL}?merchantId=${businessId}`;
            console.log(`🔗 Connecting to: ${wsUrl}`);
            
            this.webSocket = new WebSocket(wsUrl);
            
            const timeout = setTimeout(() => {
                reject(new Error('WebSocket connection timeout'));
            }, 10000);
            
            this.webSocket.on('open', () => {
                clearTimeout(timeout);
                console.log('✅ WebSocket connected successfully');
                this.testResults.websocketConnection = true;
                
                // Send subscription message
                this.webSocket.send(JSON.stringify({
                    type: 'SUBSCRIBE_ORDERS',
                    businessId: businessId
                }));
                
                resolve();
            });
            
            this.webSocket.on('message', (data) => {
                try {
                    const message = JSON.parse(data);
                    console.log('📨 WebSocket message received:', message);
                    
                    this.receivedNotifications.push({
                        ...message,
                        receivedAt: new Date().toISOString()
                    });
                    
                    // Check if this is a new order notification
                    if (message.type === 'NEW_ORDER' && message.data) {
                        console.log('🆕 NEW ORDER notification received:');
                        console.log(`   Order ID: ${message.data.orderId}`);
                        console.log(`   Customer: ${message.data.customerName}`);
                        console.log(`   Total: $${message.data.totalAmount}`);
                        
                        this.testResults.realtimeNotification = true;
                        this.testResults.notificationContent = true;
                        this.ordersReceived.push(message.data);
                    }
                } catch (error) {
                    console.error('Error parsing WebSocket message:', error);
                }
            });
            
            this.webSocket.on('error', (error) => {
                clearTimeout(timeout);
                console.error('❌ WebSocket error:', error);
                reject(error);
            });
            
            this.webSocket.on('close', (code, reason) => {
                console.log(`🔌 WebSocket closed: ${code} - ${reason}`);
            });
        });
    }

    /**
     * Send test order via webhook
     */
    async sendTestOrder(businessId) {
        console.log('\n📦 Step 2: Sending test order via webhook...');
        
        const orderId = `realtime_test_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        
        const orderPayload = {
            orderId: orderId,
            businessId: businessId,
            customerId: `customer_${Date.now()}`,
            customerName: "Real-time Test Customer",
            customerPhone: "+1234567890",
            deliveryAddress: {
                street: "123 Test Street",
                city: "Test City",
                state: "TS",
                zipCode: "12345",
                country: "USA"
            },
            items: [
                {
                    id: "item_001",
                    name: "Test Burger",
                    quantity: 1,
                    price: 15.99,
                    customizations: ["Extra cheese", "No onions"]
                },
                {
                    id: "item_002", 
                    name: "Test Fries",
                    quantity: 1,
                    price: 4.99
                }
            ],
            totalAmount: 20.98,
            notes: "Real-time notification test order",
            platformOrderId: `platform_${orderId}`
        };

        try {
            const response = await axios.post(
                `${API_BASE_URL}/webhooks/orders`,
                orderPayload,
                {
                    headers: {
                        'Content-Type': 'application/json',
                        'User-Agent': 'RealtimeNotificationTester/1.0'
                    },
                    timeout: 10000
                }
            );

            if (response.status === 200 || response.status === 201) {
                console.log('✅ Test order webhook sent successfully');
                console.log(`📦 Order ID: ${orderId}`);
                console.log('📋 Response:', JSON.stringify(response.data, null, 2));
                this.testResults.orderWebhook = true;
                return orderId;
            } else {
                console.error('❌ Webhook failed with status:', response.status);
                return null;
            }

        } catch (error) {
            console.error('❌ Error sending webhook:', error.message);
            if (error.response) {
                console.error('📄 Response data:', error.response.data);
                console.error('📊 Response status:', error.response.status);
            }
            return null;
        }
    }

    /**
     * Wait for real-time notification
     */
    async waitForNotification(orderId, timeoutMs = 15000) {
        return new Promise((resolve) => {
            console.log(`⏳ Waiting up to ${timeoutMs/1000} seconds for real-time notification...`);
            
            const startTime = Date.now();
            const checkInterval = setInterval(() => {
                // Check if we received the specific order notification
                const orderNotification = this.receivedNotifications.find(notification => 
                    notification.type === 'NEW_ORDER' && 
                    notification.data && 
                    notification.data.orderId === orderId
                );
                
                if (orderNotification) {
                    clearInterval(checkInterval);
                    console.log('✅ Real-time notification received for order:', orderId);
                    resolve(true);
                    return;
                }
                
                // Check timeout
                if (Date.now() - startTime > timeoutMs) {
                    clearInterval(checkInterval);
                    console.log('⏰ Timeout waiting for real-time notification');
                    resolve(false);
                }
            }, 500);
        });
    }

    /**
     * Verify order exists in database
     */
    async verifyOrderInDatabase(orderId) {
        console.log('\n🔍 Step 3: Verifying order in database...');
        
        try {
            // Query orders table to find the order
            const params = {
                TableName: 'order-receiver-orders-dev',
                FilterExpression: 'orderId = :orderId',
                ExpressionAttributeValues: {
                    ':orderId': orderId
                }
            };

            const result = await dynamodb.send(new ScanCommand(params));
            
            if (result.Items && result.Items.length > 0) {
                console.log('✅ Order found in database');
                console.log('📋 Order details:', JSON.stringify(result.Items[0], null, 2));
                this.testResults.orderInDatabase = true;
            } else {
                console.log('❌ Order not found in database');
            }

        } catch (error) {
            console.error('❌ Error checking database:', error.message);
        }
    }

    /**
     * Check merchant endpoints in database
     */
    async checkMerchantEndpoints(businessId) {
        console.log('\n🔍 Step 4: Checking merchant endpoints...');
        
        try {
            const params = {
                TableName: 'order-receiver-merchant-endpoints-dev',
                FilterExpression: 'merchantId = :merchantId',
                ExpressionAttributeValues: {
                    ':merchantId': businessId
                }
            };

            const result = await dynamodb.send(new ScanCommand(params));
            
            console.log(`📊 Found ${result.Items.length} endpoints for merchant ${businessId}:`);
            result.Items.forEach(endpoint => {
                console.log(`   - Type: ${endpoint.endpointType}, Active: ${endpoint.isActive}, Connected: ${endpoint.connectedAt || endpoint.registeredAt}`);
            });

        } catch (error) {
            console.error('❌ Error checking merchant endpoints:', error.message);
        }
    }

    /**
     * Generate test report
     */
    generateTestReport() {
        console.log('\n📊 TEST REPORT');
        console.log('===============');
        
        const results = this.testResults;
        const passed = Object.values(results).filter(Boolean).length;
        const total = Object.keys(results).length;
        
        console.log(`✅ Passed: ${passed}/${total} tests`);
        console.log('');
        
        console.log('📋 Test Results:');
        console.log(`   WebSocket Connection: ${results.websocketConnection ? '✅ PASS' : '❌ FAIL'}`);
        console.log(`   Order Webhook: ${results.orderWebhook ? '✅ PASS' : '❌ FAIL'}`);
        console.log(`   Real-time Notification: ${results.realtimeNotification ? '✅ PASS' : '❌ FAIL'}`);
        console.log(`   Notification Content: ${results.notificationContent ? '✅ PASS' : '❌ FAIL'}`);
        console.log(`   Order in Database: ${results.orderInDatabase ? '✅ PASS' : '❌ FAIL'}`);
        
        console.log('');
        console.log('📨 Notifications Received:', this.receivedNotifications.length);
        console.log('🆕 New Orders Received:', this.ordersReceived.length);
        
        if (this.receivedNotifications.length > 0) {
            console.log('\n📋 Notification Details:');
            this.receivedNotifications.forEach((notification, index) => {
                console.log(`   ${index + 1}. Type: ${notification.type}, Time: ${notification.receivedAt}`);
            });
        }

        // Overall result
        const overallSuccess = results.websocketConnection && 
                              results.orderWebhook && 
                              results.realtimeNotification && 
                              results.notificationContent;

        console.log('\n🎯 OVERALL RESULT:');
        if (overallSuccess) {
            console.log('✅ Real-time notifications are working correctly!');
            console.log('🎉 Orders should appear instantly in the Flutter app');
        } else {
            console.log('❌ Real-time notifications have issues');
            console.log('🔧 Check the failed tests above for debugging');
        }
    }

    /**
     * Delay helper
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Command line interface
async function main() {
    const businessId = process.argv[2] || TEST_BUSINESS_ID;
    
    console.log('🧪 Real-time Notification End-to-End Test');
    console.log('=========================================');
    
    const tester = new RealtimeNotificationTester();
    await tester.runTest(businessId);
}

// Handle uncaught errors
process.on('unhandledRejection', (reason, promise) => {
    console.error('❌ Unhandled Promise Rejection:', reason);
    process.exit(1);
});

process.on('uncaughtException', (error) => {
    console.error('❌ Uncaught Exception:', error);
    process.exit(1);
});

// Run the test if this file is executed directly
if (require.main === module) {
    main().catch(error => {
        console.error('❌ Test execution failed:', error);
        process.exit(1);
    });
}

module.exports = RealtimeNotificationTester;
