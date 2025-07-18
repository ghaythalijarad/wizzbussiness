const axios = require('axios');

// Configuration
const API_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

async function quickAuthTest() {
  console.log('🚀 Quick Authentication Test');
  console.log('===========================');
  
  try {
    // Test 1: API Health Check
    console.log('\n1️⃣ Testing API Health...');
    const healthResp = await axios.get(`${API_URL}/auth/health`, { timeout: 5000 });
    console.log('✅ Health Status:', healthResp.status, healthResp.data);
    
    // Test 2: Try signing in with test credentials
    console.log('\n2️⃣ Testing Sign In...');
    const signInResp = await axios.post(`${API_URL}/auth/signin`, {
      email: 'test@example.com',
      password: 'TestPassword123!'
    }, { 
      timeout: 10000,
      headers: { 'Content-Type': 'application/json' }
    });
    
    console.log('✅ Sign In Response:', signInResp.status, signInResp.data);
    
  } catch (error) {
    console.log('❌ Error occurred:');
    if (error.response) {
      console.log('   Status:', error.response.status);
      console.log('   Data:', error.response.data);
    } else if (error.code === 'ECONNABORTED') {
      console.log('   Request timed out');
    } else {
      console.log('   Error:', error.message);
    }
  }
}

// Run the test
quickAuthTest().then(() => {
  console.log('\n✅ Test completed');
  process.exit(0);
}).catch(error => {
  console.log('\n❌ Test failed:', error.message);
  process.exit(1);
});
