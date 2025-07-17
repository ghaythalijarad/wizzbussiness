const axios = require('axios');

const API_BASE_URL = 'https://clgs5798k1.execute-api.eu-north-1.amazonaws.com/dev';
const TEST_EMAIL = 'g87_a@outlook.com';
const TEST_PASSWORD = 'Password123!';

async function testSignIn() {
  console.log('🔐 Testing Sign In...');
  console.log(`📧 Email: ${TEST_EMAIL}`);
  console.log(`🔗 API URL: ${API_BASE_URL}`);
  
  try {
    const response = await axios.post(`${API_BASE_URL}/auth/signin`, {
      email: TEST_EMAIL,
      password: TEST_PASSWORD
    }, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });

    console.log('📊 Response Status:', response.status);
    console.log('📄 Response Data:', JSON.stringify(response.data, null, 2));
    
    if (response.data.success && response.data.access_token) {
      console.log('✅ Sign in successful!');
      return response.data.access_token;
    } else {
      console.log('❌ Sign in failed:', response.data.message);
      return null;
    }
  } catch (error) {
    console.log('❌ Sign in error:', error.message);
    if (error.response) {
      console.log('   Status:', error.response.status);
      console.log('   Data:', JSON.stringify(error.response.data, null, 2));
    }
    return null;
  }
}

testSignIn();
