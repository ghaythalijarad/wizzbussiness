const axios = require('axios');

// Configuration from the successful login
const API_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const BUSINESS_ID = '1c5eeac7-7cad-4c0c-b5c7-a538951f8caa';

async function testLocationSettings() {
  console.log('🗺️ Testing Location Settings Access');
  console.log('==================================');
  console.log(`Business ID: ${BUSINESS_ID}`);
  
  try {
    // First, try to sign in to get a fresh token
    console.log('\n1️⃣ Signing in to get fresh token...');
    const signInResp = await axios.post(`${API_URL}/auth/signin`, {
      email: 'zikbiot@yahoo.com',
      password: 'Password123!' // You may need to use the correct password
    }, { 
      timeout: 10000,
      headers: { 'Content-Type': 'application/json' }
    });
    
    if (signInResp.data.success) {
      console.log('✅ Sign in successful');
      const accessToken = signInResp.data.data.AccessToken;
      console.log('📧 Token length:', accessToken.length);
      
      // Test location settings GET
      console.log('\n2️⃣ Testing location settings GET...');
      const locationResp = await axios.get(`${API_URL}/businesses/${BUSINESS_ID}/location-settings`, {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        },
        timeout: 10000
      });
      
      console.log('✅ Location settings response:', locationResp.status, locationResp.data);
      
    } else {
      console.log('❌ Sign in failed:', signInResp.data);
    }
    
  } catch (error) {
    console.log('❌ Error occurred:');
    if (error.response) {
      console.log('   Status:', error.response.status);
      console.log('   Data:', JSON.stringify(error.response.data, null, 2));
    } else if (error.code === 'ECONNABORTED') {
      console.log('   Request timed out');
    } else {
      console.log('   Error:', error.message);
    }
  }
}

// Run the test
testLocationSettings().then(() => {
  console.log('\n✅ Test completed');
  process.exit(0);
}).catch(error => {
  console.log('\n❌ Test failed:', error.message);
  process.exit(1);
});
