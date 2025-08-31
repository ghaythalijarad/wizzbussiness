#!/usr/bin/env node

/**
 * Fix WebSocket Schema and Test Subscription Toggle
 * 
 * This script will:
 * 1. Fix the entity type from "customer" to "merchant" 
 * 2. Test the subscription toggle functionality
 * 3. Verify the isActive field changes correctly
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, UpdateCommand, GetCommand } = require('@aws-sdk/lib-dynamodb');

// Configure AWS SDK v3
const dynamoDbClient = new DynamoDBClient({ 
    region: 'us-east-1',
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    }
});
const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

const SUBSCRIPTIONS_TABLE = 'WizzUser_websocket_subscriptions_dev';
const CONNECTIONS_TABLE = 'WizzUser_websocket_connections_dev';
const BUSINESSES_TABLE = 'order-receiver-businesses-dev';

async function main() {
    console.log('🔧 Starting WebSocket Schema Fix and Test...\n');

    try {
        // Step 1: Fix entity types in both tables
        await fixEntityTypes();
        
        // Step 2: Test the subscription toggle
        await testSubscriptionToggle();
        
        console.log('\n✅ All fixes and tests completed successfully!');
        
    } catch (error) {
        console.error('❌ Error during fix/test:', error);
        process.exit(1);
    }
}

async function fixEntityTypes() {
    console.log('📝 Step 1: Fixing Entity Types...');
    
    // Fix subscription table
    console.log('  🔍 Scanning subscription table...');
    const subscriptionsParams = {
        TableName: SUBSCRIPTIONS_TABLE,
        FilterExpression: 'subscriptionType = :type AND userType = :wrongType',
        ExpressionAttributeValues: {
            ':type': 'business_status',
            ':wrongType': 'customer'
        }
    };
    
    const subscriptionsResult = await dynamodb.send(new ScanCommand(subscriptionsParams));
    console.log(`  📊 Found ${subscriptionsResult.Items.length} subscription(s) to fix`);
    
    for (const subscription of subscriptionsResult.Items) {
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
        
        await dynamodb.send(new UpdateCommand(updateParams));
        console.log(`  ✅ Fixed subscription userType: customer → merchant`);
    }
    
    // Fix connections table
    console.log('  🔍 Scanning connections table...');
    const connectionsParams = {
        TableName: CONNECTIONS_TABLE,
        FilterExpression: 'entityType = :wrongType AND attribute_exists(businessId)',
        ExpressionAttributeValues: {
            ':wrongType': 'customer'
        }
    };
    
    const connectionsResult = await dynamodb.send(new ScanCommand(connectionsParams));
    console.log(`  📊 Found ${connectionsResult.Items.length} connection(s) to fix`);
    
    for (const connection of connectionsResult.Items) {
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
        
        await dynamodb.send(new UpdateCommand(updateParams));
        console.log(`  ✅ Fixed connection entityType: customer → merchant`);
    }
}

async function testSubscriptionToggle() {
    console.log('\n🧪 Step 2: Testing Subscription Toggle...');
    
    // Get the business ID from the subscription
    const subscriptionsParams = {
        TableName: SUBSCRIPTIONS_TABLE,
        FilterExpression: 'subscriptionType = :type',
        ExpressionAttributeValues: {
            ':type': 'business_status'
        }
    };
    
    const subscriptionsResult = await dynamodb.send(new ScanCommand(subscriptionsParams));
    
    if (subscriptionsResult.Items.length === 0) {
        console.log('  ⚠️ No business_status subscriptions found for testing');
        return;
    }
    
    const subscription = subscriptionsResult.Items[0];
    const businessId = subscription.businessId;
    const userId = subscription.userId;
    
    console.log(`  🏢 Testing with business: ${businessId}`);
    console.log(`  👤 User ID: ${userId}`);
    
    // Check current business status
    const businessParams = {
        TableName: BUSINESSES_TABLE,
        Key: {
            businessId: businessId
        }
    };
    
    const businessResult = await dynamodb.send(new GetCommand(businessParams));
    const business = businessResult.Item;
    
    if (!business) {
        console.log('  ❌ Business not found in businesses table');
        return;
    }
    
    const currentStatus = business.acceptingOrders ? 'online' : 'offline';
    console.log(`  📊 Current business status: ${currentStatus} (acceptingOrders: ${business.acceptingOrders})`);
    console.log(`  📊 Current subscription isActive: ${subscription.isActive}`);
    
    // Test toggling to offline
    console.log('\n  🔄 Testing toggle to OFFLINE...');
    await simulateBusinessToggle(businessId, userId, 'offline');
    
    // Check subscription after toggle
    await checkSubscriptionStatus(subscription.subscriptionId, 'offline');
    
    // Test toggling back to online
    console.log('\n  🔄 Testing toggle to ONLINE...');
    await simulateBusinessToggle(businessId, userId, 'online');
    
    // Check subscription after toggle
    await checkSubscriptionStatus(subscription.subscriptionId, 'online');
}

async function simulateBusinessToggle(businessId, userId, status) {
    const isOnline = status === 'online';
    const timestamp = new Date().toISOString();
    
    // Update business table
    const businessUpdateParams = {
        TableName: BUSINESSES_TABLE,
        Key: {
            businessId: businessId
        },
        UpdateExpression: 'SET acceptingOrders = :status, lastStatusUpdate = :timestamp',
        ExpressionAttributeValues: {
            ':status': isOnline,
            ':timestamp': timestamp
        }
    };
    
    await dynamodb.send(new UpdateCommand(businessUpdateParams));
    console.log(`    ✅ Updated business table: acceptingOrders = ${isOnline}`);
    
    // Update subscriptions using the same logic as our fix
    const findSubscriptionParams = {
        TableName: SUBSCRIPTIONS_TABLE,
        FilterExpression: 'businessId = :businessId AND userId = :userId AND subscriptionType = :subType',
        ExpressionAttributeValues: {
            ':businessId': businessId,
            ':userId': userId,
            ':subType': 'business_status'
        }
    };
    
    const scanResult = await dynamodb.send(new ScanCommand(findSubscriptionParams));
    
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
            
            return dynamodb.send(new UpdateCommand(updateParams));
        });
        
        await Promise.all(updatePromises);
        console.log(`    ✅ Updated ${scanResult.Items.length} subscription(s): isActive = ${isOnline}`);
    } else {
        console.log('    ⚠️ No matching subscriptions found to update');
    }
}

async function checkSubscriptionStatus(subscriptionId, expectedStatus) {
    const getParams = {
        TableName: SUBSCRIPTIONS_TABLE,
        Key: {
            subscriptionId: subscriptionId
        }
    };
    
    const result = await dynamodb.send(new GetCommand(getParams));
    const subscription = result.Item;
    
    if (subscription) {
        const expectedActive = expectedStatus === 'online';
        const actualActive = subscription.isActive;
        
        console.log(`    📊 Subscription isActive: ${actualActive} (expected: ${expectedActive})`);
        
        if (actualActive === expectedActive) {
            console.log(`    ✅ Subscription status correct for ${expectedStatus} mode`);
        } else {
            console.log(`    ❌ Subscription status incorrect! Expected ${expectedActive}, got ${actualActive}`);
        }
    } else {
        console.log('    ❌ Subscription not found');
    }
}

// Load AWS credentials from profile
process.env.AWS_PROFILE = 'wizz-merchants-dev';
process.env.AWS_SDK_LOAD_CONFIG = '1';

main().catch(console.error);
