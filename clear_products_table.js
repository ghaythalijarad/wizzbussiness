const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const TABLE_NAME = 'order-receiver-products-dev';

async function clearProductsTable() {
    try {
        console.log('🗑️  Clearing products table...');
        console.log(`Table: ${TABLE_NAME}`);
        
        // Test AWS connection first
        console.log('🔑 Testing AWS credentials...');
        const sts = new AWS.STS();
        const identity = await sts.getCallerIdentity().promise();
        console.log('✅ AWS credentials are valid:', identity.Account);
        
        // First, scan to get all items
        const scanParams = {
            TableName: TABLE_NAME
        };
        
        const scanResult = await dynamodb.scan(scanParams).promise();
        console.log(`📦 Found ${scanResult.Items.length} products to delete`);
        
        // Delete each item
        for (const item of scanResult.Items) {
            console.log(`🗑️  Deleting product: ${item.name || item.productId}`);
            
            const deleteParams = {
                TableName: TABLE_NAME,
                Key: {
                    productId: item.productId
                }
            };
            
            await dynamodb.delete(deleteParams).promise();
            console.log(`✅ Deleted: ${item.name || item.productId}`);
        }
        
        console.log('🎉 All products cleared successfully!');
        
    } catch (error) {
        console.error('❌ Error clearing products table:', error);
        if (error.code) {
            console.error(`Error Code: ${error.code}`);
        }
    }
}

// Run the function
clearProductsTable();
