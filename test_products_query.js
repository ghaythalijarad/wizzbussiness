const AWS = require('aws-sdk');

// Configuration to match the Lambda environment
const region = 'us-east-1';
const PRODUCTS_TABLE = 'order-receiver-products-dev';
const BUSINESSES_TABLE = 'order-receiver-businesses-dev';

AWS.config.update({ region });
const dynamodb = new AWS.DynamoDB.DocumentClient({ region });

async function testProductsQuery() {
    try {
        console.log('🔍 Testing DynamoDB Products Query');
        console.log('=' .repeat(50));
        
        const businessId = '1c5eeac7-7cad-4c0c-b5c7-a538951f8caa';
        console.log('Business ID:', businessId);
        console.log('Products Table:', PRODUCTS_TABLE);
        
        // Test 1: Try the exact query from the Lambda function
        console.log('\n1. Testing BusinessIdIndex query (from Lambda)...');
        try {
            const params = {
                TableName: PRODUCTS_TABLE,
                IndexName: 'BusinessIdIndex',
                KeyConditionExpression: 'businessId = :businessId',
                ExpressionAttributeValues: {
                    ':businessId': businessId
                }
            };
            
            console.log('Query params:', JSON.stringify(params, null, 2));
            const result = await dynamodb.query(params).promise();
            console.log('✅ BusinessIdIndex query successful!');
            console.log(`📦 Found ${result.Items.length} products`);
            console.log('Products:', JSON.stringify(result.Items, null, 2));
        } catch (error) {
            console.log('❌ BusinessIdIndex query failed:', error.message);
            console.log('Error details:', error);
        }
        
        // Test 2: Try a scan instead (fallback)
        console.log('\n2. Testing scan with filter...');
        try {
            const scanParams = {
                TableName: PRODUCTS_TABLE,
                FilterExpression: 'businessId = :businessId',
                ExpressionAttributeValues: {
                    ':businessId': businessId
                }
            };
            
            const scanResult = await dynamodb.scan(scanParams).promise();
            console.log('✅ Scan query successful!');
            console.log(`📦 Found ${scanResult.Items.length} products via scan`);
            console.log('Products via scan:', JSON.stringify(scanResult.Items, null, 2));
        } catch (error) {
            console.log('❌ Scan query failed:', error.message);
        }
        
        // Test 3: Check table description to see indexes
        console.log('\n3. Checking table structure...');
        try {
            const describeParams = {
                TableName: PRODUCTS_TABLE
            };
            
            const tableDesc = await dynamodb.scan({
                TableName: PRODUCTS_TABLE,
                Select: 'COUNT'
            }).promise();
            
            console.log(`📊 Total items in products table: ${tableDesc.Count}`);
        } catch (error) {
            console.log('❌ Table check failed:', error.message);
        }
        
        // Test 4: Check if business exists
        console.log('\n4. Verifying business exists...');
        try {
            const businessParams = {
                TableName: BUSINESSES_TABLE,
                IndexName: 'email-index',
                KeyConditionExpression: 'email = :email',
                ExpressionAttributeValues: {
                    ':email': 'zikbiot@yahoo.com'
                }
            };
            
            const businessResult = await dynamodb.query(businessParams).promise();
            console.log('✅ Business query successful!');
            console.log(`📋 Found ${businessResult.Items.length} businesses`);
            if (businessResult.Items.length > 0) {
                const business = businessResult.Items[0];
                console.log('Business data:');
                console.log('  - business_id:', business.business_id);
                console.log('  - businessId:', business.businessId);
                console.log('  - email:', business.email);
                console.log('  - business_name:', business.business_name);
            }
        } catch (error) {
            console.log('❌ Business query failed:', error.message);
        }
        
    } catch (error) {
        console.error('💥 Unexpected error:', error);
    }
}

testProductsQuery();
