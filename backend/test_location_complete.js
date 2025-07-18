const axios = require('axios');

async function testLocationSettingsEndpoint() {
  console.log('🗺️  Testing Location Settings Endpoint');
  console.log('=====================================');
  
  const API_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
  const BUSINESS_ID = '1c5eeac7-7cad-4c0c-b5c7-a538951f8caa';
  const EMAIL = 'zikbiot@yahoo.com';
  const PASSWORD = 'Password123!'; // Update with correct password
  
  try {
    // Step 1: Sign in to get fresh access token
    console.log('1️⃣ Signing in...');
    const signInResponse = await axios.post(`${API_URL}/auth/signin`, {
      email: EMAIL,
      password: PASSWORD
    }, {
      headers: { 'Content-Type': 'application/json' },
      timeout: 15000
    });
    
    if (!signInResponse.data.success) {
      throw new Error(`Sign in failed: ${signInResponse.data.message}`);
    }
    
    const accessToken = signInResponse.data.data.AccessToken;
    console.log('✅ Sign in successful');
    console.log(`📧 Access token received (${accessToken.length} chars)`);
    
    // Step 2: Test location settings GET endpoint
    console.log('\n2️⃣ Testing GET location settings...');
    try {
      const getResponse = await axios.get(
        `${API_URL}/businesses/${BUSINESS_ID}/location-settings`,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          },
          timeout: 15000
        }
      );
      
      console.log('✅ GET location settings successful');
      console.log('📊 Response:', JSON.stringify(getResponse.data, null, 2));
      
    } catch (getError) {
      console.log('❌ GET location settings failed:');
      if (getError.response) {
        console.log(`   Status: ${getError.response.status}`);
        console.log(`   Data: ${JSON.stringify(getError.response.data, null, 2)}`);
      } else {
        console.log(`   Error: ${getError.message}`);
      }
    }
    
    // Step 3: Test location settings PUT endpoint with sample data
    console.log('\n3️⃣ Testing PUT location settings...');
    const testLocationData = {
      latitude: 31.997702,
      longitude: 44.349568,
      address: "شارع الإطفاء، المناذرة، نجف، Iraq"
    };
    
    try {
      const putResponse = await axios.put(
        `${API_URL}/businesses/${BUSINESS_ID}/location-settings`,
        testLocationData,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          },
          timeout: 15000
        }
      );
      
      console.log('✅ PUT location settings successful');
      console.log('📊 Response:', JSON.stringify(putResponse.data, null, 2));
      
    } catch (putError) {
      console.log('❌ PUT location settings failed:');
      if (putError.response) {
        console.log(`   Status: ${putError.response.status}`);
        console.log(`   Data: ${JSON.stringify(putError.response.data, null, 2)}`);
      } else {
        console.log(`   Error: ${putError.message}`);
      }
    }
    
  } catch (error) {
    console.log('❌ Test failed:');
    if (error.response) {
      console.log(`   Status: ${error.response.status}`);
      console.log(`   Data: ${JSON.stringify(error.response.data, null, 2)}`);
    } else {
      console.log(`   Error: ${error.message}`);
    }
  }
}

// Run the test
testLocationSettingsEndpoint()
  .then(() => {
    console.log('\n🎯 Location settings test completed');
    process.exit(0);
  })
  .catch(error => {
    console.log(`\n💥 Test failed: ${error.message}`);
    process.exit(1);
  });
