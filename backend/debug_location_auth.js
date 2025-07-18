const axios = require('axios');

// Configuration
const API_BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const TEST_EMAIL = `test-location-${Date.now()}@example.com`;
const TEST_PASSWORD = 'Password123!';

async function debugLocationAuth() {
  console.log('🔍 Debug Location Settings Authentication');
  console.log('=========================================');
  console.log(`📧 Email: ${TEST_EMAIL}`);
  console.log(`🔗 API URL: ${API_BASE_URL}`);
  console.log('');

  try {
    // Step 1: Check if email is available
    console.log('1️⃣ Checking email availability...');
    const checkEmailResponse = await axios.post(`${API_BASE_URL}/auth/check-email`, {
      email: TEST_EMAIL
    });
    console.log('✅ Email check successful:', checkEmailResponse.data);

    // Step 2: Register new user
    console.log('\n2️⃣ Registering new test user...');
    const registerResponse = await axios.post(`${API_BASE_URL}/auth/register-with-business`, {
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
      businessName: 'Test Location Business',
      businessType: 'restaurant',
      firstName: 'Test',
      lastName: 'User',
      phoneNumber: '+1234567890',
      address: '123 Test Street',
      city: 'Test City',
      country: 'Iraq'
    });
    console.log('✅ Registration successful:', registerResponse.data);

    const userSub = registerResponse.data.user_sub;
    const businessId = registerResponse.data.business_id;

    // Step 3: Test sign in (this will require manual email confirmation first)
    console.log('\n3️⃣ Testing sign in (will likely fail due to unconfirmed email)...');
    try {
      const signInResponse = await axios.post(`${API_BASE_URL}/auth/signin`, {
        email: TEST_EMAIL,
        password: TEST_PASSWORD
      });
      console.log('✅ Sign in successful:', signInResponse.data);
      
      const accessToken = signInResponse.data.data?.AccessToken || signInResponse.data.access_token;
      
      if (accessToken) {
        // Step 4: Test location settings endpoint
        console.log('\n4️⃣ Testing location settings endpoint...');
        const headers = {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`
        };

        const locationResponse = await axios.get(
          `${API_BASE_URL}/businesses/${businessId}/location-settings`,
          { headers }
        );
        console.log('✅ Location settings GET successful:', locationResponse.data);

        // Step 5: Test updating location settings
        console.log('\n5️⃣ Testing location settings update...');
        const updateResponse = await axios.put(
          `${API_BASE_URL}/businesses/${businessId}/location-settings`,
          {
            latitude: 33.3152,
            longitude: 44.3661,
            address: 'Baghdad, Iraq'
          },
          { headers }
        );
        console.log('✅ Location settings UPDATE successful:', updateResponse.data);
      }
      
    } catch (signInError) {
      console.log('❌ Sign in failed (expected if email not confirmed):', signInError.response?.data || signInError.message);
      console.log('\n📝 To complete testing:');
      console.log('1. Check email for verification code');
      console.log(`2. Run: node confirm_test_user.js "${TEST_EMAIL}" "VERIFICATION_CODE"`);
      console.log('3. Then retry sign in and location settings');
    }

  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

// Export for potential reuse
module.exports = { debugLocationAuth, TEST_EMAIL, TEST_PASSWORD };

// Run if called directly
if (require.main === module) {
  debugLocationAuth();
}
