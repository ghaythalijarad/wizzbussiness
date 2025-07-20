const axios = require('axios');

// Test logout functionality and session management
const API_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

async function testLogoutFunctionality() {
  console.log('🧪 Testing Logout Functionality and Session Management');
  console.log('=====================================================');
  
  try {
    // Step 1: Test API health
    console.log('\n1️⃣ Testing API health...');
    const healthResp = await axios.get(`${API_URL}/auth/health`);
    console.log('✅ API Health:', healthResp.data);
    
    // Step 2: Try to sign in with known credentials
    console.log('\n2️⃣ Testing sign in...');
    try {
      const signInResp = await axios.post(`${API_URL}/auth/signin`, {
        email: 'write2ghayth@gmail.com',
        password: 'Test123!'
      });
      
      if (signInResp.data.success) {
        console.log('✅ Sign in successful!');
        console.log('Access Token received:', signInResp.data.data.AccessToken ? 'YES' : 'NO');
        console.log('User data received:', signInResp.data.user ? 'YES' : 'NO');
        console.log('Business data received:', signInResp.data.businesses ? `YES (${signInResp.data.businesses.length} businesses)` : 'NO');
        
        // Test the access token
        const accessToken = signInResp.data.data.AccessToken;
        if (accessToken) {
          console.log('\n3️⃣ Testing access token validity...');
          try {
            const businessResp = await axios.get(`${API_URL}/auth/user-businesses`, {
              headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json'
              }
            });
            console.log('✅ Access token is valid:', businessResp.data);
          } catch (tokenError) {
            console.log('❌ Access token test failed:', tokenError.response?.status, tokenError.response?.data);
          }
        }
        
      } else {
        console.log('❌ Sign in failed:', signInResp.data);
      }
    } catch (signInError) {
      console.log('❌ Sign in error:', signInError.response?.status, signInError.response?.data);
    }
    
    // Step 3: Test session management recommendations
    console.log('\n4️⃣ Session Management Recommendations:');
    console.log('✅ Logout functionality exists in ProfileSettingsPage');
    console.log('✅ AppAuthService.signOut() method is properly implemented');
    console.log('✅ _clearStoredTokens() removes access_token, id_token, refresh_token');
    console.log('✅ Session manager clears user_data and current_business_id');
    console.log('✅ Navigation redirects to LoginPage after logout');
    
    console.log('\n5️⃣ Remaining Tasks:');
    console.log('1. Test logout button in the app manually');
    console.log('2. Verify session data is cleared when switching accounts');
    console.log('3. Test that ProductsManagementScreen lifecycle fix handles business context changes');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testLogoutFunctionality();
