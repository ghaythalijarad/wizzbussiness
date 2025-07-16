const AWS = require('aws-sdk');

// Configure AWS
const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });

const USER_POOL_ID = 'us-east-1_bDqnKdrqo';
const CLIENT_ID = '6n752vrmqmbss6nmlg6be2nn9a';
const EMAIL = 'g87_a@yahoo.com';
const PASSWORD = 'Gha@551987';

async function testDirectCognitoAuth() {
    console.log('🔐 Testing Direct Cognito Authentication');
    console.log('=======================================');
    console.log(`Email: ${EMAIL}`);
    console.log(`Password: ${PASSWORD.replace(/./g, '*')}`);
    console.log('');

    try {
        // Try different auth flows
        console.log('1️⃣ Testing USER_PASSWORD_AUTH flow...');
        
        const authParams = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: CLIENT_ID,
            AuthParameters: {
                USERNAME: EMAIL,
                PASSWORD: PASSWORD
            }
        };

        console.log('Auth parameters:', {
            AuthFlow: authParams.AuthFlow,
            ClientId: authParams.ClientId,
            AuthParameters: {
                USERNAME: authParams.AuthParameters.USERNAME,
                PASSWORD: '***hidden***'
            }
        });

        const response = await cognito.initiateAuth(authParams).promise();
        
        console.log('✅ Authentication successful!');
        console.log('Challenge Name:', response.ChallengeName || 'None');
        console.log('Session:', response.Session || 'N/A');
        console.log('Auth Result:', response.AuthenticationResult ? 'Present' : 'Not present');
        
        if (response.AuthenticationResult) {
            console.log('Access Token length:', response.AuthenticationResult.AccessToken?.length || 0);
            console.log('ID Token length:', response.AuthenticationResult.IdToken?.length || 0);
            console.log('Refresh Token length:', response.AuthenticationResult.RefreshToken?.length || 0);
        }
        
    } catch (error) {
        console.log('❌ Authentication failed');
        console.log('Error Code:', error.code);
        console.log('Error Message:', error.message);
        console.log('');
        
        // Try alternative approaches
        console.log('2️⃣ Checking User Pool configuration...');
        
        try {
            const userPoolInfo = await cognito.describeUserPool({
                UserPoolId: USER_POOL_ID
            }).promise();
            
            console.log('User Pool Name:', userPoolInfo.UserPool.Name);
            console.log('Auth Flows:', userPoolInfo.UserPool.ExplicitAuthFlows);
            console.log('Password Policy:', userPoolInfo.UserPool.Policies?.PasswordPolicy);
            
        } catch (poolError) {
            console.log('❌ Failed to get User Pool info:', poolError.message);
        }
        
        console.log('');
        console.log('3️⃣ Checking User Pool Client configuration...');
        
        try {
            const clientInfo = await cognito.describeUserPoolClient({
                UserPoolId: USER_POOL_ID,
                ClientId: CLIENT_ID
            }).promise();
            
            console.log('Client Name:', clientInfo.UserPoolClient.ClientName);
            console.log('Explicit Auth Flows:', clientInfo.UserPoolClient.ExplicitAuthFlows);
            console.log('Generate Secret:', clientInfo.UserPoolClient.GenerateSecret);
            
        } catch (clientError) {
            console.log('❌ Failed to get Client info:', clientError.message);
        }
    }
}

testDirectCognitoAuth().catch(error => {
    console.error('💥 Script failed with error:');
    console.error('Error message:', error.message);
});
