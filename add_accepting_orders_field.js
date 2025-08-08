const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const BUSINESSES_TABLE = 'order-receiver-businesses-dev';
const TEST_BUSINESS_ID = 'ef8366d7-e311-4a48-bf73-dcf1069cebe6'; // Known business ID

async function addAcceptingOrdersField() {
    try {
        console.log('🔄 Adding acceptingOrders field to business...');
        console.log(`Business ID: ${TEST_BUSINESS_ID}`);

        // First, get the current business data to verify it exists
        const getParams = {
            TableName: BUSINESSES_TABLE,
            Key: { businessId: TEST_BUSINESS_ID }
        };

        const getResult = await dynamodb.get(getParams).promise();
        if (!getResult.Item) {
            console.log('❌ Business not found!');
            return;
        }

        console.log('✅ Business found:', getResult.Item.businessName);
        console.log('Current acceptingOrders value:', getResult.Item.acceptingOrders);

        // Update the business to add the acceptingOrders field
        const updateParams = {
            TableName: BUSINESSES_TABLE,
            Key: { businessId: TEST_BUSINESS_ID },
            UpdateExpression: 'SET acceptingOrders = :accepting, lastStatusUpdate = :timestamp',
            ExpressionAttributeValues: {
                ':accepting': true, // Default to accepting orders
                ':timestamp': new Date().toISOString()
            },
            ReturnValues: 'ALL_NEW'
        };

        const updateResult = await dynamodb.update(updateParams).promise();

        console.log('✅ Successfully added acceptingOrders field!');
        console.log('Updated business:', {
            businessName: updateResult.Attributes.businessName,
            acceptingOrders: updateResult.Attributes.acceptingOrders,
            lastStatusUpdate: updateResult.Attributes.lastStatusUpdate
        });

    } catch (error) {
        console.error('❌ Error adding acceptingOrders field:', error.message);
    }
}

// Run the function
addAcceptingOrdersField().then(() => {
    console.log('✨ Process complete!');
    process.exit(0);
}).catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
});
