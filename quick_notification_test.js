#!/usr/bin/env node

/**
 * Quick notification test - send one test order
 */

const axios = require('axios');

// Configuration
const WEBHOOK_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/webhooks/orders';
const TEST_MERCHANT_ID = '752c2ea5-e7b1-4f3f-9760-487fafbe0ec0';

async function sendTestOrder() {
    const testOrder = {
        orderId: `test-order-${Date.now()}`,
        businessId: TEST_MERCHANT_ID,
        customerId: 'customer-123',
        customerName: 'Real-Time Test Customer',
        customerPhone: '+1234567890',
        deliveryAddress: {
            street: '123 Test Street',
            city: 'Test City',
            state: 'TS',
            zipCode: '12345'
        },
        items: [
            {
                id: 'item-1',
                name: 'Test Burger',
                price: 15.99,
                quantity: 1
            }
        ],
        totalAmount: 15.99,
        status: 'pending',
        notes: 'Real-time notification test order',
        platformOrderId: `platform-${Date.now()}`
    };

    try {
        console.log('🚀 Sending test order for real-time notification...');
        console.log(`📦 Order ID: ${testOrder.orderId}`);
        console.log(`🏪 Merchant ID: ${testOrder.businessId}`);
        console.log(`💰 Total: $${testOrder.totalAmount}`);
        
        const response = await axios.post(WEBHOOK_URL, testOrder, {
            headers: {
                'Content-Type': 'application/json'
            },
            timeout: 10000
        });

        if (response.status === 200 || response.status === 201) {
            console.log('✅ Test order sent successfully!');
            console.log('📱 Check your Flutter app for the real-time notification!');
            console.log('🔔 You should see a green popup with the new order notification');
        } else {
            console.log(`❌ Unexpected response status: ${response.status}`);
        }

    } catch (error) {
        console.error('❌ Error sending test order:', error.response?.data || error.message);
    }
}

// Execute the test
sendTestOrder();
