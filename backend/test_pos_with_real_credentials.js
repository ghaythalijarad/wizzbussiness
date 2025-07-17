const axios = require('axios');

// API Configuration
const API_BASE_URL = 'https://clgs5798k1.execute-api.eu-north-1.amazonaws.com/dev';

// Test credentials
const TEST_EMAIL = 'g87_a@outlook.com';
const TEST_PASSWORD = 'Password123!';

// Test POS settings data
const TEST_POS_SETTINGS = {
  systemType: 'square',
  apiSettings: {
    apiUrl: 'https://connect.squareup.com',
    apiKey: 'test-api-key-12345',
    apiSecret: 'test-api-secret-67890',
    accessToken: 'test-access-token-abcdef',
    refreshToken: 'test-refresh-token-ghijkl',
    environment: 'sandbox'
  },
  receiptSettings: {
    showBusinessLogo: true,
    businessName: 'Test Restaurant',
    businessAddress: '123 Test Street, Test City, TC 12345',
    businessPhone: '+1-555-123-4567',
    footerMessage: 'Thank you for dining with us!',
    showOrderNumber: true,
    showQrCode: true
  },
  printerSettings: {
    printerType: 'thermal',
    printerIp: '192.168.1.100',
    printerPort: 9100,
    paperWidth: 80,
    enableAutoCut: true,
    printCopies: 1
  }
};

async function testPosSettingsWithRealCredentials() {
  console.log('🧪 Testing POS Settings with Real Credentials');
  console.log('================================================');
  console.log(`📧 Email: ${TEST_EMAIL}`);
  console.log(`🔗 API URL: ${API_BASE_URL}`);
  console.log('');

  let accessToken = null;
  let businessId = null;

  try {
    // Step 1: Sign in to get access token
    console.log('🔐 Step 1: Signing in...');
    const signInResponse = await axios.post(`${API_BASE_URL}/auth/signin`, {
      email: TEST_EMAIL,
      password: TEST_PASSWORD
    }, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });

    if (signInResponse.data.success) {
      accessToken = signInResponse.data.access_token;
      console.log('✅ Successfully signed in');
      console.log(`🎫 Access token: ${accessToken.substring(0, 20)}...`);
      
      // Try to extract business_id from the token payload (if it's a JWT)
      try {
        const tokenParts = accessToken.split('.');
        if (tokenParts.length === 3) {
          const payload = JSON.parse(Buffer.from(tokenParts[1], 'base64').toString());
          businessId = payload.business_id || payload['custom:business_id'] || payload.sub;
          console.log(`🏢 Business ID from token: ${businessId}`);
        }
      } catch (e) {
        console.log('⚠️  Could not decode token, will use a test business ID');
        businessId = 'test-business-123';
      }
    } else {
      throw new Error(`Sign in failed: ${signInResponse.data.message}`);
    }

    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`
    };

    // Step 2: Test GET POS settings (should return default settings)
    console.log('\n📥 Step 2: Testing GET POS settings...');
    try {
      const getResponse = await axios.get(
        `${API_BASE_URL}/businesses/${businessId}/pos-settings`,
        { headers, timeout: 10000 }
      );
      
      if (getResponse.data.success) {
        console.log('✅ GET POS settings successful');
        console.log('📊 Current settings:');
        console.log(JSON.stringify(getResponse.data.settings, null, 2));
      } else {
        console.log('❌ GET POS settings failed:', getResponse.data.message);
      }
    } catch (error) {
      console.log('❌ GET POS settings error:');
      if (error.response) {
        console.log(`   Status: ${error.response.status}`);
        console.log(`   Message: ${JSON.stringify(error.response.data, null, 2)}`);
      } else {
        console.log(`   Error: ${error.message}`);
      }
    }

    // Step 3: Test PUT POS settings (update settings)
    console.log('\n📤 Step 3: Testing PUT POS settings...');
    try {
      const putResponse = await axios.put(
        `${API_BASE_URL}/businesses/${businessId}/pos-settings`,
        TEST_POS_SETTINGS,
        { headers, timeout: 10000 }
      );
      
      if (putResponse.data.success) {
        console.log('✅ PUT POS settings successful');
        console.log('📝 Updated settings:');
        console.log(JSON.stringify(putResponse.data.settings, null, 2));
      } else {
        console.log('❌ PUT POS settings failed:', putResponse.data.message);
      }
    } catch (error) {
      console.log('❌ PUT POS settings error:');
      if (error.response) {
        console.log(`   Status: ${error.response.status}`);
        console.log(`   Message: ${JSON.stringify(error.response.data, null, 2)}`);
      } else {
        console.log(`   Error: ${error.message}`);
      }
    }

    // Step 4: Test connection
    console.log('\n🔌 Step 4: Testing POS connection...');
    try {
      const testResponse = await axios.post(
        `${API_BASE_URL}/businesses/${businessId}/pos-settings/test-connection`,
        {},
        { headers, timeout: 15000 }
      );
      
      if (testResponse.data.success) {
        console.log('✅ Connection test successful');
        console.log('🔗 Connection result:');
        console.log(JSON.stringify(testResponse.data, null, 2));
      } else {
        console.log('❌ Connection test failed:', testResponse.data.message);
      }
    } catch (error) {
      console.log('❌ Connection test error:');
      if (error.response) {
        console.log(`   Status: ${error.response.status}`);
        console.log(`   Message: ${JSON.stringify(error.response.data, null, 2)}`);
      } else {
        console.log(`   Error: ${error.message}`);
      }
    }

    // Step 5: Get sync logs
    console.log('\n📋 Step 5: Testing GET sync logs...');
    try {
      const logsResponse = await axios.get(
        `${API_BASE_URL}/businesses/${businessId}/pos-settings/sync-logs`,
        { headers, timeout: 10000 }
      );
      
      if (logsResponse.data.success) {
        console.log('✅ GET sync logs successful');
        console.log(`📊 Found ${logsResponse.data.logs.length} logs`);
        if (logsResponse.data.logs.length > 0) {
          console.log('📝 Recent logs:');
          console.log(JSON.stringify(logsResponse.data.logs.slice(0, 3), null, 2));
        }
      } else {
        console.log('❌ GET sync logs failed:', logsResponse.data.message);
      }
    } catch (error) {
      console.log('❌ GET sync logs error:');
      if (error.response) {
        console.log(`   Status: ${error.response.status}`);
        console.log(`   Message: ${JSON.stringify(error.response.data, null, 2)}`);
      } else {
        console.log(`   Error: ${error.message}`);
      }
    }

    // Step 6: Test different POS systems
    console.log('\n🔄 Step 6: Testing different POS systems...');
    
    const posSystemsToTest = [
      { name: 'Toast', systemType: 'toast' },
      { name: 'Clover', systemType: 'clover' },
      { name: 'Generic API', systemType: 'genericApi' }
    ];

    for (const posSystem of posSystemsToTest) {
      console.log(`\n   Testing ${posSystem.name} POS...`);
      try {
        const testSystemSettings = {
          ...TEST_POS_SETTINGS,
          systemType: posSystem.systemType
        };

        const updateResponse = await axios.put(
          `${API_BASE_URL}/businesses/${businessId}/pos-settings`,
          testSystemSettings,
          { headers, timeout: 10000 }
        );

        if (updateResponse.data.success) {
          console.log(`   ✅ ${posSystem.name} settings updated successfully`);
          
          // Test connection for this system
          const testConnResponse = await axios.post(
            `${API_BASE_URL}/businesses/${businessId}/pos-settings/test-connection`,
            {},
            { headers, timeout: 15000 }
          );
          
          if (testConnResponse.data.success) {
            console.log(`   ✅ ${posSystem.name} connection test completed`);
          } else {
            console.log(`   ⚠️  ${posSystem.name} connection test: ${testConnResponse.data.message}`);
          }
        } else {
          console.log(`   ❌ ${posSystem.name} settings update failed: ${updateResponse.data.message}`);
        }
      } catch (error) {
        console.log(`   ❌ ${posSystem.name} test error: ${error.response?.data?.message || error.message}`);
      }
    }

  } catch (error) {
    console.error('🚨 Test Suite Error:', error.message);
    if (error.response) {
      console.error('Response data:', error.response.data);
    }
  }

  console.log('\n🏁 POS Settings Test Suite Completed');
  console.log('==================================');
}

// Run the test
testPosSettingsWithRealCredentials();
