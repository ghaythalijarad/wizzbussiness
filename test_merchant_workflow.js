const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const BUSINESSES_TABLE = 'order-receiver-businesses-dev';

async function testMerchantApprovalWorkflow() {
    console.log('🧪 TESTING MERCHANT APPROVAL WORKFLOW');
    console.log('=====================================');
    
    try {
        // Test business ID (from our debug earlier)
        const testBusinessId = 'ef8366d7-e311-4a48-bf73-dcf1069cebe6';
        const testEmail = 'g87_a@yahoo.com';
        
        console.log(`\n1️⃣ STEP 1: Get current business status`);
        const getParams = {
            TableName: BUSINESSES_TABLE,
            Key: { businessId: testBusinessId }
        };
        
        const currentBusiness = await dynamodb.get(getParams).promise();
        if (!currentBusiness.Item) {
            console.log('❌ Test business not found');
            return;
        }
        
        console.log(`📋 Business: ${currentBusiness.Item.businessName}`);
        console.log(`📧 Email: ${currentBusiness.Item.email}`);
        console.log(`📊 Current Status: ${currentBusiness.Item.status}`);
        
        console.log(`\n2️⃣ STEP 2: Test different status scenarios`);
        
        // Test Scenario 1: Set to pending
        console.log(`\n📝 Setting status to 'pending'...`);
        await updateStatus(testBusinessId, 'pending');
        
        // Test Scenario 2: Set to under_review 
        console.log(`\n📝 Setting status to 'under_review'...`);
        await updateStatus(testBusinessId, 'under_review');
        
        // Test Scenario 3: Set to approved
        console.log(`\n📝 Setting status to 'approved'...`);
        await updateStatus(testBusinessId, 'approved');
        
        // Test Scenario 4: Set to rejected
        console.log(`\n📝 Setting status to 'rejected'...`);
        await updateStatus(testBusinessId, 'rejected');
        
        // Reset to pending for testing
        console.log(`\n📝 Resetting to 'pending' for app testing...`);
        await updateStatus(testBusinessId, 'pending');
        
        console.log(`\n3️⃣ STEP 3: Verify final status`);
        const finalBusiness = await dynamodb.get(getParams).promise();
        console.log(`✅ Final Status: ${finalBusiness.Item.status}`);
        
        console.log(`\n🎯 NEXT STEPS FOR TESTING:`);
        console.log(`1. Login to the app with: ${testEmail}`);
        console.log(`2. You should see the 'Application Pending' screen`);
        console.log(`3. Use the admin interface to approve the business`);
        console.log(`4. Login again to access the dashboard`);
        
        console.log(`\n📱 TO TEST APPROVAL WORKFLOW:`);
        console.log(`   Run: node admin_merchant_approval.js`);
        console.log(`   Or manually approve with: node -e "
const AWS = require('aws-sdk');
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();
dynamodb.update({
  TableName: '${BUSINESSES_TABLE}',
  Key: { businessId: '${testBusinessId}' },
  UpdateExpression: 'SET #status = :status',
  ExpressionAttributeNames: { '#status': 'status' },
  ExpressionAttributeValues: { ':status': 'approved' }
}).promise().then(() => console.log('✅ Business approved!')).catch(console.error);
"`);
        
    } catch (error) {
        console.error('❌ Error in workflow test:', error.message);
    }
}

async function updateStatus(businessId, status) {
    const updateParams = {
        TableName: BUSINESSES_TABLE,
        Key: { businessId: businessId },
        UpdateExpression: 'SET #status = :status, updatedAt = :updatedAt',
        ExpressionAttributeNames: {
            '#status': 'status'
        },
        ExpressionAttributeValues: {
            ':status': status,
            ':updatedAt': new Date().toISOString()
        }
    };
    
    await dynamodb.update(updateParams).promise();
    console.log(`   ✅ Status updated to '${status}'`);
}

testMerchantApprovalWorkflow();
