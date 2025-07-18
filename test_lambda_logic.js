const AWS = require('aws-sdk');
const fs = require('fs');

async function testExactLambdaLogic() {
    try {
        console.log('🧪 Testing Exact Lambda Logic');
        console.log('=' .repeat(50));

        // Read the access token
        const accessToken = fs.readFileSync('access_token.txt', 'utf8').trim();
        
        // Initialize AWS services
        AWS.config.update({ region: 'us-east-1' });
        const cognito = new AWS.CognitoIdentityServiceProvider();
        const dynamodb = new AWS.DynamoDB.DocumentClient({ region: 'us-east-1' });

        // Step 1: Get user info (same as Lambda)
        console.log('1. Getting user info...');
        const userResponse = await cognito.getUser({ AccessToken: accessToken }).promise();
        const email = userResponse.UserAttributes.find(attr => attr.Name === 'email')?.Value;
        const userId = userResponse.UserAttributes.find(attr => attr.Name === 'sub')?.Value;
        
        const userInfo = {
            userId,
            email,
            cognitoUserId: userId
        };
        
        console.log('✅ User info:', userInfo);

        // Step 2: Get business info (same as Lambda)
        console.log('\n2. Getting business info...');
        const businessParams = {
            TableName: 'order-receiver-businesses-dev',
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: {
                ':email': email
            }
        };

        const businessResult = await dynamodb.query(businessParams).promise();
        const businessInfo = businessResult.Items?.[0] || null;
        
        if (!businessInfo) {
            console.log('❌ No business found!');
            return;
        }
        
        console.log('✅ Business found:', {
            business_id: businessInfo.business_id,
            businessId: businessInfo.businessId,
            business_name: businessInfo.business_name
        });

        // Step 3: Try to get products (same as Lambda)
        console.log('\n3. Getting products...');
        
        console.log('   Using business_id:', businessInfo.business_id);
        const productsParams1 = {
            TableName: 'order-receiver-products-dev',
            IndexName: 'BusinessIdIndex',
            KeyConditionExpression: 'businessId = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessInfo.business_id
            }
        };

        try {
            console.log('   Query params (business_id):', JSON.stringify(productsParams1, null, 4));
            const productsResult1 = await dynamodb.query(productsParams1).promise();
            console.log(`   ✅ Query with business_id successful: ${productsResult1.Items.length} products`);
        } catch (error) {
            console.log(`   ❌ Query with business_id failed:`, error.message);
        }

        // Try with businessId field
        console.log('\n   Using businessId:', businessInfo.businessId);
        const productsParams2 = {
            TableName: 'order-receiver-products-dev',
            IndexName: 'BusinessIdIndex',
            KeyConditionExpression: 'businessId = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessInfo.businessId
            }
        };

        try {
            console.log('   Query params (businessId):', JSON.stringify(productsParams2, null, 4));
            const productsResult2 = await dynamodb.query(productsParams2).promise();
            console.log(`   ✅ Query with businessId successful: ${productsResult2.Items.length} products`);
        } catch (error) {
            console.log(`   ❌ Query with businessId failed:`, error.message);
        }

        // Check the products table structure
        console.log('\n4. Checking products table structure...');
        const scanParams = {
            TableName: 'order-receiver-products-dev',
            Limit: 3
        };
        
        const scanResult = await dynamodb.scan(scanParams).promise();
        console.log(`📦 Found ${scanResult.Items.length} products (sample):`);
        
        scanResult.Items.forEach((product, index) => {
            console.log(`   Product ${index + 1}:`, {
                productId: product.productId,
                businessId: product.businessId,
                name: product.name
            });
        });

        console.log('\n🎯 Analysis complete!');

    } catch (error) {
        console.error('💥 Test failed:', error.message);
        console.error('Stack trace:', error.stack);
    }
}

testExactLambdaLogic();
