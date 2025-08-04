#!/usr/bin/env node

/**
 * End-to-End WebSocket Notification Test
 * Tests the complete flow: Webhook → Database → WebSocket Notification
 */

const WebSocket = require('ws');
const axios = require('axios');

// Configuration
const WEBHOOK_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/webhooks/orders';
const WEBSOCKET_URL = 'wss://ujyixy3uh5.execute-api.us-east-1.amazonaws.com/dev';

// Test merchants from database
const TEST_MERCHANTS = [
    '752c2ea5-e7b1-4f3f-9760-487fafbe0ec0',
    '7ccf646c-9594-48d4-8f63-c366d89257e5',
    '892161df-6cb0-4a2a-ac04-5a09e206c81e'
];

class WebSocketTester {
    constructor() {
        this.connections = new Map();
        this.messageCounters = new Map();
    }

    /**
     * Create WebSocket connection for a merchant
     */
    async connectMerchant(merchantId) {
        return new Promise((resolve, reject) => {
            const wsUrl = `${WEBSOCKET_URL}?merchantId=${merchantId}`;
            const ws = new WebSocket(wsUrl);

            ws.on('open', () => {
                console.log(`✅ WebSocket connected for merchant: ${merchantId}`);
                this.connections.set(merchantId, ws);
                this.messageCounters.set(merchantId, 0);
                resolve(ws);
            });

            ws.on('message', (data) => {
                const message = JSON.parse(data.toString());
                const count = this.messageCounters.get(merchantId) + 1;
                this.messageCounters.set(merchantId, count);
                
                console.log(`📨 Message received for ${merchantId} (#${count}):`, {
                    type: message.type,
                    orderId: message.order?.id,
                    timestamp: message.timestamp
                });

                // Handle specific message types
                this.handleWebSocketMessage(merchantId, message);
            });

            ws.on('error', (error) => {
                console.error(`❌ WebSocket error for ${merchantId}:`, error.message);
                reject(error);
            });

            ws.on('close', () => {
                console.log(`🔌 WebSocket closed for merchant: ${merchantId}`);
                this.connections.delete(merchantId);
            });

            // Timeout after 10 seconds
            setTimeout(() => {
                if (ws.readyState === WebSocket.CONNECTING) {
                    reject(new Error('Connection timeout'));
                }
            }, 10000);
        });
    }

    /**
     * Handle received WebSocket message
     */
    handleWebSocketMessage(merchantId, message) {
        switch (message.type) {
            case 'CONNECTION_ESTABLISHED':
                console.log(`🎉 Connection established for ${merchantId}`);
                break;
            
            case 'NEW_ORDER':
                console.log(`🆕 New order notification for ${merchantId}:`, {
                    orderId: message.order?.id,
                    customerName: message.order?.customer?.name,
                    total: message.order?.total,
                    items: message.order?.items?.length
                });
                break;
            
            case 'ORDER_UPDATE':
                console.log(`🔄 Order update for ${merchantId}:`, {
                    orderId: message.order?.id,
                    status: message.order?.status
                });
                break;
            
            default:
                console.log(`📋 Message type: ${message.type}`);
        }
    }

    /**
     * Send test order webhook
     */
    async sendTestOrder(merchantId) {
        const orderId = `order_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        
        const orderPayload = {
            orderId: orderId,
            businessId: merchantId,
            customerId: `customer_${Date.now()}`,
            customerName: "John Doe",
            customerPhone: "+1234567890",
            deliveryAddress: {
                street: "123 Main St",
                city: "New York",
                state: "NY",
                zipCode: "10001",
                country: "USA"
            },
            items: [
                {
                    id: "item_001",
                    name: "Deluxe Burger",
                    quantity: 1,
                    price: 15.99,
                    customizations: ["No onions", "Extra cheese"]
                },
                {
                    id: "item_002",
                    name: "French Fries",
                    quantity: 1,
                    price: 4.99
                },
                {
                    id: "item_003",
                    name: "Coca Cola",
                    quantity: 1,
                    price: 2.99
                }
            ],
            totalAmount: 23.97,
            notes: "Please ring the doorbell twice",
            platformOrderId: `platform_${orderId}`
        };

        try {
            console.log(`🚀 Sending test order for merchant: ${merchantId}`);
            console.log(`📦 Order ID: ${orderId}`);

            const response = await axios.post(WEBHOOK_URL, orderPayload, {
                headers: {
                    'Content-Type': 'application/json',
                    'User-Agent': 'WebSocketTester/1.0'
                },
                timeout: 10000
            });

            if (response.status === 200 || response.status === 201) {
                console.log(`✅ Webhook sent successfully for ${merchantId}`);
                return orderId;
            } else {
                console.error(`❌ Webhook failed for ${merchantId}:`, response.status);
                return null;
            }

        } catch (error) {
            console.error(`❌ Error sending webhook for ${merchantId}:`, error.message);
            return null;
        }
    }

    /**
     * Wait for WebSocket message
     */
    async waitForMessage(merchantId, timeout = 30000) {
        return new Promise((resolve, reject) => {
            const ws = this.connections.get(merchantId);
            if (!ws) {
                reject(new Error(`No WebSocket connection for merchant: ${merchantId}`));
                return;
            }

            const initialCount = this.messageCounters.get(merchantId) || 0;
            
            const checkForMessage = () => {
                const currentCount = this.messageCounters.get(merchantId) || 0;
                if (currentCount > initialCount) {
                    resolve(currentCount - initialCount);
                } else {
                    setTimeout(checkForMessage, 1000);
                }
            };

            // Start checking
            setTimeout(checkForMessage, 1000);

            // Timeout
            setTimeout(() => {
                reject(new Error(`Timeout waiting for message for merchant: ${merchantId}`));
            }, timeout);
        });
    }

    /**
     * Close all connections
     */
    closeAllConnections() {
        console.log('\n🔌 Closing all WebSocket connections...');
        this.connections.forEach((ws, merchantId) => {
            ws.close();
            console.log(`🔌 Closed connection for merchant: ${merchantId}`);
        });
        this.connections.clear();
    }

    /**
     * Print test results
     */
    printResults() {
        console.log('\n📊 Test Results:');
        console.log('================');
        
        this.messageCounters.forEach((count, merchantId) => {
            console.log(`${merchantId}: ${count} messages received`);
        });
        
        const totalMessages = Array.from(this.messageCounters.values()).reduce((sum, count) => sum + count, 0);
        console.log(`\nTotal messages received: ${totalMessages}`);
    }
}

/**
 * Main test function
 */
async function runEndToEndTest() {
    console.log('🚀 Starting End-to-End WebSocket Notification Test');
    console.log('=================================================\n');

    const tester = new WebSocketTester();

    try {
        // Step 1: Connect WebSockets for all test merchants
        console.log('📡 Step 1: Establishing WebSocket connections...\n');
        
        for (const merchantId of TEST_MERCHANTS) {
            try {
                await tester.connectMerchant(merchantId);
                await new Promise(resolve => setTimeout(resolve, 1000)); // Wait between connections
            } catch (error) {
                console.error(`❌ Failed to connect merchant ${merchantId}:`, error.message);
            }
        }

        console.log(`\n✅ Connected ${tester.connections.size} merchants\n`);

        // Step 2: Send test orders and wait for notifications
        console.log('📦 Step 2: Sending test orders and waiting for notifications...\n');

        for (const merchantId of TEST_MERCHANTS) {
            if (tester.connections.has(merchantId)) {
                try {
                    // Send webhook
                    const orderId = await tester.sendTestOrder(merchantId);
                    
                    if (orderId) {
                        console.log(`⏳ Waiting for WebSocket notification for ${merchantId}...`);
                        
                        // Wait for WebSocket notification
                        try {
                            const messageCount = await tester.waitForMessage(merchantId, 30000);
                            console.log(`✅ Received ${messageCount} notification(s) for ${merchantId}\n`);
                        } catch (error) {
                            console.error(`❌ No notification received for ${merchantId}: ${error.message}\n`);
                        }
                    }
                    
                    // Wait between orders
                    await new Promise(resolve => setTimeout(resolve, 2000));
                    
                } catch (error) {
                    console.error(`❌ Error testing merchant ${merchantId}:`, error.message);
                }
            }
        }

        // Step 3: Print results
        tester.printResults();

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        // Cleanup
        tester.closeAllConnections();
        console.log('\n🏁 Test completed');
    }
}

/**
 * Test individual components
 */
async function testComponents() {
    console.log('🔧 Testing Individual Components');
    console.log('===============================\n');

    // Test 1: WebSocket Connection
    console.log('🔌 Test 1: WebSocket Connection');
    const tester = new WebSocketTester();
    
    try {
        const testMerchant = TEST_MERCHANTS[0];
        await tester.connectMerchant(testMerchant);
        console.log('✅ WebSocket connection test passed\n');
        
        // Wait a bit to see connection established message
        await new Promise(resolve => setTimeout(resolve, 3000));
        
        tester.closeAllConnections();
    } catch (error) {
        console.error('❌ WebSocket connection test failed:', error.message, '\n');
    }

    // Test 2: Webhook Only
    console.log('📡 Test 2: Webhook Delivery');
    try {
        const testMerchant = TEST_MERCHANTS[0];
        const orderId = await tester.sendTestOrder(testMerchant);
        
        if (orderId) {
            console.log('✅ Webhook delivery test passed\n');
        } else {
            console.error('❌ Webhook delivery test failed\n');
        }
    } catch (error) {
        console.error('❌ Webhook delivery test failed:', error.message, '\n');
    }
}

// Run tests based on command line argument
const testType = process.argv[2] || 'full';

switch (testType) {
    case 'components':
        testComponents();
        break;
    case 'full':
    default:
        runEndToEndTest();
        break;
}
