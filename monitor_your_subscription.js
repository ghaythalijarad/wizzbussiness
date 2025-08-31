#!/usr/bin/env node

/**
 * Monitor Your Specific Subscription Record
 * Watches for changes when you toggle merchant status
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({
    region: 'us-east-1',
    credentials: {
        profile: 'wizz-merchants-dev'
    }
}));

const SUBSCRIPTIONS_TABLE = 'WizzUser_websocket_subscriptions_dev';
const YOUR_BUSINESS_ID = 'business_1756336745961_ywix4oy9aa';
const TARGET_USER_ID = 'b4a83498-b041-70c0-39d8-672250957041';

// Store previous state
let previousState = null;

async function checkYourSubscription() {
    try {
        const params = {
            TableName: SUBSCRIPTIONS_TABLE,
            FilterExpression: 'businessId = :businessId AND userId = :userId',
            ExpressionAttributeValues: {
                ':businessId': YOUR_BUSINESS_ID,
                ':userId': TARGET_USER_ID
            }
        };

        const result = await dynamodb.send(new ScanCommand(params));
        const subscription = result.Items?.[0];

        const timestamp = new Date().toLocaleTimeString();
        
        if (subscription) {
            console.log(`⏰ ${timestamp}: SUBSCRIPTION FOUND`);
            console.log('   📋 Record Details:');
            console.log(`      🆔 ID: ${subscription.subscriptionId}`);
            console.log(`      🏢 Business: ${subscription.businessId}`);
            console.log(`      👤 User: ${subscription.userId}`);
            console.log(`      🔗 Connection: ${subscription.connectionId}`);
            console.log(`      📅 Created: ${subscription.createdAt}`);
            console.log(`      ✅ Active: ${subscription.isActive}`);
            console.log(`      📊 Type: ${subscription.subscriptionType || 'N/A'}`);
            console.log(`      🎯 Topic: ${subscription.topic}`);
            console.log(`      👥 UserType: ${subscription.userType}`);

            // Detect changes
            if (previousState) {
                const changes = [];
                
                if (previousState.isActive !== subscription.isActive) {
                    changes.push(`🔄 isActive: ${previousState.isActive} → ${subscription.isActive}`);
                }
                
                if (previousState.createdAt !== subscription.createdAt) {
                    changes.push(`🕒 createdAt: ${previousState.createdAt} → ${subscription.createdAt}`);
                }
                
                if (previousState.subscriptionType !== subscription.subscriptionType) {
                    changes.push(`📊 subscriptionType: ${previousState.subscriptionType} → ${subscription.subscriptionType}`);
                }
                
                if (changes.length > 0) {
                    console.log('');
                    console.log('🎉 CHANGES DETECTED:');
                    changes.forEach(change => console.log(`   ${change}`));
                    console.log('');
                }
            }

            previousState = { ...subscription };
        } else {
            console.log(`⏰ ${timestamp}: NO SUBSCRIPTION FOUND`);
            if (previousState) {
                console.log('🗑️  SUBSCRIPTION DELETED - Your merchant went offline!');
                previousState = null;
            }
        }

    } catch (error) {
        console.error('❌ Error checking subscription:', error.message);
    }
}

async function main() {
    console.log('🔍 Monitoring Your Merchant Status Subscription');
    console.log('==============================================');
    console.log(`🏢 Your Business: ${YOUR_BUSINESS_ID}`);
    console.log(`👤 Customer User: ${TARGET_USER_ID}`);
    console.log(`📊 Table: ${SUBSCRIPTIONS_TABLE}`);
    console.log('');
    console.log('🎯 Instructions:');
    console.log('   1. Keep this monitor running');
    console.log('   2. Open your Flutter app');
    console.log('   3. Toggle your merchant status ON/OFF');
    console.log('   4. Watch for real-time changes below!');
    console.log('');
    console.log('Press Ctrl+C to stop monitoring...');
    console.log('═'.repeat(50));
    console.log('');

    // Initial check
    await checkYourSubscription();

    // Monitor every 2 seconds
    setInterval(checkYourSubscription, 2000);
}

if (require.main === module) {
    main().catch(console.error);
}
