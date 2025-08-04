const AWS = require('aws-sdk');

// Configure DynamoDB
const dynamodb = new AWS.DynamoDB.DocumentClient({
    region: 'us-east-1'
});

const WORKING_HOURS_TABLE = 'order-receiver-business-working-hours-dev';

async function debugWorkingHours() {
    try {
        console.log('🔍 Scanning working hours table...');

        const scanParams = {
            TableName: WORKING_HOURS_TABLE
        };

        const result = await dynamodb.scan(scanParams).promise();

        console.log(`📊 Found ${result.Items.length} working hours records:`);
        console.log('================================');

        result.Items.forEach((item, index) => {
            console.log(`\n📋 Record ${index + 1}:`);
            console.log(`Business ID: ${item.businessId}`);
            console.log('Working Hours:');

            const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

            days.forEach(day => {
                if (item[day]) {
                    const dayData = item[day];
                    console.log(`  ${day.charAt(0).toUpperCase() + day.slice(1)}: ${dayData.opening || 'NULL'} - ${dayData.closing || 'NULL'} (Open: ${dayData.isOpen})`);
                } else {
                    console.log(`  ${day.charAt(0).toUpperCase() + day.slice(1)}: NOT SET`);
                }
            });

            console.log(`Created: ${item.createdAt}`);
            console.log(`Updated: ${item.updatedAt}`);
        });

        if (result.Items.length === 0) {
            console.log('❌ No working hours records found!');

            // Check if there are any business records
            console.log('\n🔍 Checking business table...');
            const businessScan = await dynamodb.scan({
                TableName: 'order-receiver-businesses-dev',
                Select: 'COUNT'
            }).promise();

            console.log(`📊 Found ${businessScan.Count} business records`);
        }

    } catch (error) {
        console.error('❌ Error debugging working hours:', error);
    }
}

debugWorkingHours();
