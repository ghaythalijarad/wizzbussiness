const AWS = require('aws-sdk');

// Test the actual environment variables and configuration
async function testCognitoConfig() {
    console.log('🔍 Testing Cognito Configuration');
    console.log('===============================');
    
    // Check environment variables (as used in Lambda)
    console.log('Environment Variables:');
    console.log('- USER_POOL_ID (env):', process.env.COGNITO_USER_POOL_ID || 'NOT SET');
    console.log('- CLIENT_ID (env):', process.env.COGNITO_CLIENT_ID || 'NOT SET');
    console.log('- COGNITO_REGION (env):', process.env.COGNITO_REGION || 'NOT SET');
    
    // Hard-coded values (as used in the script)
    const USER_POOL_ID = 'us-east-1_bDqnKdrqo';
    const CLIENT_ID = '6n752vrmqmbss6nmlg6be2nn9a';
    const EMAIL = 'g87_a@yahoo.com';
    
    console.log('');
    console.log('Hard-coded Values:');
    console.log('- USER_POOL_ID:', USER_POOL_ID);
    console.log('- CLIENT_ID:', CLIENT_ID);
    console.log('- EMAIL:', EMAIL);
    
    const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });
    
    try {
        console.log('');
        console.log('1️⃣ Testing User Pool Client Configuration...');
        
        const clientInfo = await cognito.describeUserPoolClient({
            UserPoolId: USER_POOL_ID,
            ClientId: CLIENT_ID
        }).promise();
        
        console.log('✅ Client found:', clientInfo.UserPoolClient.ClientName);
        console.log('Explicit Auth Flows:', clientInfo.UserPoolClient.ExplicitAuthFlows);
        console.log('Generate Secret:', clientInfo.UserPoolClient.GenerateSecret);
        console.log('Auth Session Validity:', clientInfo.UserPoolClient.AuthSessionValidity);
        
        // Check if USER_PASSWORD_AUTH is enabled
        const hasUserPasswordAuth = clientInfo.UserPoolClient.ExplicitAuthFlows?.includes('USER_PASSWORD_AUTH');
        console.log('USER_PASSWORD_AUTH enabled:', hasUserPasswordAuth ? '✅ YES' : '❌ NO');
        
        if (!hasUserPasswordAuth) {
            console.log('❌ ISSUE FOUND: USER_PASSWORD_AUTH is not enabled for this client!');
            console.log('This explains why login is failing.');
            console.log('Available auth flows:', clientInfo.UserPoolClient.ExplicitAuthFlows);
        }
        
    } catch (error) {
        console.log('❌ Failed to get client info:', error.message);
    }
    
    try {
        console.log('');
        console.log('2️⃣ Testing User Pool Configuration...');
        
        const poolInfo = await cognito.describeUserPool({
            UserPoolId: USER_POOL_ID
        }).promise();
        
        console.log('✅ User Pool found:', poolInfo.UserPool.Name);
        console.log('User Pool Policies:', poolInfo.UserPool.Policies);
        console.log('Auto Verified Attributes:', poolInfo.UserPool.AutoVerifiedAttributes);
        console.log('Username Attributes:', poolInfo.UserPool.UsernameAttributes);
        
    } catch (error) {
        console.log('❌ Failed to get pool info:', error.message);
    }
}

testCognitoConfig().catch(error => {
    console.error('💥 Script failed:', error.message);
});
