#!/usr/bin/env node

/**
 * Monitor the ACTUAL subscription record that exists
 * Track why isActive doesn't change when toggling merchant status
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand } = require('@aws-sdk/lib-dynamodb');

// Use default AWS credentials (will pick up from AWS_PROFILE environment variable)
const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({
    region: 'us-east-1'
}));

// The ACTUAL subscription record that exists
const ACTUAL_SUBSCRIPTION_ID = 'QKixWcW8oAMCERQ=_business_status_1756633098108';
const BUSINESS_ID = 'business_1756336745961_ywix4oy9aa';

console.log('🔍 MONITORING ACTUAL SUBSCRIPTION RECORD');
console.log('==========================================');
console.log(`📋 Subscription ID: ${ACTUAL_SUBSCRIPTION_ID}`);
console.log(`🏢 Business ID: ${BUSINESS_ID}`);
console.log('');

let previousState = null;
let checkCount = 0;

async function checkSubscription() {
    try {
        const params = {
            TableName: 'WizzUser_websocket_subscriptions_dev',
            Key: {
                subscriptionId: ACTUAL_SUBSCRIPTION_ID
            }
        };
        
        const result = await dynamodb.send(new GetCommand(params));
        return result.Item;
    } catch (error) {
        console.error('❌ Error checking subscription:', error.message);
        return null;
    }
}

async function checkBusinessStatus() {
    try {
        const params = {
            TableName: 'WhizzMerchants_Businesses',
            Key: {
                businessId: BUSINESS_ID
            }
        };
        
        const result = await dynamodb.send(new GetCommand(params));
        return result.Item;
    } catch (error) {
        console.error('❌ Error checking business:', error.message);
        return null;
    }
}

async function monitor() {
    const timestamp = new Date().toLocaleTimeString();
    checkCount++;
    
    console.log(`⏰ ${timestamp} - Check #${checkCount}`);
    console.log('─'.repeat(60));
    
    // Check subscription
    const subscription = await checkSubscription();
    const business = await checkBusinessStatus();
    
    if (subscription) {
        console.log('📡 SUBSCRIPTION STATUS:');
        console.log(`   isActive: ${subscription.isActive ? '✅ TRUE' : '❌ FALSE'}`);
        console.log(`   subscriptionType: ${subscription.subscriptionType}`);
        console.log(`   userType: ${subscription.userType}`);
        console.log(`   topic: ${subscription.topic}`);
        console.log(`   connectionId: ${subscription.connectionId}`);
        console.log(`   createdAt: ${subscription.createdAt}`);
    } else {
        console.log('📡 SUBSCRIPTION: ❌ NOT FOUND');
    }
    
    if (business) {
        console.log('🏢 BUSINESS STATUS:');
        console.log(`   isActive: ${business.isActive ? '✅ TRUE' : '❌ FALSE'}`);
        console.log(`   acceptingOrders: ${business.acceptingOrders ? '✅ TRUE' : '❌ FALSE'}`);
    } else {
        console.log('🏢 BUSINESS: ❌ NOT FOUND');
    }
    
    // Detect changes
    if (previousState && subscription) {
        const changes = [];
        
        if (previousState.isActive !== subscription.isActive) {
            changes.push(`📡 Subscription isActive: ${previousState.isActive} → ${subscription.isActive}`);
        }
        
        if (business && previousState.businessAcceptingOrders !== business.acceptingOrders) {
            changes.push(`🏢 Business acceptingOrders: ${previousState.businessAcceptingOrders} → ${business.acceptingOrders}`);
        }
        
        if (changes.length > 0) {
            console.log('');
            console.log('🎉 CHANGES DETECTED:');
            changes.forEach(change => console.log(`   ${change}`));
            
            // Check for the bug
            if (business && business.acceptingOrders === false && subscription.isActive === true) {
                console.log('');
                console.log('🚨 BUG CONFIRMED: Business is offline but subscription isActive is still TRUE!');
                console.log('   This confirms the issue you reported.');
            }
        }
    }
    
    // Store current state
    previousState = {
        isActive: subscription?.isActive,
        businessAcceptingOrders: business?.acceptingOrders
    };
    
    console.log('');
}

async function main() {
    console.log('🎯 INSTRUCTIONS:');
    console.log('1. Keep this script running');
    console.log('2. Open your Flutter app and toggle merchant status ON/OFF');
    console.log('3. Watch to see if the subscription isActive field changes');
    console.log('4. We need to find out why it stays TRUE when you go offline');
    console.log('');
    console.log('Press Ctrl+C to stop monitoring...');
    console.log('═'.repeat(60));
    console.log('');
    
    // Initial check
    await monitor();
    
    // Monitor every 3 seconds
    setInterval(monitor, 3000);
}

if (require.main === module) {
    main().catch(console.error);
}
