const AWS = require('aws-sdk');

// Configure AWS Cognito
const cognito = new AWS.CognitoIdentityServiceProvider({
  region: 'us-east-1',
});

async function testLogin() {
  const email = 'g87_a@yahoo.com';
  const password = 'Gha@551987';
  const userPoolId = 'us-east-1_bDqnKdrqo';
  const clientId = '6n752vrmqmbss6nmlg6be2nn9a';

  console.log('🔍 Testing login with provided credentials...');
  console.log(`Email: ${email}`);
  console.log(`User Pool ID: ${userPoolId}`);
  console.log(`Client ID: ${clientId}`);

  try {
    // First, try to authenticate with Cognito
    const authParams = {
      AuthFlow: 'USER_PASSWORD_AUTH',
      ClientId: clientId,
      AuthParameters: {
        USERNAME: email,
        PASSWORD: password,
      },
    };

    console.log('\n📡 Attempting Cognito authentication...');
    const authResult = await cognito.initiateAuth(authParams).promise();
    
    if (authResult.AuthenticationResult) {
      console.log('✅ Cognito authentication successful!');
      console.log('Access Token:', authResult.AuthenticationResult.AccessToken.substring(0, 50) + '...');
      console.log('ID Token:', authResult.AuthenticationResult.IdToken.substring(0, 50) + '...');
      
      // Now test the backend API
      const apiUrl = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/auth/login';
      
      console.log('\n📡 Testing backend API login...');
      const fetch = require('node-fetch');
      
      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: email,
          password: password
        })
      });

      const responseData = await response.json();
      
      if (response.ok) {
        console.log('✅ Backend API login successful!');
        console.log('Response:', JSON.stringify(responseData, null, 2));
      } else {
        console.log('❌ Backend API login failed');
        console.log('Status:', response.status);
        console.log('Response:', JSON.stringify(responseData, null, 2));
      }
      
    } else if (authResult.ChallengeName) {
      console.log('⚠️ Authentication requires challenge:', authResult.ChallengeName);
      console.log('Challenge Parameters:', authResult.ChallengeParameters);
    }

  } catch (error) {
    console.log('❌ Authentication failed');
    console.log('Error Code:', error.code);
    console.log('Error Message:', error.message);
    
    if (error.code === 'UserNotConfirmedException') {
      console.log('🔍 User account is not confirmed. Checking confirmation status...');
      
      try {
        const userParams = {
          UserPoolId: userPoolId,
          Username: email
        };
        
        const userInfo = await cognito.adminGetUser(userParams).promise();
        console.log('User Status:', userInfo.UserStatus);
        console.log('User Attributes:', userInfo.UserAttributes);
      } catch (userError) {
        console.log('Error getting user info:', userError.message);
      }
    }
  }
}

// Install node-fetch if not available
async function installDependencies() {
  const { exec } = require('child_process');
  const util = require('util');
  const execAsync = util.promisify(exec);
  
  try {
    await execAsync('npm list node-fetch', { cwd: __dirname });
  } catch (error) {
    console.log('Installing node-fetch...');
    await execAsync('npm install node-fetch@2', { cwd: __dirname });
  }
}

async function main() {
  try {
    await installDependencies();
    await testLogin();
  } catch (error) {
    console.log('Script error:', error.message);
  }
}

main();
