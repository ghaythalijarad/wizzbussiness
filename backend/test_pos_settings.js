const axios = require('axios');

// Test configuration
const BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const BUSINESS_ID = 'test-business-id'; // Replace with actual business ID
const AUTH_TOKEN = 'Bearer YOUR_JWT_TOKEN'; // Replace with actual JWT token

async function testPosSettings() {
  console.log('🔧 Testing POS Settings Backend...\n');

  try {
    // Test 1: Get POS Settings (should return defaults)
    console.log('1️⃣ Testing GET POS Settings...');
    try {
      const getResponse = await axios.get(
        `${BASE_URL}/businesses/${BUSINESS_ID}/pos-settings`,
        {
          headers: {
            'Authorization': AUTH_TOKEN,
            'Content-Type': 'application/json'
          }
        }
      );
      console.log('✅ GET POS Settings successful');
      console.log('Settings:', JSON.stringify(getResponse.data.settings, null, 2));
    } catch (error) {
      console.log('❌ GET POS Settings failed:', error.response?.data || error.message);
    }

    // Test 2: Update POS Settings
    console.log('\n2️⃣ Testing PUT POS Settings...');
    const testSettings = {
      // API Settings
      apiEndpoint: 'https://api.example-pos.com',
      apiKey: 'test-api-key-12345',
      accessToken: 'test-access-token',
      locationId: 'location-123',
      systemType: 'square',
      enabled: true,
      testMode: true,
      
      // Order Settings
      autoSendOrders: true,
      autoAcceptOrders: false,
      timeoutSeconds: 45,
      orderNotificationSound: true,
      displayOrderTimer: true,
      maxProcessingTimeMinutes: 45,
      retryAttempts: 5,
      
      // Financial Settings
      currency: 'EUR',
      taxRate: 0.19,
      serviceChargeRate: 0.05,
      
      // Receipt Settings
      businessName: 'Test Restaurant',
      businessAddress: '123 Main St, Test City',
      businessPhone: '+1-555-123-4567',
      showLogo: true,
      showQrCode: false,
      footerMessage: 'Thank you for dining with us!',
      paperSize: 'A4',
      
      // Printer Settings
      printerEnabled: true,
      printerName: 'Kitchen Printer',
      printerIp: '192.168.1.100',
      autoPrintReceipts: true,
      printKitchenOrders: true
    };

    try {
      const updateResponse = await axios.put(
        `${BASE_URL}/businesses/${BUSINESS_ID}/pos-settings`,
        testSettings,
        {
          headers: {
            'Authorization': AUTH_TOKEN,
            'Content-Type': 'application/json'
          }
        }
      );
      console.log('✅ PUT POS Settings successful');
      console.log('Response:', updateResponse.data.message);
    } catch (error) {
      console.log('❌ PUT POS Settings failed:', error.response?.data || error.message);
    }

    // Test 3: Test Connection
    console.log('\n3️⃣ Testing Connection Test...');
    const connectionConfig = {
      system_type: 'square',
      api_endpoint: 'https://connect.squareupsandbox.com',
      api_key: 'test-api-key',
      access_token: 'test-access-token',
      location_id: 'test-location-id'
    };

    try {
      const testResponse = await axios.post(
        `${BASE_URL}/businesses/${BUSINESS_ID}/pos-settings/test-connection`,
        connectionConfig,
        {
          headers: {
            'Authorization': AUTH_TOKEN,
            'Content-Type': 'application/json'
          }
        }
      );
      console.log('✅ Connection test completed');
      console.log('Result:', testResponse.data);
    } catch (error) {
      console.log('❌ Connection test failed:', error.response?.data || error.message);
    }

    // Test 4: Get Sync Logs
    console.log('\n4️⃣ Testing GET Sync Logs...');
    try {
      const logsResponse = await axios.get(
        `${BASE_URL}/businesses/${BUSINESS_ID}/pos-settings/sync-logs`,
        {
          headers: {
            'Authorization': AUTH_TOKEN,
            'Content-Type': 'application/json'
          }
        }
      );
      console.log('✅ GET Sync Logs successful');
      console.log('Logs count:', logsResponse.data.logs?.length || 0);
    } catch (error) {
      console.log('❌ GET Sync Logs failed:', error.response?.data || error.message);
    }

  } catch (error) {
    console.error('❌ Overall test failed:', error.message);
  }
}

// Instructions for running the test
console.log('📝 POS Settings Backend Test');
console.log('==========================');
console.log('');
console.log('To run this test:');
console.log('1. Replace BUSINESS_ID with a valid business ID');
console.log('2. Replace AUTH_TOKEN with a valid JWT token');
console.log('3. Ensure the business exists and user has access');
console.log('4. Run: node test_pos_settings.js');
console.log('');
console.log('❗ Uncomment the line below to run the test:');
console.log('');

// Uncomment the line below to run the test
// testPosSettings();

module.exports = { testPosSettings };
