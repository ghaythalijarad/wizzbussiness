#!/usr/bin/env node

/**
 * Real-Time WebSocket Subscription Monitor
 * Monitors subscription isActive changes in real-time
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: 'us-east-1' });
const docClient = DynamoDBDocumentClient.from(client);

const SUBSCRIPTIONS_TABLE = 'WizzUser_websocket_subscriptions_dev';

let lastState = new Map();

async function monitorSubscriptions() {
    console.log('🔍 WebSocket Subscription Monitor Started');
    console.log('📱 Toggle your merchant status in the Flutter app to see changes');
    console.log('⏹️  Press Ctrl+C to stop monitoring\n');

    // Initial scan
    await checkSubscriptions(true);

    // Monitor every 2 seconds
    setInterval(async () => {
        await checkSubscriptions(false);
    }, 2000);
}

async function checkSubscriptions(isInitial) {
    try {
        const result = await docClient.send(new ScanCommand({
            TableName: SUBSCRIPTIONS_TABLE,
            FilterExpression: 'subscriptionType = :type',
            ExpressionAttributeValues: {
                ':type': 'business_status'
            }
        }));

        for (const subscription of result.Items || []) {
            const id = subscription.subscriptionId;
            const currentActive = subscription.isActive;
            const businessId = subscription.businessId;
            const userType = subscription.userType;
            const updatedAt = subscription.updatedAt;

            const key = `${id}_${currentActive}`;
            
            if (isInitial) {
                console.log(`📊 Initial State - ${id}:`);
                console.log(`   BusinessId: ${businessId}`);
                console.log(`   UserType: ${userType}`);
                console.log(`   IsActive: ${currentActive}`);
                console.log(`   UpdatedAt: ${updatedAt || 'Not set'}`);
                console.log('');
                lastState.set(id, currentActive);
            } else {
                const previousActive = lastState.get(id);
                
                if (previousActive !== currentActive) {
                    const timestamp = new Date().toLocaleTimeString();
                    console.log(`🔄 [${timestamp}] STATUS CHANGE DETECTED!`);
                    console.log(`   Subscription: ${id}`);
                    console.log(`   BusinessId: ${businessId}`);
                    console.log(`   Changed: ${previousActive} → ${currentActive}`);
                    console.log(`   UpdatedAt: ${updatedAt || 'Not set'}`);
                    console.log('   ' + (currentActive ? '🟢 ACTIVE' : '🔴 INACTIVE'));
                    console.log('');
                    
                    lastState.set(id, currentActive);
                }
            }
        }
    } catch (error) {
        console.error('❌ Error monitoring subscriptions:', error.message);
    }
}

// Handle Ctrl+C gracefully
process.on('SIGINT', () => {
    console.log('\n📋 Monitoring stopped');
    console.log('👋 Goodbye!');
    process.exit(0);
});

// Start monitoring
monitorSubscriptions().catch(console.error);
