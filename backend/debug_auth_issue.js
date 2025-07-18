const AWS = require('aws-sdk');
const axios = require('axios');

// Configuration
const API_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const region = 'us-east-1';
const USER_POOL_ID = 'us-east-1_bDqnKdrqo';
const CLIENT_ID = '6n752vrmqmbss6nmlg6be2nn9a';

AWS.config.update({ region });
const cognito = new AWS.CognitoIdentityServiceProvider();

async function debugAuthIssue() {
  console.log('🔍 Debugging Authentication Issue');
  console.log('================================');
  
  try {
    // Step 1: Test API health
    console.log('1️⃣ Testing API health...');
    const healthResp = await axios.get(`${API_URL}/auth/health`);
    console.log('✅ API Health:', healthResp.data);
    
    // Step 2: Test email that should exist
    const testEmail = 'ghayth.allaheebi@gmail.com';
    console.log(`\n2️⃣ Checking if ${testEmail} exists...`);
    
    const emailResp = await axios.post(`${API_URL}/auth/check-email`, {
      email: testEmail
    });
    console.log('Email check result:', emailResp.data);
    
    if (emailResp.data.exists) {
      console.log('\n3️⃣ Attempting to sign in...');
      
      // Try to sign in with known credentials
      const signInResp = await axios.post(`${API_URL}/auth/signin`, {
        email: testEmail,
        password: 'Test123!'  // Use the password you know
      });
      
      if (signInResp.data.success) {
        console.log('✅ Sign in successful!');
        console.log('Access Token:', signInResp.data.access_token.substring(0, 50) + '...');
        
        // Step 4: Test with the token
        console.log('\n4️⃣ Testing business API with token...');
        const businessResp = await axios.get(`${API_URL}/users/businesses`, {
          headers: {
            'Authorization': `Bearer ${signInResp.data.access_token}`,
            'Content-Type': 'application/json'
          }
        });
        
        console.log('✅ Business API response:', businessResp.data);
        
      } else {
        console.log('❌ Sign in failed:', signInResp.data);
      }
    }
    
  } catch (error) {
    console.error('❌ Error during debug:', {
      message: error.message,
      status: error.response?.status,
      data: error.response?.data
    });
    
    if (error.response?.status === 401) {
      console.log('\n💡 This appears to be an authentication issue.');
      console.log('Possible solutions:');
      console.log('1. Check if the user needs to confirm their email');
      console.log('2. Verify the password is correct');
      console.log('3. Check if the user account is enabled in Cognito');
    }
  }
}

debugAuthIssue();
