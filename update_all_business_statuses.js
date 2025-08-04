const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const BUSINESSES_TABLE = 'order-receiver-businesses-dev';

async function updateAllBusinessStatuses() {
    console.log('🔄 Updating all business statuses to standardized values...');
    
    try {
        // First scan all businesses
        const scanParams = {
            TableName: BUSINESSES_TABLE,
            ProjectionExpression: 'businessId, businessName, #status, email',
            ExpressionAttributeNames: {
                '#status': 'status'
            }
        };
        
        const result = await dynamodb.scan(scanParams).promise();
        
        console.log(`📊 Found ${result.Items.length} businesses to update:`);
        
        let updatedCount = 0;
        
        for (const business of result.Items) {
            const currentStatus = business.status;
            let newStatus;
            
            // Map old status values to new standardized ones
            switch (currentStatus) {
                case 'pending_verification':
                    newStatus = 'pending';
                    break;
                case 'approved':
                case 'rejected':
                case 'pending':
                case 'under_review':
                    newStatus = currentStatus; // Already standardized
                    break;
                default:
                    newStatus = 'pending'; // Default fallback
            }
            
            if (currentStatus !== newStatus) {
                console.log(`\n📝 Updating ${business.businessName || 'Unnamed Business'}:`);
                console.log(`   Email: ${business.email}`);
                console.log(`   Status: ${currentStatus} → ${newStatus}`);
                
                const updateParams = {
                    TableName: BUSINESSES_TABLE,
                    Key: { businessId: business.businessId },
                    UpdateExpression: 'SET #status = :status, updatedAt = :updatedAt',
                    ExpressionAttributeNames: {
                        '#status': 'status'
                    },
                    ExpressionAttributeValues: {
                        ':status': newStatus,
                        ':updatedAt': new Date().toISOString()
                    }
                };
                
                await dynamodb.update(updateParams).promise();
                updatedCount++;
                console.log(`   ✅ Updated successfully`);
            } else {
                console.log(`\n✅ ${business.businessName || 'Unnamed Business'} already has correct status: ${currentStatus}`);
            }
        }
        
        console.log(`\n🎉 Update complete! Updated ${updatedCount} businesses.`);
        
        // Now scan again to verify the changes
        console.log('\n📊 Final status verification:');
        const verifyResult = await dynamodb.scan(scanParams).promise();
        
        const statusCounts = {};
        verifyResult.Items.forEach((item) => {
            const status = item.status || 'undefined';
            statusCounts[status] = (statusCounts[status] || 0) + 1;
        });
        
        console.log('📈 Final status summary:');
        Object.entries(statusCounts).forEach(([status, count]) => {
            console.log(`  - ${status}: ${count} business(es)`);
        });
        
    } catch (error) {
        console.error('❌ Error updating business statuses:', error.message);
    }
}

updateAllBusinessStatuses();
