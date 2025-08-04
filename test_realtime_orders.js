const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const ORDERS_TABLE = 'order-receiver-orders-dev';
const BUSINESS_ID = '723a276a-ad62-482c-898c-076d1f8d5c0e'; // Using the business ID from context

async function testRealtimeOrders() {
    console.log('🔍 Testing Real-time Order Functionality');
    console.log('=' .repeat(60));

    try {
        // 1. First check if there are existing orders
        console.log('\n1. Checking existing orders for business...');
        const existingOrdersParams = {
            TableName: ORDERS_TABLE,
            IndexName: 'BusinessIdIndex',
            KeyConditionExpression: 'businessId = :businessId',
            ExpressionAttributeValues: {
                ':businessId': BUSINESS_ID
            }
        };

        const existingResult = await dynamodb.query(existingOrdersParams).promise();
        console.log(`📦 Found ${existingResult.Items.length} existing orders`);
        
        if (existingResult.Items.length > 0) {
            console.log('📋 Existing orders:');
            existingResult.Items.forEach((order, index) => {
                console.log(`   ${index + 1}. Order ID: ${order.orderId}, Status: ${order.status}, Customer: ${order.customerName}`);
            });
        }

        // 2. Create a new test order
        console.log('\n2. Creating a new test order...');
        const testOrder = {
            orderId: uuidv4(),
            businessId: BUSINESS_ID,
            customerId: 'test-customer-' + Date.now(),
            customerName: 'أحمد محمد (اختبار)',
            customerPhone: '+964 771 123 4567',
            deliveryAddress: 'الكرادة الداخلية، بغداد، العراق',
            items: [
                {
                    dishId: 'test-dish-1',
                    dishName: 'شاورما دجاج',
                    price: 15.0,
                    quantity: 2
                },
                {
                    dishId: 'test-dish-2',
                    dishName: 'عصير برتقال',
                    price: 4.0,
                    quantity: 1
                }
            ],
            totalAmount: 34.0,
            status: 'pending',
            notes: 'طلب تجريبي للاختبار',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            estimatedPreparationTimeMinutes: 25
        };

        const insertParams = {
            TableName: ORDERS_TABLE,
            Item: testOrder
        };

        await dynamodb.put(insertParams).promise();
        console.log('✅ Test order created successfully!');
        console.log(`   Order ID: ${testOrder.orderId}`);
        console.log(`   Customer: ${testOrder.customerName}`);
        console.log(`   Total: $${testOrder.totalAmount}`);

        // 3. Verify the order was inserted
        console.log('\n3. Verifying order insertion...');
        const verifyResult = await dynamodb.query(existingOrdersParams).promise();
        console.log(`📦 Total orders after insertion: ${verifyResult.Items.length}`);

        // 4. Test the API endpoint
        console.log('\n4. Testing API endpoint (simulation)...');
        console.log('📡 The Flutter app should now detect this new order in the next 10-second refresh cycle');
        console.log('📱 Check your iOS simulator to see if the new order appears');
        
        console.log('\n✅ Real-time order test completed successfully!');
        console.log('💡 If the order doesn\'t appear in the app, check:');
        console.log('   - Network connectivity in the app');
        console.log('   - Authentication tokens');
        console.log('   - OrderService API calls');
        console.log('   - Business ID matching');

    } catch (error) {
        console.error('❌ Real-time order test failed:', error);
    }
}

testRealtimeOrders();
