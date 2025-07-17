const axios = require('axios');

// Configuration
const API_BASE_URL = 'https://clgs5798k1.execute-api.eu-north-1.amazonaws.com/dev';
const TEST_BUSINESS_ID = 'test-business-123';

// Test credentials - these should be valid user credentials
const TEST_EMAIL = 'admin@wizz.com';
const TEST_PASSWORD = 'TempPassword123!';

async function testPosSettingsEndpoints() {
  console.log('🧪 Testing POS Settings Backend Endpoints');
  console.log('=' .repeat(50));

  try {
    // Step 1: Sign in to get access token
    console.log('🔐 Step 1: Signing in to get access token...');
    const signInResponse = await axios.post(`${API_BASE_URL}/auth/signin`, {
      email: TEST_EMAIL,
      password: TEST_PASSWORD
    });

    if (!signInResponse.data.success) {
      throw new Error(`Sign in failed: ${signInResponse.data.message}`);
    }

    const accessToken = signInResponse.data.access_token;
    console.log('✅ Successfully signed in and got access token');

    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`
    };

    // Step 2: Test GET POS settings (should return default settings)
    console.log('\n📥 Step 2: Testing GET POS settings...');
    try {
      const getResponse = await axios.get(
        `${API_BASE_URL}/businesses/${TEST_BUSINESS_ID}/pos-settings`,
        { headers }
      );
      console.log('✅ GET POS settings successful');
      console.log('📊 Default settings received:', JSON.stringify(getResponse.data.settings, null, 2));
    } catch (error) {
      console.log('❌ GET POS settings failed:', error.response?.data?.message || error.message);
    }

    // Step 3: Test PUT POS settings (update settings)
    console.log('\n📤 Step 3: Testing PUT POS settings...');
    const testSettings = {
      apiEndpoint: 'https://api.test-pos.com',
      apiKey: 'test-api-key-123',
      systemType: 'square',
      enabled: true,
      businessName: 'Test Restaurant',
      businessAddress: '123 Test Street, Test City',
      businessPhone: '+1-555-123-4567',
      autoPrintReceipts: true,
      printerEnabled: true,
      currency: 'USD',
      taxRate: 8.5
    };

    try {
      const putResponse = await axios.put(
        `${API_BASE_URL}/businesses/${TEST_BUSINESS_ID}/pos-settings`,
        testSettings,
        { headers }
      );
      console.log('✅ PUT POS settings successful');
      console.log('📊 Updated settings:', JSON.stringify(putResponse.data.settings, null, 2));
    } catch (error) {
      console.log('❌ PUT POS settings failed:', error.response?.data?.message || error.message);
    }

    // Step 4: Test connection testing
    console.log('\n🔗 Step 4: Testing POS connection test...');
    const testConfig = {
      system_type: 'genericApi',
      api_endpoint: 'https://httpbin.org/status/200',
      api_key: 'test-key'
    };

    try {
      const testResponse = await axios.post(
        `${API_BASE_URL}/businesses/${TEST_BUSINESS_ID}/pos-settings/test-connection`,
        testConfig,
        { headers }
      );
      console.log('✅ Connection test successful');
      console.log('📊 Test result:', JSON.stringify(testResponse.data, null, 2));
    } catch (error) {
      console.log('❌ Connection test failed:', error.response?.data?.message || error.message);
    }

    // Step 5: Test sync logs retrieval
    console.log('\n📋 Step 5: Testing sync logs retrieval...');
    try {
      const logsResponse = await axios.get(
        `${API_BASE_URL}/businesses/${TEST_BUSINESS_ID}/pos-settings/sync-logs`,
        { headers }
      );
      console.log('✅ Sync logs retrieval successful');
      console.log('📊 Logs count:', logsResponse.data.logs?.length || 0);
    } catch (error) {
      console.log('❌ Sync logs retrieval failed:', error.response?.data?.message || error.message);
    }

    console.log('\n🎉 POS Settings Backend Test Complete!');

  } catch (error) {
    console.error('💥 Test failed with error:', error.message);
    if (error.response) {
      console.error('📄 Response data:', error.response.data);
      console.error('📊 Response status:', error.response.status);
    }
  }
}

// Run the test
if (require.main === module) {
  testPosSettingsEndpoints();
}

module.exports = { testPosSettingsEndpoints };
