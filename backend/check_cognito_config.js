const AWS = require('aws-sdk');

const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });

const USER_POOL_ID = 'us-east-1_bDqnKdrqo';
const CLIENT_ID = '6n752vrmqmbss6nmlg6be2nn9a';

async function checkCognitoConfig() {
    console.log('🔍 Checking Cognito Configuration');
    console.log('================================');
    
    try {
        // Check User Pool configuration
        console.log('1️⃣ Checking User Pool...');
        const userPool = await cognito.describeUserPool({
            UserPoolId: USER_POOL_ID
        }).promise();
        
        console.log('✅ User Pool found');
        console.log('Name:', userPool.UserPool.Name);
        console.log('Policies:', JSON.stringify(userPool.UserPool.Policies, null, 2));
        console.log('Auto Verified Attributes:', userPool.UserPool.AutoVerifiedAttributes);
        console.log('Username Attributes:', userPool.UserPool.UsernameAttributes);
        console.log('');
        
        // Check Client configuration
        console.log('2️⃣ Checking User Pool Client...');
        const client = await cognito.describeUserPoolClient({
            UserPoolId: USER_POOL_ID,
            ClientId: CLIENT_ID
        }).promise();
        
        console.log('✅ Client found');
        console.log('Client Name:', client.UserPoolClient.ClientName);
        console.log('Generate Secret:', client.UserPoolClient.GenerateSecret);
        console.log('Explicit Auth Flows:', client.UserPoolClient.ExplicitAuthFlows);
        console.log('Supported Identity Providers:', client.UserPoolClient.SupportedIdentityProviders);
        console.log('');
        
        // Check if USER_PASSWORD_AUTH is enabled
        const hasUserPasswordAuth = client.UserPoolClient.ExplicitAuthFlows?.includes('USER_PASSWORD_AUTH');
        console.log('3️⃣ Authentication Flow Check');
        console.log('USER_PASSWORD_AUTH enabled:', hasUserPasswordAuth);
        
        if (!hasUserPasswordAuth) {
            console.log('❌ USER_PASSWORD_AUTH is not enabled!');
            console.log('This is likely the cause of login failures.');
            console.log('');
            console.log('To fix this, you need to enable USER_PASSWORD_AUTH in the client settings.');
        } else {
            console.log('✅ USER_PASSWORD_AUTH is enabled');
        }
        
    } catch (error) {
        console.log('❌ Error checking configuration:', error.message);
    }
}

checkCognitoConfig();
