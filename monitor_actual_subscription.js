#!/usr/bin/env node

/**
 * Monitor ACTUAL Subscription Toggle Issue
 * Tracks the real subscription record that exists in your system
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');

// Initialize DynamoDB
const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient({
    region: 'us-east-1'
}));

const BUSINESS_ID = 'business_1756336745961_ywix4oy9aa';
const USER_ID = 'b4a83498-b041-70c0-39d8-672250957041';

// Actual subscription ID from your system
const ACTUAL_SUBSCRIPTION_ID = 'QKixWcW8oAMCERQ=_business_status_1756633098108';

const BUSINESSES_TABLE = 'WhizzMerchants_Businesses'; // The correct business table 
const SUBSCRIPTIONS_TABLE = 'WizzUser_websocket_subscriptions_dev';

console.log('🔍 ACTUAL SUBSCRIPTION MONITOR');
console.log('==============================');
console.log(`🏢 Business ID: ${BUSINESS_ID}`);
console.log(`👤 User ID: ${USER_ID}`);
console.log(`🆔 Actual Subscription ID: ${ACTUAL_SUBSCRIPTION_ID}`);
console.log('');

let previousState = null;
let changeCount = 0;

async function checkBusinessStatus() {
    try {
        // Check in the correct business table
        const params = {
            TableName: BUSINESSES_TABLE,
            Key: { businessId: BUSINESS_ID }
        };
        
        const result = await dynamodb.send(new GetCommand(params));
        return result.Item;
    } catch (error) {
        console.error('❌ Error checking business status:', error.message);
        return null;
    }
}

async function checkActualSubscription() {
    try {
        const params = {
            TableName: SUBSCRIPTIONS_TABLE,
            Key: { subscriptionId: ACTUAL_SUBSCRIPTION_ID }
        };
        
        const result = await dynamodb.send(new GetCommand(params));
        return result.Item;
    } catch (error) {
        console.error('❌ Error checking subscription:', error.message);
        return null;
    }
}

async function findAllRelatedSubscriptions() {
    try {
        const params = {
            TableName: SUBSCRIPTIONS_TABLE,
            FilterExpression: 'businessId = :businessId OR (userId = :userId AND contains(topic, :businessId))',
            ExpressionAttributeValues: {
                ':businessId': BUSINESS_ID,
                ':userId': USER_ID
            },
            Limit: 20
        };
        
        const result = await dynamodb.send(new ScanCommand(params));
        return result.Items || [];
    } catch (error) {
        console.error('❌ Error scanning subscriptions:', error.message);
        return [];
    }
}

async function monitorChanges() {
    const timestamp = new Date().toLocaleTimeString();
    
    try {
        // Get current state
        const business = await checkBusinessStatus();
        const actualSubscription = await checkActualSubscription();
        
        const currentState = {
            businessAcceptingOrders: business?.acceptingOrders,
            businessLastUpdate: business?.lastUpdate || business?.lastStatusUpdate,
            subscriptionExists: !!actualSubscription,
            subscriptionIsActive: actualSubscription?.isActive,
            subscriptionCreatedAt: actualSubscription?.createdAt,
            subscriptionType: actualSubscription?.subscriptionType,
            subscriptionUserType: actualSubscription?.userType
        };
        
        console.log(`⏰ ${timestamp} - Check #${++changeCount}`);
        console.log('─'.repeat(60));
        
        // Business status
        if (business) {
            console.log('🏢 BUSINESS STATUS (WhizzMerchants_Businesses):');
            console.log(`   accepting orders: ${business.acceptingOrders ? '✅ YES' : '❌ NO'}`);
            console.log(`   last update: ${business.lastUpdate || business.lastStatusUpdate || 'Never'}`);
            console.log(`   name: ${business.name || business.businessName || 'N/A'}`);
        } else {
            console.log('🏢 BUSINESS STATUS: ❌ NOT FOUND in WhizzMerchants_Businesses');
        }
        
        // Actual subscription status
        if (actualSubscription) {
            console.log('📡 ACTUAL SUBSCRIPTION STATUS:');
            console.log(`   ID: ${ACTUAL_SUBSCRIPTION_ID}`);
            console.log(`   isActive: ${actualSubscription.isActive ? '✅ TRUE' : '❌ FALSE'}`);
            console.log(`   subscription type: ${actualSubscription.subscriptionType || 'N/A'}`);
            console.log(`   user type: ${actualSubscription.userType || 'N/A'}`);
            console.log(`   topic: ${actualSubscription.topic || 'N/A'}`);
            console.log(`   connection ID: ${actualSubscription.connectionId || 'N/A'}`);
            console.log(`   created at: ${actualSubscription.createdAt || 'Never'}`);
        } else {
            console.log('📡 ACTUAL SUBSCRIPTION: ❌ NOT FOUND');
        }
        
        // Detect changes
        if (previousState) {
            const changes = [];
            
            if (previousState.businessAcceptingOrders !== currentState.businessAcceptingOrders) {
                changes.push(`🏢 Business accepting orders: ${previousState.businessAcceptingOrders} → ${currentState.businessAcceptingOrders}`);
            }
            
            if (previousState.businessLastUpdate !== currentState.businessLastUpdate) {
                changes.push(`🏢 Business timestamp updated`);
            }
            
            if (previousState.subscriptionIsActive !== currentState.subscriptionIsActive) {
                changes.push(`📡 Subscription isActive: ${previousState.subscriptionIsActive} → ${currentState.subscriptionIsActive}`);
            }
            
            if (previousState.subscriptionCreatedAt !== currentState.subscriptionCreatedAt) {
                changes.push(`📡 Subscription recreated/updated`);
            }
            
            if (changes.length > 0) {
                console.log('');
                console.log('🎉 CHANGES DETECTED:');
                changes.forEach(change => console.log(`   ${change}`));
                
                // Check for the specific bug
                if (currentState.businessAcceptingOrders === false && currentState.subscriptionIsActive === true) {
                    console.log('');
                    console.log('🚨 BUG DETECTED: Business is offline but subscription isActive is still TRUE!');
                    console.log('   This is the exact issue you reported.');
                    
                    // Show what should happen
                    console.log('');
                    console.log('💡 EXPECTED BEHAVIOR:');
                    console.log('   When business goes offline → subscription isActive should = FALSE');
                    console.log('   But it\'s still TRUE, which means customers might think you\'re available!');
                }
            }
        }
        
        previousState = currentState;
        console.log('');
        
    } catch (error) {
        console.error(`❌ Error during monitoring: ${error.message}`);
    }
}

async function main() {
    console.log('🎯 INSTRUCTIONS:');
    console.log('1. Keep this script running');
    console.log('2. Open your Flutter app');
    console.log('3. Toggle merchant status ON/OFF');
    console.log('4. Watch for the bug where subscription isActive stays TRUE when you go offline');
    console.log('');
    console.log('📋 SYSTEM ANALYSIS:');
    console.log('   • Your app uses business_status subscriptions (not merchant subscriptions)');
    console.log('   • Customer apps subscribe to your availability changes');
    console.log('   • When you toggle OFF, isActive should become FALSE');
    console.log('');
    
    // Show all related subscriptions first
    console.log('🔍 Finding all related subscriptions...');
    const allSubscriptions = await findAllRelatedSubscriptions();
    if (allSubscriptions.length > 0) {
        console.log(`📋 Found ${allSubscriptions.length} related subscription(s):`);
        allSubscriptions.forEach((sub, index) => {
            console.log(`   ${index + 1}. ${sub.subscriptionId} (active: ${sub.isActive})`);
        });
    } else {
        console.log('📭 No related subscriptions found');
    }
    
    console.log('');
    console.log('Press Ctrl+C to stop...');
    console.log('═'.repeat(60));
    console.log('');
    
    // Initial check
    await monitorChanges();
    
    // Monitor every 2 seconds
    setInterval(monitorChanges, 2000);
}

if (require.main === module) {
    main().catch(console.error);
}
