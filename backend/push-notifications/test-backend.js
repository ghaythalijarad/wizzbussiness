#!/usr/bin/env node

/**
 * Test Push Notifications Backend
 * 
 * This script tests the deployed push notification infrastructure
 */

const https = require('https');
const AWS = require('aws-sdk');

// Configuration
const API_BASE_URL = process.env.API_BASE_URL || 'https://YOUR_API_ENDPOINT_HERE';
const JWT_TOKEN = process.env.JWT_TOKEN || 'your-jwt-token-here';
const TEST_DEVICE_TOKEN = 'test-fcm-token-' + Date.now();

async function makeApiCall(path, method = 'POST', data = null) {
    return new Promise((resolve, reject) => {
        const url = new URL(API_BASE_URL + path);
        
        const options = {
            hostname: url.hostname,
            port: 443,
            path: url.pathname,
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${JWT_TOKEN}`
            }
        };

        const req = https.request(options, (res) => {
            let body = '';
            
            res.on('data', (chunk) => {
                body += chunk;
            });
            
            res.on('end', () => {
                try {
                    const response = JSON.parse(body);
                    resolve({
                        statusCode: res.statusCode,
                        body: response
                    });
                } catch (error) {
                    resolve({
                        statusCode: res.statusCode,
                        body: body
                    });
                }
            });
        });

        req.on('error', (error) => {
            reject(error);
        });

        if (data) {
            req.write(JSON.stringify(data));
        }
        
        req.end();
    });
}

async function testDeviceTokenRegistration() {
    console.log('🧪 Testing device token registration...');
    
    try {
        const response = await makeApiCall('/notifications/register-token', 'POST', {
            deviceToken: TEST_DEVICE_TOKEN
        });
        
        if (response.statusCode === 200) {
            console.log('✅ Device token registration successful');
            console.log('Response:', response.body);
            return true;
        } else {
            console.log('❌ Device token registration failed');
            console.log('Status:', response.statusCode);
            console.log('Response:', response.body);
            return false;
        }
    } catch (error) {
        console.error('❌ Error during device token registration:', error.message);
        return false;
    }
}

async function testPushNotificationSend() {
    console.log('🧪 Testing push notification send...');
    
    try {
        const response = await makeApiCall('/notifications/send', 'POST', {
            merchantId: 'test-merchant-' + Date.now(),
            title: 'Test Notification',
            message: 'This is a test push notification from the migration test script',
            data: {
                test: true,
                timestamp: new Date().toISOString()
            }
        });
        
        if (response.statusCode === 200) {
            console.log('✅ Push notification send successful');
            console.log('Response:', response.body);
            return true;
        } else {
            console.log('❌ Push notification send failed');
            console.log('Status:', response.statusCode);
            console.log('Response:', response.body);
            return false;
        }
    } catch (error) {
        console.error('❌ Error during push notification send:', error.message);
        return false;
    }
}

async function testDynamoDBTables() {
    console.log('🧪 Testing DynamoDB tables...');
    
    try {
        const dynamodb = new AWS.DynamoDB({ region: 'us-east-1' });
        
        // Test Device Tokens table
        const deviceTokensTableName = 'push-notifications-dev-device-tokens';
        const deviceTokensTable = await dynamodb.describeTable({ 
            TableName: deviceTokensTableName 
        }).promise();
        
        console.log('✅ Device Tokens table exists and is active');
        
        // Test Push Logs table
        const pushLogsTableName = 'push-notifications-dev-push-logs';
        const pushLogsTable = await dynamodb.describeTable({ 
            TableName: pushLogsTableName 
        }).promise();
        
        console.log('✅ Push Logs table exists and is active');
        
        return true;
    } catch (error) {
        console.error('❌ Error testing DynamoDB tables:', error.message);
        return false;
    }
}

async function main() {
    console.log('🚀 Testing Push Notifications Backend Migration\n');
    
    // Check configuration
    if (API_BASE_URL.includes('YOUR_API_ENDPOINT_HERE')) {
        console.log('❌ Please set API_BASE_URL environment variable');
        console.log('Usage: API_BASE_URL=https://your-api-endpoint.com JWT_TOKEN=your-token node test-backend.js');
        process.exit(1);
    }
    
    if (JWT_TOKEN === 'your-jwt-token-here') {
        console.log('⚠️  JWT_TOKEN not set - API calls may fail with authentication errors');
    }
    
    const results = [];
    
    // Test 1: DynamoDB Tables
    console.log('=== Test 1: DynamoDB Tables ===');
    const tablesTest = await testDynamoDBTables();
    results.push({ test: 'DynamoDB Tables', passed: tablesTest });
    console.log('');
    
    // Test 2: Device Token Registration
    console.log('=== Test 2: Device Token Registration ===');
    const registrationTest = await testDeviceTokenRegistration();
    results.push({ test: 'Device Token Registration', passed: registrationTest });
    console.log('');
    
    // Test 3: Push Notification Send
    console.log('=== Test 3: Push Notification Send ===');
    const sendTest = await testPushNotificationSend();
    results.push({ test: 'Push Notification Send', passed: sendTest });
    console.log('');
    
    // Summary
    console.log('=== Test Summary ===');
    const passedTests = results.filter(r => r.passed).length;
    const totalTests = results.length;
    
    results.forEach(result => {
        const status = result.passed ? '✅' : '❌';
        console.log(`${status} ${result.test}`);
    });
    
    console.log('');
    console.log(`📊 Results: ${passedTests}/${totalTests} tests passed`);
    
    if (passedTests === totalTests) {
        console.log('🎉 All tests passed! Migration is working correctly.');
        process.exit(0);
    } else {
        console.log('⚠️  Some tests failed. Please check the configuration and deployment.');
        process.exit(1);
    }
}

// Run tests
if (require.main === module) {
    main();
}
