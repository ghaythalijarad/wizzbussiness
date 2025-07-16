const AWS = require('aws-sdk');

// Test Cognito authentication directly
async function testCognitoAuth() {
    const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });
    
    const email = 'g87_a@yahoo.com';
    const password = 'Gha@551987';
    const clientId = '6n752vrmqmbss6nmlg6be2nn9a';
    
    console.log('🔍 Testing Cognito Authentication Directly...');
    console.log(`Email: ${email}`);
    console.log(`Client ID: ${clientId}`);
    
    try {
        // First, check if user exists and get user details
        console.log('\n1️⃣ Checking user status in Cognito...');
        try {
            const userResult = await cognito.adminGetUser({
                UserPoolId: 'us-east-1_bDqnKdrqo',
                Username: email
            }).promise();
            
            console.log('✅ User found in Cognito');
            console.log('User Status:', userResult.UserStatus);
            console.log('Enabled:', userResult.Enabled);
            console.log('Attributes:');
            userResult.UserAttributes.forEach(attr => {
                console.log(`  ${attr.Name}: ${attr.Value}`);
            });
        } catch (getUserError) {
            console.log('❌ Error getting user:', getUserError.code, getUserError.message);
            return;
        }
        
        // Now try to authenticate
        console.log('\n2️⃣ Attempting authentication...');
        const authParams = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: clientId,
            AuthParameters: {
                USERNAME: email,
                PASSWORD: password
            }
        };
        
        const authResult = await cognito.initiateAuth(authParams).promise();
        console.log('✅ Authentication successful!');
        console.log('Access Token Length:', authResult.AuthenticationResult.AccessToken.length);
        
    } catch (error) {
        console.log('❌ Authentication failed:', error.code, error.message);
        
        // Check for specific error codes
        if (error.code === 'NotAuthorizedException') {
            console.log('💡 This usually means incorrect password or user not confirmed');
        } else if (error.code === 'UserNotConfirmedException') {
            console.log('💡 User exists but email is not verified');
        } else if (error.code === 'UserNotFoundException') {
            console.log('💡 User does not exist in Cognito');
        }
        
        console.log('Full error:', JSON.stringify(error, null, 2));
    }
}

testCognitoAuth().catch(console.error);
