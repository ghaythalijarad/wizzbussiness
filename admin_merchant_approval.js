const AWS = require('aws-sdk');
const readline = require('readline');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const BUSINESSES_TABLE = 'order-receiver-businesses-dev';

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

async function question(prompt) {
    return new Promise((resolve) => {
        rl.question(prompt, (answer) => {
            resolve(answer);
        });
    });
}

async function listBusinesses() {
    console.log('\n📋 Merchant Applications:');
    console.log('=' .repeat(80));
    
    try {
        const scanParams = {
            TableName: BUSINESSES_TABLE,
            ProjectionExpression: 'businessId, businessName, #status, email, ownerName, businessType, createdAt',
            ExpressionAttributeNames: {
                '#status': 'status'
            }
        };
        
        const result = await dynamodb.scan(scanParams).promise();
        
        result.Items.forEach((item, index) => {
            const status = item.status || 'unknown';
            const statusEmoji = {
                'pending': '🟡',
                'approved': '✅',
                'rejected': '❌',
                'under_review': '🔍'
            }[status] || '❓';
            
            console.log(`${index + 1}. ${statusEmoji} ${item.businessName || 'Unnamed Business'}`);
            console.log(`   📧 Email: ${item.email}`);
            console.log(`   👤 Owner: ${item.ownerName || 'Not specified'}`);
            console.log(`   🏢 Type: ${item.businessType || 'Not specified'}`);
            console.log(`   📊 Status: ${status}`);
            console.log(`   🆔 ID: ${item.businessId}`);
            console.log(`   📅 Created: ${item.createdAt ? new Date(item.createdAt).toLocaleDateString() : 'Unknown'}`);
            console.log('');
        });
        
        return result.Items;
    } catch (error) {
        console.error('❌ Error listing businesses:', error.message);
        return [];
    }
}

async function updateBusinessStatus(businessId, newStatus) {
    try {
        const updateParams = {
            TableName: BUSINESSES_TABLE,
            Key: { businessId: businessId },
            UpdateExpression: 'SET #status = :status, updatedAt = :updatedAt',
            ExpressionAttributeNames: {
                '#status': 'status'
            },
            ExpressionAttributeValues: {
                ':status': newStatus,
                ':updatedAt': new Date().toISOString()
            },
            ReturnValues: 'UPDATED_NEW'
        };
        
        const result = await dynamodb.update(updateParams).promise();
        console.log(`✅ Status updated to '${newStatus}' successfully!`);
        return true;
    } catch (error) {
        console.error('❌ Error updating status:', error.message);
        return false;
    }
}

async function adminInterface() {
    console.log('🏢 MERCHANT APPROVAL ADMIN INTERFACE');
    console.log('====================================');
    
    while (true) {
        const businesses = await listBusinesses();
        
        if (businesses.length === 0) {
            console.log('❌ No businesses found.');
            break;
        }
        
        console.log('\n⚙️  ADMIN ACTIONS:');
        console.log('1. Approve a business');
        console.log('2. Reject a business'); 
        console.log('3. Set to under review');
        console.log('4. Set to pending');
        console.log('5. Refresh list');
        console.log('6. Exit');
        
        const action = await question('\n🔧 Choose an action (1-6): ');
        
        if (action === '6') {
            break;
        }
        
        if (action === '5') {
            continue;
        }
        
        if (['1', '2', '3', '4'].includes(action)) {
            const businessIndex = await question('\n📋 Enter business number to update: ');
            const index = parseInt(businessIndex) - 1;
            
            if (index >= 0 && index < businesses.length) {
                const business = businesses[index];
                let newStatus;
                
                switch (action) {
                    case '1':
                        newStatus = 'approved';
                        break;
                    case '2':
                        newStatus = 'rejected';
                        break;
                    case '3':
                        newStatus = 'under_review';
                        break;
                    case '4':
                        newStatus = 'pending';
                        break;
                }
                
                console.log(`\n🔄 Updating ${business.businessName} status to '${newStatus}'...`);
                const success = await updateBusinessStatus(business.businessId, newStatus);
                
                if (success) {
                    console.log(`\n🎉 ${business.businessName} is now ${newStatus}!`);
                    
                    if (newStatus === 'approved') {
                        console.log('📱 The merchant can now access their dashboard and start receiving orders.');
                    } else if (newStatus === 'rejected') {
                        console.log('📧 Consider sending an email explaining the rejection reason.');
                    }
                }
            } else {
                console.log('❌ Invalid business number.');
            }
        } else {
            console.log('❌ Invalid action.');
        }
        
        console.log('\n' + '='.repeat(80));
    }
    
    rl.close();
}

// Start the admin interface
adminInterface();
