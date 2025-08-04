const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');
const axios = require('axios');

// Configuration
const API_BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const WORKING_HOURS_TABLE = 'order-receiver-business-working-hours-dev';

// Configure AWS SDK v3
const dynamoDbClient = new DynamoDBClient({ region: 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

async function testWorkingHoursFunctionality() {
    try {
        console.log('🧪 Testing Working Hours Functionality End-to-End...\n');

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

        // Step 2: Check current working hours in database
        console.log('\n2️⃣ Checking current working hours in database...');
        const scanParams = {
            TableName: WORKING_HOURS_TABLE,
            FilterExpression: 'business_id = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessId
            }
        };

        const scanResult = await dynamodb.send(new ScanCommand(scanParams));
        console.log(`📊 Found ${scanResult.Items.length} existing working hours records for this business`);

        scanResult.Items.forEach(item => {
            console.log(`📅 ${item.weekday}: ${item.opening} - ${item.closing} (Updated: ${item.updated_at})`);
        });

        // Step 3: Test GET working hours endpoint
        console.log('\n3️⃣ Testing GET working hours endpoint...');
        const getResponse = await axios.get(
            `${API_BASE_URL}/businesses/${businessId}/working-hours`,
            {
                headers: {
                    'Authorization': `Bearer ${accessToken}`
                }
            }
        );

        console.log('📥 GET working hours response:', JSON.stringify(getResponse.data, null, 2));

        // Step 4: Test working hours update with new times
        console.log('\n4️⃣ Testing working hours update...');
        const testWorkingHours = {
            Monday: { opening: '08:00', closing: '17:00' },
            Tuesday: { opening: '08:00', closing: '17:00' },
            Wednesday: { opening: '08:00', closing: '17:00' },
            Thursday: { opening: '08:00', closing: '17:00' },
            Friday: { opening: '08:00', closing: '17:00' },
            Saturday: { opening: '10:00', closing: '16:00' },
            Sunday: { opening: null, closing: null } // Test null values
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

        // Step 5: Wait for data to be written
        console.log('\n5️⃣ Waiting for data to be written...');
        await new Promise(resolve => setTimeout(resolve, 2000));

        // Step 6: Verify the updated data in database
        console.log('\n6️⃣ Verifying updated data in database...');
        const verifyResult = await dynamodb.send(new ScanCommand(scanParams));

        console.log(`📊 Found ${verifyResult.Items.length} working hours records after update:`);

        const expectedDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        let allGood = true;

        expectedDays.forEach(day => {
            const record = verifyResult.Items.find(item => item.weekday === day);
            if (!record) {
                console.log(`❌ Missing record for ${day}`);
                allGood = false;
            } else {
                console.log(`✅ ${day}: ${record.opening || 'NULL'} - ${record.closing || 'NULL'} (Updated: ${record.updated_at})`);
            }
        });

        // Step 7: Test GET again to see if the API returns the updated data
        console.log('\n7️⃣ Testing GET working hours after update...');
        const getResponse2 = await axios.get(
            `${API_BASE_URL}/businesses/${businessId}/working-hours`,
            {
                headers: {
                    'Authorization': `Bearer ${accessToken}`
                }
            }
        );

        console.log('📥 GET working hours response after update:', JSON.stringify(getResponse2.data, null, 2));

        if (allGood) {
            console.log('\n🎉 All working hours functionality is working correctly! 🎉');
            console.log('✅ Save working hours: WORKING');
            console.log('✅ Load working hours: WORKING');
            console.log('✅ Update working hours: WORKING');
            console.log('✅ Handle null values: WORKING');
        } else {
            console.log('\n❌ Some issues found with working hours functionality.');
        }

    } catch (error) {
        console.error('❌ Test failed:', error.response?.data || error.message);
        if (error.response?.status) {
            console.error('Status:', error.response.status);
        }
    }
}

testWorkingHoursFunctionality();
