const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const BUSINESSES_TABLE = 'order-receiver-businesses-dev';
const BUSINESS_ID = 'ef8366d7-e311-4a48-bf73-dcf1069cebe6'; // From debug output

async function updateBusinessStatus() {
    console.log('🔄 Updating business status to use standardized values...');
    
    try {
        // First get the current business data
        const getParams = {
            TableName: BUSINESSES_TABLE,
            Key: { businessId: BUSINESS_ID }
        };
        
        const result = await dynamodb.get(getParams).promise();
        
        if (!result.Item) {
            console.log('❌ Business not found');
            return;
        }
        
        console.log('📋 Current business data:');
        console.log(`  - Business ID: ${result.Item.businessId}`);
        console.log(`  - Business Name: ${result.Item.businessName}`);
        console.log(`  - Current Status: ${result.Item.status}`);
        console.log(`  - Email: ${result.Item.email}`);
        
        // Update status from 'pending_verification' to 'pending'
        const updateParams = {
            TableName: BUSINESSES_TABLE,
            Key: { businessId: BUSINESS_ID },
            UpdateExpression: 'SET #status = :status, updatedAt = :updatedAt',
            ExpressionAttributeNames: {
                '#status': 'status'
            },
            ExpressionAttributeValues: {
                ':status': 'pending',
                ':updatedAt': new Date().toISOString()
            },
            ReturnValues: 'UPDATED_NEW'
        };
        
        const updateResult = await dynamodb.update(updateParams).promise();
        
        console.log('✅ Business status updated successfully!');
        console.log('📋 Updated attributes:', updateResult.Attributes);
        
    } catch (error) {
        console.error('❌ Error updating business status:', error.message);
    }
}

// Also create a function to check what status values exist in the database
async function scanBusinessStatuses() {
    console.log('\n🔍 Scanning all business statuses in the database...');
    
    try {
        const scanParams = {
            TableName: BUSINESSES_TABLE,
            ProjectionExpression: 'businessId, businessName, #status, email',
            ExpressionAttributeNames: {
                '#status': 'status'
            }
        };
        
        const result = await dynamodb.scan(scanParams).promise();
        
        console.log(`📊 Found ${result.Items.length} businesses:`);
        
        const statusCounts = {};
        result.Items.forEach((item, index) => {
            const status = item.status || 'undefined';
            statusCounts[status] = (statusCounts[status] || 0) + 1;
            
            console.log(`  ${index + 1}. ${item.businessName || 'Unnamed'}`);
            console.log(`     Status: ${status}`);
            console.log(`     Email: ${item.email}`);
            console.log(`     ID: ${item.businessId}`);
            console.log('');
        });
        
        console.log('📈 Status summary:');
        Object.entries(statusCounts).forEach(([status, count]) => {
            console.log(`  - ${status}: ${count} business(es)`);
        });
        
    } catch (error) {
        console.error('❌ Error scanning businesses:', error.message);
    }
}

async function main() {
    await scanBusinessStatuses();
    await updateBusinessStatus();
    console.log('\n✨ Status update complete!');
}

main();
