const AWS = require('aws-sdk');
const fetch = require('node-fetch');

// Configure AWS Cognito
const cognito = new AWS.CognitoIdentityServiceProvider({
  region: 'us-east-1',
});

async function testWithToken() {
  const email = 'g87_a@yahoo.com';
  const password = 'Gha@551987';
  const userPoolId = 'us-east-1_bDqnKdrqo';
  const clientId = '6n752vrmqmbss6nmlg6be2nn9a';

  try {
    // Get Cognito token
    const authParams = {
      AuthFlow: 'USER_PASSWORD_AUTH',
      ClientId: clientId,
      AuthParameters: {
        USERNAME: email,
        PASSWORD: password,
      },
    };

    const authResult = await cognito.initiateAuth(authParams).promise();
    const idToken = authResult.AuthenticationResult.IdToken;
    const accessToken = authResult.AuthenticationResult.AccessToken;

    console.log('✅ Got tokens from Cognito');

    // Test different endpoints
    const baseUrl = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
    const endpoints = [
      '/auth/login',
      '/login',
      '/auth',
      '/users/login',
      '/api/auth/login',
      '/business/login'
    ];

    for (const endpoint of endpoints) {
      console.log(`\n🔍 Testing ${baseUrl}${endpoint}`);
      
      // Test without auth
      try {
        const response1 = await fetch(`${baseUrl}${endpoint}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            email: email,
            password: password
          })
        });
        
        console.log(`Without auth - Status: ${response1.status}`);
        if (response1.status !== 403) {
          const data = await response1.text();
          console.log(`Response: ${data.substring(0, 200)}`);
        }
      } catch (error) {
        console.log(`Without auth - Error: ${error.message}`);
      }

      // Test with ID token
      try {
        const response2 = await fetch(`${baseUrl}${endpoint}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${idToken}`
          },
          body: JSON.stringify({
            email: email,
            password: password
          })
        });
        
        console.log(`With ID token - Status: ${response2.status}`);
        if (response2.status !== 403) {
          const data = await response2.text();
          console.log(`Response: ${data.substring(0, 200)}`);
        }
      } catch (error) {
        console.log(`With ID token - Error: ${error.message}`);
      }

      // Test with Access token
      try {
        const response3 = await fetch(`${baseUrl}${endpoint}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken}`
          },
          body: JSON.stringify({
            email: email,
            password: password
          })
        });
        
        console.log(`With Access token - Status: ${response3.status}`);
        if (response3.status !== 403) {
          const data = await response3.text();
          console.log(`Response: ${data.substring(0, 200)}`);
        }
      } catch (error) {
        console.log(`With Access token - Error: ${error.message}`);
      }
    }

    // Let's also test some GET endpoints to see what's available
    console.log('\n🔍 Testing GET endpoints to see what exists...');
    const getEndpoints = [
      '/',
      '/health',
      '/status',
      '/business',
      '/users'
    ];

    for (const endpoint of getEndpoints) {
      try {
        const response = await fetch(`${baseUrl}${endpoint}`, {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${idToken}`
          }
        });
        
        console.log(`GET ${endpoint} - Status: ${response.status}`);
        if (response.status !== 403 && response.status !== 404) {
          const data = await response.text();
          console.log(`Response: ${data.substring(0, 200)}`);
        }
      } catch (error) {
        console.log(`GET ${endpoint} - Error: ${error.message}`);
      }
    }

  } catch (error) {
    console.log('Error:', error.message);
  }
}

testWithToken();
