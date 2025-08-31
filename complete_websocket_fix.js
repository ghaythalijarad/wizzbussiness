#!/usr/bin/env node

/**
 * Complete WebSocket Schema Fix and Toggle Test - AWS SDK v3
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, UpdateCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: 'us-east-1' });
const docClient = DynamoDBDocumentClient.from(client);

const SUBSCRIPTIONS_TABLE = 'WizzUser_websocket_subscriptions_dev';
const CONNECTIONS_TABLE = 'WizzUser_websocket_connections_dev';
const BUSINESSES_TABLE = 'order-receiver-businesses-dev';

// Add timeout
setTimeout(() => {
    console.log('⏰ Script timeout after 30 seconds');
    process.exit(1);
}, 30000);

async function main() {
    console.log('🔧 Starting Complete WebSocket Fix...\n');

    try {
        // Step 1: Fix entity types
        await fixEntityTypes();
        
        // Step 2: Test subscription toggle
        await testToggle();
        
        console.log('\n✅ All fixes completed successfully!');
        process.exit(0);
        
    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
}

async function fixEntityTypes() {
    console.log('📝 Step 1: Fixing Entity Types...');
    
    // Fix subscription userType from "customer" to "merchant"
    const subscriptionsParams = {
        TableName: SUBSCRIPTIONS_TABLE,
        FilterExpression: 'subscriptionType = :type AND userType = :wrongType',
        ExpressionAttributeValues: {
            ':type': 'business_status',
            ':wrongType': 'customer'
        }
    };
    
    const subscriptionsResult = await docClient.send(new ScanCommand(subscriptionsParams));
    console.log(`  📊 Found ${subscriptionsResult.Items?.length || 0} subscriptions to fix`);
    
    for (const subscription of subscriptionsResult.Items || []) {
        console.log(`  🔧 Fixing subscription: ${subscription.subscriptionId}`);
        
        const updateParams = {
            TableName: SUBSCRIPTIONS_TABLE,
            Key: {
                subscriptionId: subscription.subscriptionId
            },
            UpdateExpression: 'SET userType = :correctType',
            ExpressionAttributeValues: {
                ':correctType': 'merchant'
            }
        };
        
        await docClient.send(new UpdateCommand(updateParams));
        console.log(`  ✅ Fixed userType: customer → merchant`);
    }
    
    // Fix connection entityType from "customer" to "merchant"
    const connectionsParams = {
        TableName: CONNECTIONS_TABLE,
        FilterExpression: 'entityType = :wrongType AND attribute_exists(businessId)',
        ExpressionAttributeValues: {
            ':wrongType': 'customer'
        }
    };
    
    const connectionsResult = await docClient.send(new ScanCommand(connectionsParams));
    console.log(`  📊 Found ${connectionsResult.Items?.length || 0} connections to fix`);
    
    for (const connection of connectionsResult.Items || []) {
        console.log(`  🔧 Fixing connection: ${connection.connectionId}`);
        
        const updateParams = {
            TableName: CONNECTIONS_TABLE,
            Key: {
                PK: connection.PK,
                SK: connection.SK
            },
            UpdateExpression: 'SET entityType = :correctType',
            ExpressionAttributeValues: {
                ':correctType': 'merchant'
            }
        };
        
        await docClient.send(new UpdateCommand(updateParams));
        console.log(`  ✅ Fixed entityType: customer → merchant`);
    }
}

async function testToggle() {
    console.log('\n🧪 Step 2: Testing Subscription Toggle...');
    
    // Get subscription to test
    const subscriptionsParams = {
        TableName: SUBSCRIPTIONS_TABLE,
        FilterExpression: 'subscriptionType = :type',
        ExpressionAttributeValues: {
            ':type': 'business_status'
        },
        Limit: 1
    };
    
    const subscriptionsResult = await docClient.send(new ScanCommand(subscriptionsParams));
    
    if (!subscriptionsResult.Items || subscriptionsResult.Items.length === 0) {
        console.log('  ⚠️ No business_status subscriptions found for testing');
        return;
    }
    
    const subscription = subscriptionsResult.Items[0];
    const businessId = subscription.businessId;
    const userId = subscription.userId;
    
    console.log(`  🏢 Testing with business: ${businessId}`);
    console.log(`  👤 User ID: ${userId}`);
    console.log(`  📊 Current subscription isActive: ${subscription.isActive}`);
    
    // Check current business status
    const businessParams = {
        TableName: BUSINESSES_TABLE,
        Key: { businessId: businessId }
    };
    
    const businessResult = await docClient.send(new GetCommand(businessParams));
    const business = businessResult.Item;
    
    if (!business) {
        console.log('  ❌ Business not found');
        return;
    }
    
    const currentAcceptingOrders = business.acceptingOrders || false;
    console.log(`  📊 Current business acceptingOrders: ${currentAcceptingOrders}`);
    
    // Test 1: Toggle to OFFLINE
    console.log('\n  🔄 Test 1: Toggle to OFFLINE');
    await simulateToggle(businessId, userId, false);
    await checkResults(subscription.subscriptionId, businessId, false);
    
    // Test 2: Toggle to ONLINE
    console.log('\n  🔄 Test 2: Toggle to ONLINE');
    await simulateToggle(businessId, userId, true);
    await checkResults(subscription.subscriptionId, businessId, true);
}

async function simulateToggle(businessId, userId, isOnline) {
    const timestamp = new Date().toISOString();
    
    // Update business table
    const businessUpdateParams = {
        TableName: BUSINESSES_TABLE,
        Key: { businessId: businessId },
        UpdateExpression: 'SET acceptingOrders = :status, lastStatusUpdate = :timestamp',
        ExpressionAttributeValues: {
            ':status': isOnline,
            ':timestamp': timestamp
        }
    };
    
    await docClient.send(new UpdateCommand(businessUpdateParams));
    console.log(`    ✅ Updated business acceptingOrders = ${isOnline}`);
    
    // Update subscriptions (using our fixed logic)
    const findSubscriptionParams = {
        TableName: SUBSCRIPTIONS_TABLE,
        FilterExpression: 'businessId = :businessId AND userId = :userId AND subscriptionType = :subType',
        ExpressionAttributeValues: {
            ':businessId': businessId,
            ':userId': userId,
            ':subType': 'business_status'
        }
    };
    
    const scanResult = await docClient.send(new ScanCommand(findSubscriptionParams));
    
    if (scanResult.Items && scanResult.Items.length > 0) {
        const updatePromises = scanResult.Items.map(async (subscription) => {
            const updateParams = {
                TableName: SUBSCRIPTIONS_TABLE,
                Key: {
                    subscriptionId: subscription.subscriptionId
                },
                UpdateExpression: 'SET isActive = :isActive',
                ExpressionAttributeValues: {
                    ':isActive': isOnline
                }
            };
            
            return docClient.send(new UpdateCommand(updateParams));
        });
        
        await Promise.all(updatePromises);
        console.log(`    ✅ Updated ${scanResult.Items.length} subscription(s) isActive = ${isOnline}`);
    } else {
        console.log('    ⚠️ No matching subscriptions found');
    }
}

async function checkResults(subscriptionId, businessId, expectedOnline) {
    // Check subscription
    const subParams = {
        TableName: SUBSCRIPTIONS_TABLE,
        Key: { subscriptionId: subscriptionId }
    };
    
    const subResult = await docClient.send(new GetCommand(subParams));
    const subscription = subResult.Item;
    
    // Check business
    const busParams = {
        TableName: BUSINESSES_TABLE,
        Key: { businessId: businessId }
    };
    
    const busResult = await docClient.send(new GetCommand(busParams));
    const business = busResult.Item;
    
    console.log(`    📊 Results:`);
    console.log(`      Business acceptingOrders: ${business?.acceptingOrders} (expected: ${expectedOnline})`);
    console.log(`      Subscription isActive: ${subscription?.isActive} (expected: ${expectedOnline})`);
    
    const businessCorrect = business?.acceptingOrders === expectedOnline;
    const subscriptionCorrect = subscription?.isActive === expectedOnline;
    
    if (businessCorrect && subscriptionCorrect) {
        console.log(`    ✅ ${expectedOnline ? 'ONLINE' : 'OFFLINE'} toggle test PASSED`);
    } else {
        console.log(`    ❌ ${expectedOnline ? 'ONLINE' : 'OFFLINE'} toggle test FAILED`);
    }
}

main().catch(error => {
    console.error('❌ Script failed:', error);
    process.exit(1);
});
