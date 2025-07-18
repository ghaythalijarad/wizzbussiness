const axios = require('axios');

async function testLocationEndpoint() {
  console.log('🧪 Testing Location Settings Endpoint');
  console.log('=====================================');
  
  const API_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
  const BUSINESS_ID = '1c5eeac7-7cad-4c0c-b5c7-a538951f8caa';
  const EMAIL = 'zikbiot@yahoo.com';
  const PASSWORD = 'your-actual-password'; // Update this
  
  try {
    // Step 1: Sign in to get fresh access token
    console.log('1️⃣ Signing in...');
    const signInResponse = await axios.post(`${API_URL}/auth/signin`, {
      email: EMAIL,
      password: PASSWORD
    }, {
      headers: { 'Content-Type': 'application/json' },
      timeout: 10000
    });
    
    if (!signInResponse.data.success) {
      console.log('❌ Sign in failed:', signInResponse.data.message);
      return;
    }
    
    const accessToken = signInResponse.data.data.AccessToken;
    console.log('✅ Sign in successful');
    console.log(`📧 Token: ${accessToken.substring(0, 50)}...`);
    
    // Step 2: Test GET location settings
    console.log('\n2️⃣ Testing GET location settings...');
    try {
      const getResponse = await axios.get(
        `${API_URL}/businesses/${BUSINESS_ID}/location-settings`,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          },
          timeout: 10000
        }
      );
      
      console.log('✅ GET successful');
      console.log('📊 Current settings:', JSON.stringify(getResponse.data, null, 2));
      
    } catch (getError) {
      console.log('❌ GET failed:');
      if (getError.response) {
        console.log(`   Status: ${getError.response.status}`);
        console.log(`   Data: ${JSON.stringify(getError.response.data, null, 2)}`);
      } else {
        console.log(`   Error: ${getError.message}`);
      }
    }
    
    // Step 3: Test PUT location settings
    console.log('\n3️⃣ Testing PUT location settings...');
    const testLocation = {
      latitude: 31.997702,
      longitude: 44.349568,
      address: "شارع الإطفاء، المناذرة، نجف، Iraq",
      updated_at: new Date().toISOString()
    };
    
    try {
      const putResponse = await axios.put(
        `${API_URL}/businesses/${BUSINESS_ID}/location-settings`,
        testLocation,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          },
          timeout: 10000
        }
      );
      
      console.log('✅ PUT successful');
      console.log('📊 Updated settings:', JSON.stringify(putResponse.data, null, 2));
      
    } catch (putError) {
      console.log('❌ PUT failed:');
      if (putError.response) {
        console.log(`   Status: ${putError.response.status}`);
        console.log(`   Data: ${JSON.stringify(putError.response.data, null, 2)}`);
      } else {
        console.log(`   Error: ${putError.message}`);
      }
    }
    
  } catch (error) {
    console.log('❌ General error:', error.message);
  }
}

testLocationEndpoint();
