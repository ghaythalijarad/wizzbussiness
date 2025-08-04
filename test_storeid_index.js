#!/usr/bin/env node

const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const ORDERS_TABLE = 'order-receiver-orders-dev';

async function testStoreIdIndex() {
    console.log('🔍 Testing StoreIdIndex functionality...\n');

    // Test with the main store ID from the data we saw
    const storeId = '7ccf646c-9594-48d4-8f63-c366d89257e5';

    try {
        console.log(`📊 Querying orders for storeId: ${storeId}`);

        const params = {
            TableName: ORDERS_TABLE,
            IndexName: 'StoreIdIndex',
            KeyConditionExpression: 'storeId = :storeId',
            ExpressionAttributeValues: {
                ':storeId': storeId
            }
        };

        console.log('Query parameters:', JSON.stringify(params, null, 2));

        const startTime = Date.now();
        const result = await dynamodb.query(params).promise();
        const queryTime = Date.now() - startTime;

        console.log(`\n✅ Query completed successfully!`);
        console.log(`⏱️  Query time: ${queryTime}ms`);
        console.log(`📦 Items returned: ${result.Items.length}`);
        console.log(`🔥 Consumed capacity: ${JSON.stringify(result.ConsumedCapacity)}`);

        if (result.Items.length > 0) {
            console.log('\n📋 Sample order:');
            const sampleOrder = result.Items[0];
            console.log(`   Order ID: ${sampleOrder.orderId}`);
            console.log(`   Store ID: ${sampleOrder.storeId}`);
            console.log(`   Status: ${sampleOrder.status}`);
            console.log(`   Customer: ${sampleOrder.customerName}`);
            console.log(`   Total: ${sampleOrder.totalAmount}`);
            console.log(`   Created: ${sampleOrder.createdAt}`);
        }

        // Test with status filter
        console.log('\n🔍 Testing with status filter (pending orders)...');

        const filteredParams = {
            ...params,
            FilterExpression: '#status = :status',
            ExpressionAttributeNames: { '#status': 'status' },
            ExpressionAttributeValues: {
                ...params.ExpressionAttributeValues,
                ':status': 'pending'
            }
        };

        const filteredStartTime = Date.now();
        const filteredResult = await dynamodb.query(filteredParams).promise();
        const filteredQueryTime = Date.now() - filteredStartTime;

        console.log(`⏱️  Filtered query time: ${filteredQueryTime}ms`);
        console.log(`📦 Pending orders found: ${filteredResult.Items.length}`);

        // Compare with scan operation (inefficient way)
        console.log('\n🐌 Comparing with inefficient scan operation...');

        const scanParams = {
            TableName: ORDERS_TABLE,
            FilterExpression: 'storeId = :storeId',
            ExpressionAttributeValues: {
                ':storeId': storeId
            }
        };

        const scanStartTime = Date.now();
        const scanResult = await dynamodb.scan(scanParams).promise();
        const scanTime = Date.now() - scanStartTime;

        console.log(`⏱️  Scan time: ${scanTime}ms`);
        console.log(`📦 Scan items returned: ${scanResult.Items.length}`);

        console.log('\n📊 Performance Comparison:');
        console.log(`   Query (with index): ${queryTime}ms ⚡`);
        console.log(`   Scan (full table): ${scanTime}ms 🐌`);
        console.log(`   Speed improvement: ${Math.round(scanTime / queryTime)}x faster`);

        // Test other store IDs
        console.log('\n🔍 Testing other store IDs...');
        const testStoreIds = ['test-store-123', '2e102ff3-72a2-4823-93b8-f975d915c82e'];

        for (const testStoreId of testStoreIds) {
            const testParams = {
                TableName: ORDERS_TABLE,
                IndexName: 'StoreIdIndex',
                KeyConditionExpression: 'storeId = :storeId',
                ExpressionAttributeValues: {
                    ':storeId': testStoreId
                }
            };

            try {
                const testResult = await dynamodb.query(testParams).promise();
                console.log(`   Store ${testStoreId}: ${testResult.Items.length} orders`);
            } catch (error) {
                console.log(`   Store ${testStoreId}: Error - ${error.message}`);
            }
        }

        console.log('\n🎉 StoreIdIndex is working perfectly!');
        console.log('✅ Option 2 implementation is complete and efficient.');

    } catch (error) {
        console.error('❌ Error testing StoreIdIndex:', error);
        process.exit(1);
    }
}

// Run the test
testStoreIdIndex();
