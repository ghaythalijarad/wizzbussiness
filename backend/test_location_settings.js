const axios = require('axios');

// Configuration
const API_BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const TEST_BUSINESS_ID = '123e4567-e89b-12d3-a456-426614174000'; // The business ID from check_location_data.js
const TEST_EMAIL = 'g87_a@yahoo.com'; // Working email from reset script
const TEST_PASSWORD = 'NewSecure123!'; // Working password from reset script

async function testLocationSettingsEndpoints() {
  console.log('📍 Testing Location Settings Backend...\n');

  try {
    // Step 1: Sign in to get access token
    console.log('1️⃣ Signing in to get access token...');
    const loginResponse = await axios.post(
      `${API_BASE_URL}/auth/signin`,
      {
        email: TEST_EMAIL,
        password: TEST_PASSWORD
      },
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    if (!loginResponse.data.success) {
      throw new Error('Login failed: ' + loginResponse.data.message);
    }

    const accessToken = loginResponse.data.tokens.AccessToken;
    console.log('✅ Sign in successful');

    const headers = {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    };

    // Step 2: Test GET location settings (should return defaults)
    console.log('\n2️⃣ Testing GET location settings...');
    try {
      const getResponse = await axios.get(
        `${API_BASE_URL}/businesses/${TEST_BUSINESS_ID}/location-settings`,
        { headers }
      );
      console.log('✅ GET location settings successful');
      console.log('📊 Default settings:', JSON.stringify(getResponse.data.settings, null, 2));
    } catch (error) {
      console.log('❌ GET location settings failed:', error.response?.data?.message || error.message);
    }

    // Step 3: Test PUT location settings (update settings)
    console.log('\n3️⃣ Testing PUT location settings...');
    const testLocationSettings = {
      latitude: 33.3152,  // Baghdad coordinates
      longitude: 44.3661,
      address: '123 Test Street, Baghdad, Iraq',
      updated_at: new Date().toISOString()
    };

    try {
      const putResponse = await axios.put(
        `${API_BASE_URL}/businesses/${TEST_BUSINESS_ID}/location-settings`,
        testLocationSettings,
        { headers }
      );
      console.log('✅ PUT location settings successful');
      console.log('📊 Updated settings:', JSON.stringify(putResponse.data.settings, null, 2));
    } catch (error) {
      console.log('❌ PUT location settings failed:', error.response?.data?.message || error.message);
    }

    // Step 4: Test GET location settings again (should return updated values)
    console.log('\n4️⃣ Testing GET location settings after update...');
    try {
      const getResponse2 = await axios.get(
        `${API_BASE_URL}/businesses/${TEST_BUSINESS_ID}/location-settings`,
        { headers }
      );
      console.log('✅ GET location settings after update successful');
      console.log('📊 Updated settings:', JSON.stringify(getResponse2.data.settings, null, 2));
    } catch (error) {
      console.log('❌ GET location settings after update failed:', error.response?.data?.message || error.message);
    }

    // Step 5: Test invalid coordinates
    console.log('\n5️⃣ Testing invalid coordinates validation...');
    const invalidLocationSettings = {
      latitude: 999,  // Invalid latitude
      longitude: 44.3661,
      address: 'Test Address'
    };

    try {
      const invalidResponse = await axios.put(
        `${API_BASE_URL}/businesses/${TEST_BUSINESS_ID}/location-settings`,
        invalidLocationSettings,
        { headers }
      );
      console.log('❌ Invalid coordinates test failed - should have been rejected');
    } catch (error) {
      if (error.response?.status === 400) {
        console.log('✅ Invalid coordinates properly rejected:', error.response.data.message);
      } else {
        console.log('❌ Unexpected error with invalid coordinates:', error.response?.data?.message || error.message);
      }
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error('Full error:', error);
  }
}

// Instructions for running the test
console.log('📝 Location Settings Backend Test');
console.log('=================================');
console.log('');
console.log('To run this test:');
console.log('1. Replace TEST_BUSINESS_ID with a valid business ID');
console.log('2. Replace TEST_EMAIL and TEST_PASSWORD with valid credentials');
console.log('3. Ensure the business exists and user has access');
console.log('4. Run: node test_location_settings.js');
console.log('');
console.log('❗ Uncomment the line below to run the test:');
console.log('');

// Uncomment the line below to run the test
testLocationSettingsEndpoints();

module.exports = { testLocationSettingsEndpoints };
