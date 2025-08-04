const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const BUSINESSES_TABLE = 'order-receiver-businesses-dev';

async function quickStatusUpdate() {
    console.log('Starting status update...');
    
    try {
        // Update specific business IDs we know about
        const businessIds = [
            '723a276a-ad62-482c-898c-076d1f8d5c0e',
            '60a9a6ea-d3e4-4715-9656-e5a08b055638', 
            'c1ac0bf1-40ec-4f78-8156-4a055b22f092',
            '70639a4d-f2bb-4cff-a2d7-555847814d9d'
        ];
        
        console.log(`Updating ${businessIds.length} businesses...`);
        
        for (const businessId of businessIds) {
            console.log(`Updating ${businessId}...`);
            
            const updateParams = {
                TableName: BUSINESSES_TABLE,
                Key: { businessId: businessId },
                UpdateExpression: 'SET #status = :status, updatedAt = :updatedAt',
                ExpressionAttributeNames: {
                    '#status': 'status'
                },
                ExpressionAttributeValues: {
                    ':status': 'pending',
                    ':updatedAt': new Date().toISOString()
                }
            };
            
            await dynamodb.update(updateParams).promise();
            console.log(`✅ Updated ${businessId}`);
        }
        
        console.log('✨ All businesses updated!');
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

quickStatusUpdate();
