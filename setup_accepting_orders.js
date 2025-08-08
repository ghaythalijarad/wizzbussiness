const AWS = require('aws-sdk');

AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const BUSINESSES_TABLE = 'order-receiver-businesses-dev';

async function addAcceptingOrdersToAllBusinesses() {
    console.log('🔄 Adding acceptingOrders field to all businesses...');

    try {
        // First scan all businesses
        const scanParams = {
            TableName: BUSINESSES_TABLE,
            ProjectionExpression: 'businessId, businessName, acceptingOrders'
        };

        const result = await dynamodb.scan(scanParams).promise();
        console.log(`📊 Found ${result.Items.length} businesses`);

        let updateCount = 0;
        let skipCount = 0;

        for (const business of result.Items) {
            if (business.acceptingOrders === undefined) {
                // Add the acceptingOrders field
                try {
                    const updateParams = {
                        TableName: BUSINESSES_TABLE,
                        Key: { businessId: business.businessId },
                        UpdateExpression: 'SET acceptingOrders = :accepting, lastStatusUpdate = :timestamp',
                        ExpressionAttributeValues: {
                            ':accepting': true, // Default to accepting orders
                            ':timestamp': new Date().toISOString()
                        }
                    };

                    await dynamodb.update(updateParams).promise();
                    console.log(`✅ Updated ${business.businessName || business.businessId}`);
                    updateCount++;
                } catch (error) {
                    console.error(`❌ Failed to update ${business.businessId}:`, error.message);
                }
            } else {
                console.log(`⏭️  Skipped ${business.businessName || business.businessId} (already has acceptingOrders: ${business.acceptingOrders})`);
                skipCount++;
            }
        }

        console.log(`\n🎉 Process complete!`);
        console.log(`📊 Summary:`);
        console.log(`   - Updated: ${updateCount} businesses`);
        console.log(`   - Skipped: ${skipCount} businesses`);
        console.log(`   - Total: ${result.Items.length} businesses`);

        return { updateCount, skipCount, total: result.Items.length };

    } catch (error) {
        console.error('❌ Error:', error.message);
        throw error;
    }
}

// Self-executing function with proper cleanup
(async () => {
    try {
        await addAcceptingOrdersToAllBusinesses();
        process.exit(0);
    } catch (error) {
        console.error('Fatal error:', error);
        process.exit(1);
    }
})();
