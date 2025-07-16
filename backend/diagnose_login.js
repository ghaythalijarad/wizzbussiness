const AWS = require('aws-sdk');

const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });
const USER_POOL_ID = 'us-east-1_bDqnKdrqo';
const CLIENT_ID = '6n752vrmqmbss6nmlg6be2nn9a';

async function diagnoseLoginIssue() {
    console.log('🔍 DIAGNOSING LOGIN ISSUE');
    console.log('========================');
    
    try {
        // Step 1: Check User Pool Client configuration
        console.log('1️⃣ Checking User Pool Client Configuration...');
        const clientConfig = await cognito.describeUserPoolClient({
            UserPoolId: USER_POOL_ID,
            ClientId: CLIENT_ID
        }).promise();
        
        console.log('✅ Client Name:', clientConfig.UserPoolClient.ClientName);
        console.log('✅ Auth Flows:', clientConfig.UserPoolClient.ExplicitAuthFlows);
        console.log('✅ Generate Secret:', clientConfig.UserPoolClient.GenerateSecret);
        console.log('✅ Prevent User Existence Errors:', clientConfig.UserPoolClient.PreventUserExistenceErrors);
        
        // Check if USER_PASSWORD_AUTH is enabled
        const hasUserPasswordAuth = clientConfig.UserPoolClient.ExplicitAuthFlows.includes('USER_PASSWORD_AUTH');
        console.log('✅ USER_PASSWORD_AUTH Enabled:', hasUserPasswordAuth);
        
        if (!hasUserPasswordAuth) {
            console.log('❌ ISSUE FOUND: USER_PASSWORD_AUTH is not enabled!');
            console.log('💡 SOLUTION: Enable USER_PASSWORD_AUTH in Cognito User Pool Client settings');
            return;
        }
        
        console.log('\n2️⃣ User Pool Client Configuration: ✅ LOOKS GOOD');
        
    } catch (error) {
        console.log('❌ Error checking client config:', error.message);
    }
}

diagnoseLoginIssue().catch(console.error);
