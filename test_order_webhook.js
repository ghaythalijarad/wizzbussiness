const https = require('https');

// Test order data
const testOrder = {
    orderId: "test_order_" + Date.now(),
    businessId: "business_123", // This should match a real business ID from your app
    customerId: "customer_456",
    customerName: "John Doe",
    customerPhone: "+1234567890",
    deliveryAddress: {
        street: "123 Test Street",
        city: "Test City",
        state: "TC",
        zipCode: "12345"
    },
    items: [
        {
            productId: "prod_001",
            name: "Test Burger",
            quantity: 2,
            price: 12.99,
            customizations: ["No onions", "Extra cheese"]
        },
        {
            productId: "prod_002", 
            name: "French Fries",
            quantity: 1,
            price: 4.99
        }
    ],
    totalAmount: 30.97,
    notes: "Please ring doorbell",
    platformOrderId: "platform_order_" + Date.now()
};

const postData = JSON.stringify(testOrder);

const options = {
    hostname: '72nmgq5rc4.execute-api.us-east-1.amazonaws.com',
    port: 443,
    path: '/dev/webhooks/orders',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
    }
};

console.log('🧪 Testing order webhook with data:', JSON.stringify(testOrder, null, 2));

const req = https.request(options, (res) => {
    let data = '';
    
    res.on('data', (chunk) => {
        data += chunk;
    });
    
    res.on('end', () => {
        console.log('\n📡 Response Status:', res.statusCode);
        console.log('📡 Response Headers:', res.headers);
        console.log('📡 Response Body:', data);
        
        try {
            const responseJson = JSON.parse(data);
            if (responseJson.success) {
                console.log('✅ Order webhook test PASSED!');
                console.log('🆔 Order ID:', responseJson.orderId);
            } else {
                console.log('❌ Order webhook test FAILED:', responseJson.message);
            }
        } catch (e) {
            console.log('❌ Failed to parse response as JSON:', data);
        }
    });
});

req.on('error', (e) => {
    console.error('❌ Request error:', e);
});

req.write(postData);
req.end();
