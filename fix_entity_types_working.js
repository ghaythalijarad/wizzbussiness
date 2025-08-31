#!/usr/bin/env node

/**
 * Working Fix for Entity Types - Handle DynamoDB Keys Correctly
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, UpdateCommand, GetCommand, DescribeTableCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({ region: 'us-east-1' });
const docClient = DynamoDBDocumentClient.from(client);

const SUBSCRIPTIONS_TABLE = 'WizzUser_websocket_subscriptions_dev';
const CONNECTIONS_TABLE = 'WizzUser_websocket_connections_dev';
const BUSINESSES_TABLE = 'order-receiver-businesses-dev';

// Add timeout
setTimeout(() => {
    console.log('⏰ Script timeout after 60 seconds');
    process.exit(1);
}, 60000);

async function main() {
    console.log('🔧 Starting Entity Type Fix...\n');

    try {
        // Step 1: Check table schemas
        await checkTableSchemas();
        
        // Step 2: Fix subscription entity types
        await fixSubscriptionEntityTypes();
        
        // Step 3: Fix connection entity types
        await fixConnectionEntityTypes();
        
        // Step 4: Test the fix
        await testEntityTypeFix();
        
        console.log('\n✅ Entity type fix completed successfully!');
        process.exit(0);
        
    } catch (error) {
        console.error('❌ Error:', error.message);
        console.error('Stack:', error.stack);
        process.exit(1);
    }
}

async function checkTableSchemas() {
    console.log('📋 Step 1: Checking Table Schemas...');
    
    try {
        // Check subscriptions table
        const subsSchema = await client.send(new DescribeTableCommand({
            TableName: SUBSCRIPTIONS_TABLE
        }));
        
        console.log('  📊 Subscriptions Table Schema:');
        console.log('    Keys:', subsSchema.Table.KeySchema);
        
        // Check connections table  
        const connSchema = await client.send(new DescribeTableCommand({
            TableName: CONNECTIONS_TABLE
        }));
        
        console.log('  📊 Connections Table Schema:');
        console.log('    Keys:', connSchema.Table.KeySchema);
        
    } catch (error) {
        console.log('  ⚠️ Could not retrieve table schemas:', error.message);
        console.log('  📝 Proceeding with known key structures...');
    }
}

async function fixSubscriptionEntityTypes() {
    console.log('\n🔧 Step 2: Fixing Subscription Entity Types...');
    
    // Find business_status subscriptions with wrong userType
    const scanParams = {
        TableName: SUBSCRIPTIONS_TABLE,
        FilterExpression: 'subscriptionType = :type AND userType = :wrongType',
        ExpressionAttributeValues: {
            ':type': 'business_status',
            ':wrongType': 'customer'
        }
    };
    
    const result = await docClient.send(new ScanCommand(scanParams));
    console.log(`  📊 Found ${result.Items?.length || 0} subscriptions to fix`);
    
    for (const subscription of result.Items || []) {
        console.log(`  🔧 Fixing subscription: ${subscription.subscriptionId}`);
        console.log(`    Current userType: ${subscription.userType}`);
        console.log(`    Business ID: ${subscription.businessId}`);
        
        try {
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
            console.log(`    ✅ Updated userType: customer → merchant`);
            
        } catch (updateError) {
            console.log(`    ❌ Failed to update subscription: ${updateError.message}`);
            
            // Try alternative key structure if primary key failed
            console.log(`    🔄 Trying alternative key structure...`);
            
            // List all fields in the subscription to understand the key
            console.log(`    📝 Subscription fields:`, Object.keys(subscription));
        }
    }
}

async function fixConnectionEntityTypes() {
    console.log('\n🔧 Step 3: Fixing Connection Entity Types...');
    
    // Find connections with wrong entityType that have businessId
    const scanParams = {
        TableName: CONNECTIONS_TABLE,
        FilterExpression: 'entityType = :wrongType AND attribute_exists(businessId)',
        ExpressionAttributeValues: {
            ':wrongType': 'customer'
        }
    };
    
    const result = await docClient.send(new ScanCommand(scanParams));
    console.log(`  📊 Found ${result.Items?.length || 0} connections to fix`);
    
    for (const connection of result.Items || []) {
        console.log(`  🔧 Fixing connection: ${connection.connectionId}`);
        console.log(`    Current entityType: ${connection.entityType}`);
        console.log(`    Business ID: ${connection.businessId}`);
        console.log(`    Connection fields:`, Object.keys(connection));
        
        try {
            // Try the primary key approach first
            let updateParams = {
                TableName: CONNECTIONS_TABLE,
                Key: {
                    connectionId: connection.connectionId
                },
                UpdateExpression: 'SET entityType = :correctType',
                ExpressionAttributeValues: {
                    ':correctType': 'merchant'
                }
            };
            
            await docClient.send(new UpdateCommand(updateParams));
            console.log(`    ✅ Updated entityType: customer → merchant`);
            
        } catch (updateError) {
            console.log(`    ⚠️ Primary key failed: ${updateError.message}`);
            
            // Try composite key structure
            try {
                console.log(`    🔄 Trying composite key structure...`);
                
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
                console.log(`    ✅ Updated entityType using composite key: customer → merchant`);
                
            } catch (compositeError) {
                console.log(`    ❌ Both key approaches failed:`);
                console.log(`      Primary: ${updateError.message}`);
                console.log(`      Composite: ${compositeError.message}`);
                console.log(`    📝 Skipping this connection for manual review`);
            }
        }
    }
}

async function testEntityTypeFix() {
    console.log('\n🧪 Step 4: Testing Entity Type Fix...');
    
    // Check if subscriptions were fixed
    const subsParams = {
        TableName: SUBSCRIPTIONS_TABLE,
        FilterExpression: 'subscriptionType = :type',
        ExpressionAttributeValues: {
            ':type': 'business_status'
        }
    };
    
    const subsResult = await docClient.send(new ScanCommand(subsParams));
    
    console.log('  📊 Subscription Status:');
    for (const sub of subsResult.Items || []) {
        console.log(`    ${sub.subscriptionId}: userType=${sub.userType}, businessId=${sub.businessId}`);
    }
    
    // Check if connections were fixed
    const connParams = {
        TableName: CONNECTIONS_TABLE,
        FilterExpression: 'attribute_exists(businessId)',
        Limit: 5 // Just check a few
    };
    
    const connResult = await docClient.send(new ScanCommand(connParams));
    
    console.log('  📊 Connection Status (sample):');
    for (const conn of connResult.Items || []) {
        console.log(`    ${conn.connectionId}: entityType=${conn.entityType}, businessId=${conn.businessId}`);
    }
}

// Run the script
main().catch(console.error);
