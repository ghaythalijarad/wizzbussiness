const AWS = require('aws-sdk');
const axios = require('axios');

// Configuration
const API_BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const COGNITO_CONFIG = {
    region: 'us-east-1',
    userPoolId: 'us-east-1_bDqnKdrqo',
    clientId: '6n752vrmqmbss6nmlg6be2nn9a'
};

AWS.config.update({ region: COGNITO_CONFIG.region });
const cognito = new AWS.CognitoIdentityServiceProvider();

async function debugAuthFlow() {
    console.log('🔍 Debug Authentication Flow');
    console.log('=============================');
    
    try {
        // Step 1: Test with known working credentials
        console.log('1️⃣ Testing sign in with credentials...');
        const signInResponse = await axios.post(`${API_BASE_URL}/auth/signin`, {
            email: 'zikbiot@yahoo.com',
            password: 'Gha@551987'
        });
        
        console.log('Sign in response:', JSON.stringify(signInResponse.data, null, 2));
        
        if (signInResponse.data.success) {
            const accessToken = signInResponse.data.data?.AccessToken;
            const idToken = signInResponse.data.data?.IdToken;
            
            console.log('\n2️⃣ Testing tokens...');
            console.log(`Access Token: ${accessToken ? accessToken.substring(0, 50) + '...' : 'NOT FOUND'}`);
            console.log(`ID Token: ${idToken ? idToken.substring(0, 50) + '...' : 'NOT FOUND'}`);
            
            if (accessToken) {
                // Step 3: Test getUserBusinesses with access token
                console.log('\n3️⃣ Testing /auth/user-businesses with ACCESS token...');
                try {
                    const businessResponse = await axios.get(`${API_BASE_URL}/auth/user-businesses`, {
                        headers: {
                            'Authorization': `Bearer ${accessToken}`,
                            'Content-Type': 'application/json'
                        }
                    });
                    console.log('✅ getUserBusinesses SUCCESS:', JSON.stringify(businessResponse.data, null, 2));
                } catch (accessError) {
                    console.log('❌ getUserBusinesses with ACCESS token FAILED:', accessError.response?.status, accessError.response?.data);
                }
            }
            
            if (idToken) {
                // Step 4: Test getUserBusinesses with ID token (should fail)
                console.log('\n4️⃣ Testing /auth/user-businesses with ID token (should fail)...');
                try {
                    const businessResponse = await axios.get(`${API_BASE_URL}/auth/user-businesses`, {
                        headers: {
                            'Authorization': `Bearer ${idToken}`,
                            'Content-Type': 'application/json'
                        }
                    });
                    console.log('⚠️ getUserBusinesses with ID token unexpectedly succeeded:', businessResponse.data);
                } catch (idError) {
                    console.log('✅ getUserBusinesses with ID token correctly FAILED:', idError.response?.status, idError.response?.data);
                }
            }
            
            // Step 5: Test token validation with Cognito directly
            if (accessToken) {
                console.log('\n5️⃣ Testing direct Cognito token validation...');
                try {
                    const userResponse = await cognito.getUser({ AccessToken: accessToken }).promise();
                    console.log('✅ Cognito token validation SUCCESS');
                    console.log('User attributes:', userResponse.UserAttributes);
                } catch (cognitoError) {
                    console.log('❌ Cognito token validation FAILED:', cognitoError.code, cognitoError.message);
                }
            }
        } else {
            console.log('❌ Sign in failed:', signInResponse.data);
        }
        
    } catch (error) {
        console.log('❌ Authentication flow error:', {
            message: error.message,
            status: error.response?.status,
            data: error.response?.data
        });
    }
}

debugAuthFlow().catch(console.error);
