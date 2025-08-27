console.log('🚀 Starting WebSocket test...');

try {
    const { CognitoIdentityProviderClient, InitiateAuthCommand } = require('@aws-sdk/client-cognito-identity-provider');
    console.log('✅ AWS SDK loaded successfully');
    
    // Test basic WebSocket
    const WebSocket = require('ws');
    console.log('✅ WebSocket module loaded successfully');
    
    console.log('🔐 Testing login credentials...');
    
    const TEST_EMAIL = 'g87_a@yahoo.com';
    const TEST_PASSWORD = 'Gha@551987';
    const COGNITO_CLIENT_ID = '1tl9g7nk2k2chtj5fg960fgdth';
    const COGNITO_REGION = 'us-east-1';
    
    const cognitoClient = new CognitoIdentityProviderClient({ region: COGNITO_REGION });
    
    async function testLogin() {
        console.log('🔑 Attempting login...');
        
        try {
            const authParams = {
                AuthFlow: 'USER_PASSWORD_AUTH',
                ClientId: COGNITO_CLIENT_ID,
                AuthParameters: {
                    USERNAME: TEST_EMAIL,
                    PASSWORD: TEST_PASSWORD
                }
            };

            const command = new InitiateAuthCommand(authParams);
            const response = await cognitoClient.send(command);

            if (response.AuthenticationResult) {
                console.log('✅ Login successful!');
                console.log('🎫 Access token length:', response.AuthenticationResult.AccessToken.length);
                return response.AuthenticationResult.AccessToken;
            } else {
                console.error('❌ No authentication result');
                return null;
            }
        } catch (error) {
            console.error('❌ Login failed:', error.name, error.message);
            return null;
        }
    }
    
    testLogin().then(token => {
        if (token) {
            console.log('🎯 Authentication test completed successfully!');
            console.log('✅ Ready to test WebSocket connections');
        } else {
            console.log('❌ Authentication test failed');
        }
    }).catch(error => {
        console.error('❌ Test error:', error);
    });
    
} catch (error) {
    console.error('❌ Module loading error:', error);
}
