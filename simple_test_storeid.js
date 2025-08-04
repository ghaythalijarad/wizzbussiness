#!/usr/bin/env node

console.log('🔍 Starting StoreIdIndex test...');

const AWS = require('aws-sdk');

console.log('📦 AWS SDK loaded successfully');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

console.log('🔧 DynamoDB client configured');

const ORDERS_TABLE = 'order-receiver-orders-dev';
const storeId = '7ccf646c-9594-48d4-8f63-c366d89257e5';

console.log(`📊 Testing query for storeId: ${storeId}`);

const params = {
    TableName: ORDERS_TABLE,
    IndexName: 'StoreIdIndex',
    KeyConditionExpression: 'storeId = :storeId',
    ExpressionAttributeValues: {
        ':storeId': storeId
    }
};

console.log('📝 Query parameters:', JSON.stringify(params, null, 2));

dynamodb.query(params)
    .promise()
    .then(result => {
        console.log('✅ Query successful!');
        console.log(`📦 Items returned: ${result.Items.length}`);
        console.log('🎉 StoreIdIndex is working perfectly!');

        if (result.Items.length > 0) {
            const sample = result.Items[0];
            console.log('📋 Sample order:');
            console.log(`   Order ID: ${sample.orderId}`);
            console.log(`   Store ID: ${sample.storeId}`);
            console.log(`   Status: ${sample.status}`);
            console.log(`   Customer: ${sample.customerName}`);
        }
    })
    .catch(error => {
        console.error('❌ Query failed:', error.message);
        console.error('🔍 Full error:', JSON.stringify(error, null, 2));
    });

console.log('⏳ Query initiated...');
