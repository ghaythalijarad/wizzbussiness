const axios = require('axios');
const fs = require('fs');
const AWS = require('aws-sdk');

// Read the access token
const token = fs.readFileSync('access_token.txt', 'utf8').trim();
const baseUrl = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

// Configure AWS for checking CloudWatch logs
AWS.config.update({ region: 'us-east-1' });
const cloudwatchLogs = new AWS.CloudWatchLogs();

async function testProductsEndpoint() {
    console.log('🧪 Testing Products Endpoint Directly');
    console.log('=====================================');
    
    try {
        console.log('📞 Calling GET /products...');
        const response = await axios.get(`${baseUrl}/products`, {
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            }
        });
        
        console.log('✅ Success:', response.status);
        console.log('📋 Data:', JSON.stringify(response.data, null, 2));
        
    } catch (error) {
        console.log('❌ Error:', error.response?.status, error.response?.statusText);
        console.log('📄 Error Data:', JSON.stringify(error.response?.data, null, 2));
        
        // Try to get recent CloudWatch logs
        console.log('\n🔍 Checking CloudWatch logs...');
        await getRecentLogs();
    }
}

async function getRecentLogs() {
    try {
        const logGroupName = '/aws/lambda/order-receiver-dev-order-management-v1-sls';
        
        // Get log streams from the last 10 minutes
        const streamsResponse = await cloudwatchLogs.describeLogStreams({
            logGroupName: logGroupName,
            orderBy: 'LastEventTime',
            descending: true,
            limit: 5
        }).promise();
        
        if (streamsResponse.logStreams.length > 0) {
            const latestStream = streamsResponse.logStreams[0];
            console.log(`📝 Latest log stream: ${latestStream.logStreamName}`);
            
            // Get recent log events
            const eventsResponse = await cloudwatchLogs.getLogEvents({
                logGroupName: logGroupName,
                logStreamName: latestStream.logStreamName,
                startTime: Date.now() - 5 * 60 * 1000, // Last 5 minutes
                limit: 20
            }).promise();
            
            console.log('\n🔍 Recent log events:');
            eventsResponse.events.forEach(event => {
                console.log(`[${new Date(event.timestamp).toISOString()}] ${event.message}`);
            });
        } else {
            console.log('📋 No recent log streams found');
        }
        
    } catch (logError) {
        console.log('❌ Error getting logs:', logError.message);
    }
}

testProductsEndpoint();
