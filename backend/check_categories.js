const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({
    region: 'us-east-1'
});

const dynamodb = new AWS.DynamoDB.DocumentClient();
const CATEGORIES_TABLE = 'order-receiver-categories-dev';

async function checkCategories() {
    try {
        console.log('🔍 Checking categories in DynamoDB...');
        
        // Query categories for 'store' business type
        const params = {
            TableName: CATEGORIES_TABLE,
            IndexName: 'business-type-index',
            KeyConditionExpression: 'businessType = :businessType',
            ExpressionAttributeValues: {
                ':businessType': 'store'
            }
        };

        const result = await dynamodb.query(params).promise();
        
        console.log(`📊 Found ${result.Items.length} categories for business type 'store':`);
        
        result.Items.forEach((category, index) => {
            console.log(`${index + 1}. ${category.name} (${category.name_ar})`);
            console.log(`   ID: ${category.categoryId}`);
            console.log(`   Description: ${category.description}`);
            console.log(`   Active: ${category.isActive}`);
            console.log(`   Created: ${category.created_at}`);
            console.log('');
        });
        
    } catch (error) {
        console.error('❌ Error checking categories:', error);
    }
}

// Run the check
checkCategories();
