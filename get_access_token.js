const AWS = require('aws-sdk');
const fs = require('fs');

// Configure AWS
const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });

const CONFIG = {
    USER_POOL_ID: 'us-east-1_bDqnKdrqo',
    CLIENT_ID: '6n752vrmqmbss6nmlg6be2nn9a',
    EMAIL: 'zikbiot@yahoo.com',
    PASSWORD: 'Gha@551987'
};

async function getAccessToken() {
    try {
        console.log('🔑 Getting access token for existing user...');
        console.log(`Email: ${CONFIG.EMAIL}`);
        
        const authParams = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: CONFIG.CLIENT_ID,
            AuthParameters: {
                'USERNAME': CONFIG.EMAIL,
                'PASSWORD': CONFIG.PASSWORD
            }
        };

        const result = await cognito.initiateAuth(authParams).promise();
        
        if (result.AuthenticationResult && result.AuthenticationResult.AccessToken) {
            const accessToken = result.AuthenticationResult.AccessToken;
            const idToken = result.AuthenticationResult.IdToken;  // Capture ID token
            console.log('✅ Tokens obtained successfully!');
            console.log(`Access Token (first 50 chars): ${accessToken.substring(0, 50)}...`);
            console.log(`ID Token (first 50 chars): ${idToken.substring(0, 50)}...`);
            
            // Save tokens to files
            fs.writeFileSync('access_token.txt', accessToken);
            console.log('💾 Access token saved to access_token.txt');
            if (idToken) {
                fs.writeFileSync('id_token.txt', idToken);
                console.log('💾 ID token saved to id_token.txt');
            }
            
            return { accessToken, idToken };
        } else {
            console.log('❌ No access token in response');
            console.log('Response:', JSON.stringify(result, null, 2));
        }
    } catch (error) {
        console.log('❌ Failed to get access token:', error.message);
        if (error.code) {
            console.log(`Error Code: ${error.code}`);
        }
    }
}

// Run the function
getAccessToken();
