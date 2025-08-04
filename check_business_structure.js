const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand } = require('@aws-sdk/lib-dynamodb');

// Configure AWS SDK v3
const dynamoDbClient = new DynamoDBClient({ region: 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

async function checkBusinessStructure() {
    console.log('🔍 Checking business table structure...\n');

    const businessId = '892161df-6cb0-4a2a-ac04-5a09e206c81e'; // أسواق شمسة

    try {
        const params = {
            TableName: 'order-receiver-businesses-dev',
            Key: { businessId: businessId }
        };

        const result = await dynamodb.send(new GetCommand(params));
        
        if (result.Item) {
            console.log('✅ Business found:');
            console.log(JSON.stringify(result.Item, null, 2));
        } else {
            console.log(`❌ Business ${businessId} not found`);
        }

    } catch (error) {
        console.error('❌ Error:', error);
    }
}

checkBusinessStructure();
