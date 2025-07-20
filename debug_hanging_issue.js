const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({
    region: 'us-east-1'
});

const cognito = new AWS.CognitoIdentityServiceProvider();

async function testAuth() {
    console.log('🔍 Testing authentication to diagnose hanging issue...');
    
    try {
        const params = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: '6n752vrmqmbss6nmlg6be2nn9a',
            AuthParameters: {
                USERNAME: 'zikbiot@yahoo.com',
                PASSWORD: 'Gha@551987'
            }
        };

        console.log('📡 Attempting authentication with timeout...');
        
        // Add timeout to prevent hanging
        const authPromise = cognito.initiateAuth(params).promise();
        const timeoutPromise = new Promise((_, reject) => 
            setTimeout(() => reject(new Error('Authentication timeout after 10 seconds')), 10000)
        );

        const result = await Promise.race([authPromise, timeoutPromise]);
        
        console.log('✅ Authentication successful!');
        console.log('Access Token (first 50 chars):', result.AuthenticationResult.AccessToken.substring(0, 50) + '...');
        
        // Save the new token
        const fs = require('fs');
        fs.writeFileSync('/Users/ghaythallaheebi/order-receiver-app-2/access_token.txt', result.AuthenticationResult.AccessToken);
        console.log('💾 New access token saved to access_token.txt');
        
        return result.AuthenticationResult.AccessToken;
        
    } catch (error) {
        console.error('❌ Authentication failed:', error.message);
        
        if (error.message.includes('timeout')) {
            console.log('🕒 Authentication is hanging - this suggests network/API Gateway issues');
        }
        
        return null;
    }
}

async function testAPIConnectivity() {
    console.log('\n🌐 Testing API Gateway connectivity...');
    
    const https = require('https');
    const url = 'https://m8jrfp6ea5.execute-api.us-east-1.amazonaws.com/prod/health';
    
    return new Promise((resolve) => {
        const req = https.get(url, { timeout: 5000 }, (res) => {
            console.log(`✅ API Gateway accessible - Status: ${res.statusCode}`);
            resolve(true);
        });
        
        req.on('timeout', () => {
            console.log('❌ API Gateway timeout - network issues detected');
            req.destroy();
            resolve(false);
        });
        
        req.on('error', (error) => {
            console.log('❌ API Gateway connection failed:', error.message);
            resolve(false);
        });
    });
}

async function main() {
    console.log('🚀 Starting diagnostic for hanging issue...\n');
    
    // Test API connectivity first
    const apiConnected = await testAPIConnectivity();
    
    if (!apiConnected) {
        console.log('\n💡 DIAGNOSIS: Network connectivity issues preventing API calls');
        console.log('   This would cause the Flutter app to hang on API requests');
        return;
    }
    
    // Test authentication
    const token = await testAuth();
    
    if (token) {
        console.log('\n✅ DIAGNOSIS: Authentication working - hanging issue resolved');
        console.log('   You can now test the Flutter app with the fresh token');
    } else {
        console.log('\n❌ DIAGNOSIS: Authentication issues persist');
        console.log('   Check AWS credentials and Cognito configuration');
    }
}

main().catch(console.error);
