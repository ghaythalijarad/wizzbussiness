const AWS = require('aws-sdk');

// Configure AWS SDK
AWS.config.update({
    region: 'us-east-1'
});

const dynamodb = new AWS.DynamoDB();

async function checkOrdersForBusiness() {
    try {
        console.log('🔍 Checking orders for business g87_a@yahoo.com...');
        console.log('Business ID: 892161df-6cb0-4a2a-ac04-5a09e206c81e');

        // First, let's scan all orders to see what's there
        const scanParams = {
            TableName: 'order-receiver-orders-dev'
        };

        const scanResult = await dynamodb.scan(scanParams).promise();
        console.log(`\n📊 Total orders in table: ${scanResult.Items.length}`);

        if (scanResult.Items.length > 0) {
            console.log('\n📋 All orders found:');
            scanResult.Items.forEach((item, index) => {
                console.log(`\n${index + 1}. Order ID: ${item.orderId?.S || 'N/A'}`);
                console.log(`   Store ID: ${item.storeId?.S || 'N/A'}`);
                console.log(`   Business ID: ${item.businessId?.S || 'N/A'}`);
                console.log(`   Status: ${item.status?.S || 'N/A'}`);
                console.log(`   Created: ${item.createdAt?.S || 'N/A'}`);
                console.log(`   Total: ${item.total?.N || 'N/A'}`);
                console.log(`   Customer: ${item.customerName?.S || 'N/A'}`);
            });

            // Check for orders matching our business
            const businessOrders = scanResult.Items.filter(item =>
                item.businessId?.S === '892161df-6cb0-4a2a-ac04-5a09e206c81e' ||
                item.storeId?.S === '892161df-6cb0-4a2a-ac04-5a09e206c81e'
            );

            console.log(`\n🎯 Orders for business g87_a@yahoo.com: ${businessOrders.length}`);

            if (businessOrders.length > 0) {
                businessOrders.forEach((order, index) => {
                    console.log(`\n✅ Order ${index + 1}:`);
                    console.log(`   Order ID: ${order.orderId?.S}`);
                    console.log(`   Status: ${order.status?.S}`);
                    console.log(`   Total: ${order.total?.N}`);
                    console.log(`   Created: ${order.createdAt?.S}`);
                });
            } else {
                console.log('❌ No orders found for this business');
            }
        } else {
            console.log('📝 No orders found in the table');
        }

    } catch (error) {
        console.error('❌ Error:', error);
    }
}

checkOrdersForBusiness();
