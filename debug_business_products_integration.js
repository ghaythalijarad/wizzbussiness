const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const BUSINESS_ID = '723a276a-ad62-482c-898c-076d1f8d5c0e';

async function debugBusinessAndProducts() {
    console.log('Starting debug...');
    try {
        console.log('🔍 Debugging Business and Products Integration');
        console.log('=' .repeat(60));
        
        // 1. Check business table structure
        console.log('\n1. Checking business table structure...');
        const businessParams = {
            TableName: 'order-receiver-businesses-dev',
            Key: {
                businessId: BUSINESS_ID
            }
        };
        
        const businessResult = await dynamodb.get(businessParams).promise();
        if (businessResult.Item) {
            console.log('✅ Business found:');
            console.log('   - businessId:', businessResult.Item.businessId);
            console.log('   - business_id:', businessResult.Item.business_id);
            console.log('   - email:', businessResult.Item.email);
            console.log('   - cognitoUserId:', businessResult.Item.cognitoUserId);
        } else {
            console.log('❌ Business not found with businessId:', BUSINESS_ID);
        }
        
        // 2. Check if business has business_id field
        console.log('\n2. Checking business_id field...');
        const businessIdToUse = businessResult.Item?.business_id || businessResult.Item?.businessId || BUSINESS_ID;
        console.log('   - business_id to use for products:', businessIdToUse);
        
        // 3. Check products table
        console.log('\n3. Checking products table...');
        const scanParams = {
            TableName: 'order-receiver-products-dev',
            Limit: 3
        };
        
        const scanResult = await dynamodb.scan(scanParams).promise();
        console.log(`📦 Found ${scanResult.Items.length} products (sample):`);
        
        scanResult.Items.forEach((product, index) => {
            console.log(`   Product ${index + 1}:`, {
                productId: product.productId,
                business_id: product.business_id,
                businessId: product.businessId,
                name: product.name
            });
        });
        
        // 4. Try to query products using business_id
        console.log('\n4. Testing products query...');
        try {
            const queryParams = {
                TableName: 'order-receiver-products-dev',
                FilterExpression: 'business_id = :businessId',
                ExpressionAttributeValues: {
                    ':businessId': businessIdToUse
                }
            };
            
            const queryResult = await dynamodb.scan(queryParams).promise();
            console.log(`✅ Products query successful: ${queryResult.Items.length} products found`);
            
            queryResult.Items.forEach((product, index) => {
                console.log(`   Product ${index + 1}: ${product.name} (business_id: ${product.business_id})`);
            });
            
        } catch (error) {
            console.log('❌ Products query failed:', error.message);
        }
        
    } catch (error) {
        console.error('💥 Debug failed:', error.message);
        console.error('Error details:', error);
    }
}

// Run the debug
debugBusinessAndProducts();
