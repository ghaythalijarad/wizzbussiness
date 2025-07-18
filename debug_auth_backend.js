const AWS = require('aws-sdk');

// Configuration
const cognitoConfig = {
    UserPoolId: 'us-east-1_bDqnKdrqo',
    ClientId: '6n752vrmqmbss6nmlg6be2nn9a',
    region: 'us-east-1'
};

// Use the access token we already have
const fs = require('fs');

async function debugAuthenticatedEndpoint() {
    console.log('🔍 Script started');
    try {
        console.log('🔍 Debugging Authenticated Endpoint Issue');
        console.log('=' .repeat(50));

        // Read the access token
        console.log('Reading access token file...');
        const accessToken = fs.readFileSync('access_token.txt', 'utf8').trim();
        console.log(`📝 Using access token: ${accessToken.substring(0, 50)}...`);

        // Test the token by getting user info
        console.log('\n1. Testing token with Cognito GetUser...');
        AWS.config.update({ region: cognitoConfig.region });
        const cognito = new AWS.CognitoIdentityServiceProvider();
        
        const userResponse = await cognito.getUser({ AccessToken: accessToken }).promise();
        const email = userResponse.UserAttributes.find(attr => attr.Name === 'email')?.Value;
        const userId = userResponse.UserAttributes.find(attr => attr.Name === 'sub')?.Value;
        
        console.log(`✅ Token is valid!`);
        console.log(`📧 Email: ${email}`);
        console.log(`👤 User ID: ${userId}`);

        // Test DynamoDB connection
        console.log('\n2. Testing DynamoDB connection...');
        const dynamodb = new AWS.DynamoDB.DocumentClient({ region: 'us-east-1' });
        
        // Check if the businesses table exists and if the user has a business
        console.log('   Checking businesses table...');
        const businessesTableName = 'order-receiver-businesses-dev';
        
        try {
            const params = {
                TableName: businessesTableName,
                IndexName: 'email-index',
                KeyConditionExpression: 'email = :email',
                ExpressionAttributeValues: {
                    ':email': email
                }
            };

            console.log(`   Query params:`, JSON.stringify(params, null, 4));
            const result = await dynamodb.query(params).promise();
            
            console.log(`✅ Businesses table query successful!`);
            console.log(`📊 Found ${result.Items?.length || 0} business records`);
            
            if (result.Items && result.Items.length > 0) {
                console.log(`📋 Business info:`, JSON.stringify(result.Items[0], null, 4));
            } else {
                console.log('❌ No business found for this user!');
                console.log('   This could be why the endpoints are failing.');
            }
        } catch (dbError) {
            console.log(`❌ DynamoDB query failed:`, dbError.message);
            console.log(`   Error code: ${dbError.code}`);
            console.log(`   This is likely the cause of the 500 error.`);
        }

        // Test products table access
        console.log('\n3. Testing products table...');
        const productsTableName = 'order-receiver-products-dev';
        
        try {
            const productsParams = {
                TableName: productsTableName,
                Limit: 1
            };
            
            const productsResult = await dynamodb.scan(productsParams).promise();
            console.log(`✅ Products table accessible!`);
            console.log(`📦 Found ${productsResult.Items?.length || 0} products (limited to 1)`);
        } catch (dbError) {
            console.log(`❌ Products table access failed:`, dbError.message);
        }

        // Test categories table access
        console.log('\n4. Testing categories table...');
        const categoriesTableName = 'order-receiver-categories-dev';
        
        try {
            const categoriesParams = {
                TableName: categoriesTableName,
                Limit: 1
            };
            
            const categoriesResult = await dynamodb.scan(categoriesParams).promise();
            console.log(`✅ Categories table accessible!`);
            console.log(`📋 Found ${categoriesResult.Items?.length || 0} categories (limited to 1)`);
        } catch (dbError) {
            console.log(`❌ Categories table access failed:`, dbError.message);
        }

    } catch (error) {
        console.error('💥 Debug failed:', error.message);
        console.error('Error code:', error.code);
    }
}

// Run the debug
debugAuthenticatedEndpoint();
