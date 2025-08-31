#!/usr/bin/env node

/**
 * Quick Subscription Status Check
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: 'us-east-1' });
const docClient = DynamoDBDocumentClient.from(client);

async function quickCheck() {
    try {
        console.log('🔍 Quick Subscription Check...\n');
        
        const result = await docClient.send(new ScanCommand({
            TableName: 'WizzUser_websocket_subscriptions_dev',
            FilterExpression: 'subscriptionType = :type',
            ExpressionAttributeValues: {
                ':type': 'business_status'
            }
        }));
        
        if (!result.Items || result.Items.length === 0) {
            console.log('❌ No business_status subscriptions found');
            return;
        }
        
        console.log(`📊 Found ${result.Items.length} business_status subscription(s):`);
        
        for (const sub of result.Items) {
            console.log('\n' + '='.repeat(60));
            console.log(`📋 ID: ${sub.subscriptionId}`);
            console.log(`🏢 Business: ${sub.businessId}`);
            console.log(`👤 User: ${sub.userId}`);
            console.log(`📊 IsActive: ${sub.isActive} ${sub.isActive ? '🟢 ACTIVE' : '🔴 INACTIVE'}`);
            console.log(`📱 UserType: ${sub.userType}`);
            console.log(`🕐 Created: ${new Date(sub.createdAt).toLocaleString()}`);
            console.log(`🔄 Updated: ${sub.updatedAt || 'Never'}`);
        }
        
        const activeCount = result.Items.filter(s => s.isActive).length;
        const inactiveCount = result.Items.filter(s => !s.isActive).length;
        
        console.log('\n' + '='.repeat(60));
        console.log('📈 SUMMARY:');
        console.log(`🟢 Active: ${activeCount}`);
        console.log(`🔴 Inactive: ${inactiveCount}`);
        
        if (inactiveCount > 0) {
            console.log('\n✅ SUCCESS: Some subscriptions are inactive (toggle worked!)');
        } else if (activeCount > 0) {
            console.log('\n⚠️  All subscriptions still active (toggle may not have worked)');
        }
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

quickCheck();
