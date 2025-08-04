const AWS = require('aws-sdk');
const axios = require('axios');

// Configuration
const API_BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const WORKING_HOURS_TABLE = 'order-receiver-business-working-hours-dev';

// Configure AWS
const dynamodb = new AWS.DynamoDB.DocumentClient({
    region: 'us-east-1'
});

async function testWorkingHours() {
    try {
        console.log('🧪 Testing Working Hours Fix...\n');
        
        // Step 1: Get access token
        console.log('1️⃣ Getting access token...');
        const authResponse = await axios.post(`${API_BASE_URL}/auth/login`, {
            email: 'test@example.com',
            password: 'Test123!'
        });
        
        const accessToken = authResponse.data.accessToken;
        const businessId = authResponse.data.business?.businessId;
        
        if (!accessToken || !businessId) {
            console.error('❌ Failed to get access token or business ID');
            return;
        }
        
        console.log('✅ Got access token and business ID:', businessId);
        
        // Step 2: Test working hours with various time formats
        console.log('\n2️⃣ Testing working hours update...');
        const testWorkingHours = {
            Monday: { opening: '09:00', closing: '17:00' },
            Tuesday: { opening: '08:30', closing: '18:00' },
            Wednesday: { opening: '09:00', closing: '17:30' },
            Thursday: { opening: '08:00', closing: '19:00' },
            Friday: { opening: '10:00', closing: '16:00' },
            Saturday: { opening: '11:00', closing: '15:00' },
            Sunday: { opening: '12:00', closing: '14:00' }
        };
        
        console.log('📝 Sending working hours data:', JSON.stringify(testWorkingHours, null, 2));
        
        const updateResponse = await axios.put(
            `${API_BASE_URL}/businesses/${businessId}/working-hours`,
            testWorkingHours,
            {
                headers: {
                    'Authorization': `Bearer ${accessToken}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        console.log('✅ Working hours update response:', updateResponse.data);
        
        // Step 3: Wait a moment for the data to be written
        console.log('\n3️⃣ Waiting for data to be written...');
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        // Step 4: Check the database directly
        console.log('\n4️⃣ Checking database records...');
        const scanParams = {
            TableName: WORKING_HOURS_TABLE,
            FilterExpression: 'business_id = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessId
            }
        };
        
        const scanResult = await dynamodb.scan(scanParams).promise();
        
        console.log(`📊 Found ${scanResult.Items.length} working hours records:`);
        
        scanResult.Items.forEach(item => {
            console.log(`📅 ${item.weekday}: ${item.opening} - ${item.closing} (Updated: ${item.updated_at})`);
        });
        
        // Step 5: Verify all days are present and have valid times
        const expectedDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        const foundDays = scanResult.Items.map(item => item.weekday);
        
        console.log('\n5️⃣ Verification Results:');
        let allGood = true;
        
        expectedDays.forEach(day => {
            const record = scanResult.Items.find(item => item.weekday === day);
            if (!record) {
                console.log(`❌ Missing record for ${day}`);
                allGood = false;
            } else if (!record.opening || !record.closing) {
                console.log(`❌ ${day} has null/empty times: opening="${record.opening}", closing="${record.closing}"`);
                allGood = false;
            } else {
                console.log(`✅ ${day}: ${record.opening} - ${record.closing}`);
            }
        });
        
        if (allGood) {
            console.log('\n🎉 All working hours are saving correctly! The fix is working! 🎉');
        } else {
            console.log('\n❌ Some working hours are still not saving correctly.');
        }
        
        // Step 6: Test the GET endpoint
        console.log('\n6️⃣ Testing GET working hours endpoint...');
        const getResponse = await axios.get(
            `${API_BASE_URL}/businesses/${businessId}/working-hours`,
            {
                headers: {
                    'Authorization': `Bearer ${accessToken}`
                }
            }
        );
        
        console.log('📥 GET working hours response:', JSON.stringify(getResponse.data, null, 2));
        
    } catch (error) {
        console.error('❌ Test failed:', error.response?.data || error.message);
        if (error.response?.status) {
            console.error('Status:', error.response.status);
        }
    }
}

testWorkingHours();
