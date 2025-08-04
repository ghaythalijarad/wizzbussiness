const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({
    region: 'us-east-1',
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
});

const dynamodb = new AWS.DynamoDB.DocumentClient();

async function checkLoggedInBusiness() {
    try {
        console.log('🔍 Checking business for logged-in account: g87_a@yahoo.com');

        // First, let's scan the businesses table to find this email
        const businessParams = {
            TableName: 'order-receiver-businesses-dev',
            FilterExpression: 'ownerEmail = :email',
            ExpressionAttributeValues: {
                ':email': 'g87_a@yahoo.com'
            }
        };

        console.log('📋 Scanning businesses table...');
        const businessResult = await dynamodb.scan(businessParams).promise();

        if (businessResult.Items && businessResult.Items.length > 0) {
            const business = businessResult.Items[0];
            console.log('✅ Found business for g87_a@yahoo.com:');
            console.log('   Business ID:', business.businessId);
            console.log('   Business Name:', business.businessName);
            console.log('   Owner Email:', business.ownerEmail);
            console.log('   Store ID:', business.storeId || 'Not set');
            console.log('   Full business data:', JSON.stringify(business, null, 2));

            // Now check for orders with this business ID or store ID
            const businessId = business.businessId;
            const storeId = business.storeId;

            console.log('\n🛍️ Checking for orders...');

            // Check orders by business ID
            if (businessId) {
                const orderParams1 = {
                    TableName: 'order-receiver-orders-dev',
                    FilterExpression: 'businessId = :businessId',
                    ExpressionAttributeValues: {
                        ':businessId': businessId
                    }
                };

                const orderResult1 = await dynamodb.scan(orderParams1).promise();
                console.log(`📦 Orders found with businessId ${businessId}:`, orderResult1.Items?.length || 0);
                if (orderResult1.Items && orderResult1.Items.length > 0) {
                    orderResult1.Items.forEach((order, index) => {
                        console.log(`   Order ${index + 1}:`, {
                            orderId: order.orderId,
                            customerName: order.customerName,
                            total: order.total,
                            status: order.status,
                            createdAt: order.createdAt
                        });
                    });
                }
            }

            // Check orders by store ID
            if (storeId) {
                const orderParams2 = {
                    TableName: 'order-receiver-orders-dev',
                    FilterExpression: 'storeId = :storeId',
                    ExpressionAttributeValues: {
                        ':storeId': storeId
                    }
                };

                const orderResult2 = await dynamodb.scan(orderParams2).promise();
                console.log(`📦 Orders found with storeId ${storeId}:`, orderResult2.Items?.length || 0);
                if (orderResult2.Items && orderResult2.Items.length > 0) {
                    orderResult2.Items.forEach((order, index) => {
                        console.log(`   Order ${index + 1}:`, {
                            orderId: order.orderId,
                            customerName: order.customerName,
                            total: order.total,
                            status: order.status,
                            createdAt: order.createdAt
                        });
                    });
                }
            }

        } else {
            console.log('❌ No business found for g87_a@yahoo.com');

            // Let's also check all businesses to see what's available
            console.log('\n📋 All businesses in the table:');
            const allBusinessParams = {
                TableName: 'order-receiver-businesses-dev'
            };

            const allBusinessResult = await dynamodb.scan(allBusinessParams).promise();
            if (allBusinessResult.Items && allBusinessResult.Items.length > 0) {
                allBusinessResult.Items.forEach((business, index) => {
                    console.log(`   Business ${index + 1}:`, {
                        businessId: business.businessId,
                        businessName: business.businessName,
                        ownerEmail: business.ownerEmail,
                        storeId: business.storeId
                    });
                });
            }
        }

    } catch (error) {
        console.error('❌ Error checking logged-in business:', error);
    }
}

checkLoggedInBusiness();
