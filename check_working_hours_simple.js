const AWS = require('aws-sdk');

const dynamodb = new AWS.DynamoDB.DocumentClient({
    region: 'us-east-1'
});

const WORKING_HOURS_TABLE = 'order-receiver-business-working-hours-dev';

async function checkWorkingHoursTable() {
    try {
        console.log('🔍 Checking working hours table structure and data...');
        
        // First, scan the entire table to see what's there
        const scanResult = await dynamodb.scan({
            TableName: WORKING_HOURS_TABLE
        }).promise();
        
        console.log(`📊 Total records in table: ${scanResult.Items.length}`);
        
        if (scanResult.Items.length === 0) {
            console.log('❌ No working hours records found in the table');
            return;
        }
        
        console.log('\n📋 Sample records:');
        scanResult.Items.forEach((item, index) => {
            console.log(`\nRecord ${index + 1}:`);
            console.log(JSON.stringify(item, null, 2));
        });
        
        // Check if there are records with different key structures
        const businessIds = [...new Set(scanResult.Items.map(item => item.business_id || item.businessId))];
        console.log(`\n🏢 Unique business IDs: ${businessIds.join(', ')}`);
        
        // Group by business ID and weekday
        const byBusiness = {};
        scanResult.Items.forEach(item => {
            const bizId = item.business_id || item.businessId;
            const weekday = item.weekday;
            
            if (!byBusiness[bizId]) {
                byBusiness[bizId] = {};
            }
            
            byBusiness[bizId][weekday] = {
                opening: item.opening,
                closing: item.closing,
                updated_at: item.updated_at
            };
        });
        
        console.log('\n📅 Working hours by business:');
        Object.keys(byBusiness).forEach(bizId => {
            console.log(`\nBusiness ${bizId}:`);
            Object.keys(byBusiness[bizId]).forEach(day => {
                const hours = byBusiness[bizId][day];
                console.log(`  ${day}: ${hours.opening || 'NULL'} - ${hours.closing || 'NULL'} (${hours.updated_at})`);
            });
        });
        
    } catch (error) {
        console.error('❌ Error checking working hours table:', error);
    }
}

checkWorkingHoursTable();
