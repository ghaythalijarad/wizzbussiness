const axios = require('axios');

// Updated API endpoints with correct paths
const API_BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

// Test data
const testBusinessId = 'test-business-123';
const testOrderId = 'test-order-456';
const testMerchantId = 'test-merchant-789';

/**
 * Test all merchant endpoints
 */
async function testMerchantEndpoints() {
    console.log('🧪 Testing Merchant Order Management Endpoints');
    console.log('API Base URL:', API_BASE_URL);
    console.log('=====================================\n');

    // Test 1: Get orders for business (corrected path)
    await testEndpoint('GET Orders for Business',
        'GET',
        `/merchant/orders/${testBusinessId}?status=pending`
    );

    // Test 2: Confirm order (corrected path)
    await testEndpoint('Confirm Order',
        'PUT',
        `/merchant/order/${testOrderId}/confirm`,
        { estimatedPreparationTime: 25 }
    );

    // Test 3: Reject order (corrected path)
    await testEndpoint('Reject Order',
        'PUT',
        `/merchant/order/${testOrderId}/reject`,
        { reason: 'Out of ingredients' }
    );

    // Test 4: Update order status (corrected path)
    await testEndpoint('Update Order Status',
        'PUT',
        `/merchant/order/${testOrderId}/status`,
        { status: 'preparing', notes: 'Started cooking' }
    );

    // Test 5: Register device token
    await testEndpoint('Register Device Token',
        'POST',
        `/merchants/${testMerchantId}/device-token`,
        { deviceToken: 'test-fcm-token-123', platform: 'android' }
    );

    // Test 6: Webhook for incoming orders
    await testEndpoint('Webhook - Incoming Order',
        'POST',
        '/webhooks/orders',
        {
            orderId: 'webhook-order-123',
            businessId: testBusinessId,
            customerId: 'customer-456',
            customerName: 'John Doe',
            customerPhone: '+1234567890',
            deliveryAddress: '123 Main St, City',
            items: [
                { name: 'Burger', quantity: 2, price: 15.99 },
                { name: 'Fries', quantity: 1, price: 5.99 }
            ],
            totalAmount: 37.97,
            notes: 'Extra sauce please',
            platformOrderId: 'platform-order-789'
        }
    );

    console.log('\n🏁 All tests completed!');
}

/**
 * Test individual endpoint
 */
async function testEndpoint(testName, method, path, data = null) {
    try {
        console.log(`📡 Testing: ${testName}`);
        console.log(`   ${method} ${path}`);

        const config = {
            method: method.toLowerCase(),
            url: `${API_BASE_URL}${path}`,
            headers: {
                'Content-Type': 'application/json'
            }
        };

        if (data && (method === 'POST' || method === 'PUT')) {
            config.data = data;
            console.log(`   Body:`, JSON.stringify(data, null, 2));
        }

        const response = await axios(config);

        console.log(`   ✅ Status: ${response.status}`);
        console.log(`   Response:`, JSON.stringify(response.data, null, 2));
        console.log('');

    } catch (error) {
        console.log(`   ❌ Error: ${error.response?.status || 'Network Error'}`);
        if (error.response?.data) {
            console.log(`   Error Details:`, JSON.stringify(error.response.data, null, 2));
        } else {
            console.log(`   Error Message:`, error.message);
        }
        console.log('');
    }
}

// Run tests
testMerchantEndpoints().catch(console.error);
