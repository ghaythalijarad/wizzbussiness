#!/usr/bin/env node

/**
 * Database Monitor for Sidebar Toggle Fix
 * This script monitors the WizzUser_websocket_subscriptions_dev table
 * to track changes when the sidebar toggle is used.
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, GetCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ 
    region: 'us-east-1',
    // AWS credentials should be configured via AWS CLI or environment variables
});
const dynamodb = DynamoDBDocumentClient.from(client);

const tableName = 'WizzUser_websocket_subscriptions_dev';

// Store previous state to detect changes
let previousState = {};
let monitoringStartTime = new Date();
const BUSINESS_ID = '7ccf646c-9594-48d4-8f63-c366d89257e5'; // Current logged-in business
const USER_ID = '34381438-1011-7067-5ae3-a848cbf1d682'; // Current user ID from session

// Table names
const BUSINESSES_TABLE = 'order-receiver-businesses-dev';
const CONNECTIONS_TABLE = 'WizzUser_websocket_connections_dev';
const SUBSCRIPTIONS_TABLE = 'WizzUser_websocket_subscriptions_dev';

console.log('🔍 DynamoDB Toggle Monitoring Tool');
console.log('=====================================');
console.log(`📊 Business ID: ${BUSINESS_ID}`);
console.log(`👤 User ID: ${USER_ID}`);
console.log('');

/**
 * Check business status in main table
 */
async function checkBusinessStatus() {
    try {
        const params = {
            TableName: BUSINESSES_TABLE,
            Key: {
                businessId: BUSINESS_ID
            },
            ProjectionExpression: 'businessId, acceptingOrders, lastStatusUpdate, #name',
            ExpressionAttributeNames: {
                '#name': 'name'
            }
        };

        const result = await dynamodb.send(new GetCommand(params));
        
        if (result.Item) {
            console.log('🏢 BUSINESS STATUS TABLE:');
            console.log('   Table:', BUSINESSES_TABLE);
            console.log(`   Business: ${result.Item.name || 'N/A'}`);
            console.log(`   Accepting Orders: ${result.Item.acceptingOrders ? '✅ YES' : '❌ NO'}`);
            console.log(`   Last Update: ${result.Item.lastStatusUpdate || 'Never'}`);
            console.log('');
            return result.Item;
        } else {
            console.log('❌ Business not found in table');
            return null;
        }
    } catch (error) {
        console.error('❌ Error checking business status:', error.message);
        return null;
    }
}

/**
 * Check WebSocket connections
 */
async function checkWebSocketConnections() {
    try {
        const params = {
            TableName: CONNECTIONS_TABLE,
            IndexName: 'GSI1',
            KeyConditionExpression: 'GSI1PK = :businessPK',
            ExpressionAttributeValues: {
                ':businessPK': `BUSINESS#${BUSINESS_ID}`
            }
        };

        const result = await dynamodb.send(new QueryCommand(params));
        
        console.log('🌐 WEBSOCKET CONNECTIONS TABLE:');
        console.log('   Table:', CONNECTIONS_TABLE);
        console.log(`   Total Connections: ${result.Items?.length || 0}`);
        
        if (result.Items && result.Items.length > 0) {
            result.Items.forEach((item, index) => {
                const isActive = !item.ttl || item.ttl > Math.floor(Date.now() / 1000);
                console.log(`   Connection ${index + 1}:`);
                console.log(`     Type: ${item.connectionType || 'UNKNOWN'}`);
                console.log(`     Status: ${isActive ? '🟢 Active' : '🔴 Expired'}`);
                console.log(`     Connected: ${item.connectedAt || 'Unknown'}`);
                console.log(`     User ID: ${item.userId || 'N/A'}`);
            });
        } else {
            console.log('   📭 No active connections found');
        }
        console.log('');
        return result.Items || [];
    } catch (error) {
        console.error('❌ Error checking WebSocket connections:', error.message);
        return [];
    }
}

/**
 * Check WebSocket subscriptions
 */
async function checkWebSocketSubscriptions() {
    try {
        // Try to find merchant subscription by subscription ID pattern
        const subscriptionId = `merchant_${BUSINESS_ID}_${USER_ID}`;
        
        const params = {
            TableName: SUBSCRIPTIONS_TABLE,
            Key: {
                subscriptionId: subscriptionId
            }
        };

        const result = await dynamodb.send(new GetCommand(params));
        
        console.log('📡 WEBSOCKET SUBSCRIPTIONS TABLE:');
        console.log('   Table:', SUBSCRIPTIONS_TABLE);
        console.log(`   Subscription ID: ${subscriptionId}`);
        
        if (result.Item) {
            console.log('   ✅ Subscription Found:');
            console.log(`     Entity Type: ${result.Item.entityType || 'N/A'}`);
            console.log(`     Status: ${result.Item.status || 'N/A'}`);
            console.log(`     Active: ${result.Item.isActive ? '✅ YES' : '❌ NO'}`);
            console.log(`     Topic: ${result.Item.topic || 'N/A'}`);
            console.log(`     Last Update: ${result.Item.lastUpdate || 'Never'}`);
        } else {
            console.log('   📭 No subscription found with expected ID');
            
            // Try a broader search
            console.log('   🔍 Searching for any merchant subscriptions...');
            const scanParams = {
                TableName: SUBSCRIPTIONS_TABLE,
                FilterExpression: 'entityType = :entityType AND entityId = :businessId',
                ExpressionAttributeValues: {
                    ':entityType': 'merchant',
                    ':businessId': BUSINESS_ID
                },
                Limit: 10
            };
            
            const scanResult = await dynamodb.send(new ScanCommand(scanParams));
            if (scanResult.Items && scanResult.Items.length > 0) {
                console.log(`   📋 Found ${scanResult.Items.length} related subscriptions:`);
                scanResult.Items.forEach((item, index) => {
                    console.log(`     ${index + 1}. ID: ${item.subscriptionId}`);
                    console.log(`        Status: ${item.status || 'N/A'}`);
                    console.log(`        Active: ${item.isActive ? '✅' : '❌'}`);
                });
            }
        }
        console.log('');
        return result.Item;
    } catch (error) {
        console.error('❌ Error checking WebSocket subscriptions:', error.message);
        return null;
    }
}

/**
 * Monitor changes with timestamps
 */
async function monitorChanges() {
    const startTime = new Date().toISOString();
    console.log(`🚀 Monitoring started at: ${startTime}`);
    console.log('🔄 Toggle your merchant status in the app now...');
    console.log('📱 Watch the tables update in real-time below:');
    console.log('=====================================');
    console.log('');

    let previousState = null;
    let changeDetected = false;

    // Monitor every 2 seconds for 2 minutes
    const monitoring = setInterval(async () => {
        const currentTime = new Date().toISOString();
        console.log(`⏰ Check at: ${currentTime}`);
        console.log('─'.repeat(50));

        // Check all tables
        const businessStatus = await checkBusinessStatus();
        const connections = await checkWebSocketConnections();
        const subscriptions = await checkWebSocketSubscriptions();

        // Detect changes
        const currentState = {
            acceptingOrders: businessStatus?.acceptingOrders,
            lastStatusUpdate: businessStatus?.lastStatusUpdate,
            connectionsCount: connections.length,
            subscriptionStatus: subscriptions?.status,
            subscriptionActive: subscriptions?.isActive
        };

        if (previousState) {
            const changes = [];
            if (previousState.acceptingOrders !== currentState.acceptingOrders) {
                changes.push(`accepting orders: ${previousState.acceptingOrders} → ${currentState.acceptingOrders}`);
            }
            if (previousState.lastStatusUpdate !== currentState.lastStatusUpdate) {
                changes.push(`timestamp updated`);
            }
            if (previousState.connectionsCount !== currentState.connectionsCount) {
                changes.push(`connections: ${previousState.connectionsCount} → ${currentState.connectionsCount}`);
            }
            if (previousState.subscriptionStatus !== currentState.subscriptionStatus) {
                changes.push(`subscription status: ${previousState.subscriptionStatus} → ${currentState.subscriptionStatus}`);
            }
            if (previousState.subscriptionActive !== currentState.subscriptionActive) {
                changes.push(`subscription active: ${previousState.subscriptionActive} → ${currentState.subscriptionActive}`);
            }

            if (changes.length > 0) {
                console.log('🎉 CHANGES DETECTED:');
                changes.forEach(change => console.log(`   📝 ${change}`));
                changeDetected = true;
            } else if (!changeDetected) {
                console.log('⏳ Waiting for changes...');
            }
        }

        previousState = currentState;
        console.log('');
    }, 2000);

    // Stop monitoring after 2 minutes
    setTimeout(() => {
        clearInterval(monitoring);
        console.log('🏁 Monitoring completed!');
        console.log('');
        if (changeDetected) {
            console.log('✅ Changes were detected in the DynamoDB tables!');
        } else {
            console.log('ℹ️  No changes detected. Make sure to toggle the status in your app.');
        }
        process.exit(0);
    }, 120000); // 2 minutes
}

// Start monitoring
monitorChanges().catch(console.error);
