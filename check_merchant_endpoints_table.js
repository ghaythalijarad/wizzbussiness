const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const MERCHANT_ENDPOINTS_TABLE = 'order-receiver-merchant-endpoints-dev';

async function checkMerchantEndpointsTable() {
    try {
        console.log('🔍 Checking merchant endpoints table structure...');
        
        // Scan the table to see current structure
        const scanParams = {
            TableName: MERCHANT_ENDPOINTS_TABLE,
            Limit: 5  // Just get a few items to see structure
        };
        
        const result = await dynamodb.scan(scanParams).promise();
        console.log('\n📊 Current items in merchant endpoints table:');
        console.log('Item count:', result.Items.length);
        
        if (result.Items.length > 0) {
            console.log('\nSample items:');
            result.Items.forEach((item, index) => {
                console.log(`Item ${index + 1}:`, JSON.stringify(item, null, 2));
            });
        } else {
            console.log('No items found in table');
        }
        
        // Try to describe the table to see indexes
        const dynamodbClient = new AWS.DynamoDB();
        const tableDescription = await dynamodbClient.describeTable({
            TableName: MERCHANT_ENDPOINTS_TABLE
        }).promise();
        
        console.log('\n🏗️ Table structure:');
        console.log('Key Schema:', JSON.stringify(tableDescription.Table.KeySchema, null, 2));
        
        if (tableDescription.Table.GlobalSecondaryIndexes) {
            console.log('Global Secondary Indexes:');
            tableDescription.Table.GlobalSecondaryIndexes.forEach(index => {
                console.log(`- ${index.IndexName}:`, JSON.stringify(index.KeySchema, null, 2));
            });
        } else {
            console.log('No Global Secondary Indexes found');
        }
        
    } catch (error) {
        console.error('❌ Error checking merchant endpoints table:', error);
        if (error.code === 'ResourceNotFoundException') {
            console.log('💡 The merchant endpoints table does not exist. Need to create it.');
        }
    }
}

checkMerchantEndpointsTable();
