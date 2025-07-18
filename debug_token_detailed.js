const AWS = require('aws-sdk');
const jwt = require('jsonwebtoken');

// Test the JWT token decoding locally to see if that's the issue
async function debugToken() {
    try {
        console.log('🔍 Debugging JWT Token');
        console.log('=' .repeat(50));

        // Read the access token
        const fs = require('fs');
        const accessToken = fs.readFileSync('access_token.txt', 'utf8').trim();
        console.log('Token length:', accessToken.length);
        console.log('Token prefix:', accessToken.substring(0, 50));

        // Try to decode without verification first
        console.log('\n1. Decoding token without verification...');
        try {
            const decoded = jwt.decode(accessToken, { complete: true });
            console.log('✅ Token decoded successfully');
            console.log('Header:', decoded.header);
            console.log('Payload:', decoded.payload);
            
            // Check if token is expired
            const now = Math.floor(Date.now() / 1000);
            const exp = decoded.payload.exp;
            console.log(`Current time: ${now}, Token exp: ${exp}`);
            console.log(`Token ${exp > now ? 'is valid' : 'is EXPIRED'}`);
            
        } catch (error) {
            console.log('❌ Token decode failed:', error.message);
        }

        // Test Cognito verification
        console.log('\n2. Testing Cognito token verification...');
        try {
            AWS.config.update({ region: 'us-east-1' });
            const cognito = new AWS.CognitoIdentityServiceProvider();
            
            const params = {
                AccessToken: accessToken
            };
            
            const result = await cognito.getUser(params).promise();
            console.log('✅ Cognito verification successful');
            console.log('User attributes:', result.UserAttributes);
            
        } catch (error) {
            console.log('❌ Cognito verification failed:', error.message);
            console.log('Error code:', error.code);
        }

        // Test calling products endpoint with detailed error capture
        console.log('\n3. Testing products endpoint with detailed error capture...');
        const axios = require('axios');
        
        try {
            const response = await axios.get('https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/products', {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${accessToken}`
                },
                timeout: 30000,
                validateStatus: function (status) {
                    return true; // Don't throw on any status code
                }
            });
            
            console.log('Response status:', response.status);
            console.log('Response headers:', response.headers);
            console.log('Response data:', JSON.stringify(response.data, null, 2));
            
        } catch (error) {
            console.log('Request completely failed:', error.message);
            if (error.response) {
                console.log('Response status:', error.response.status);
                console.log('Response data:', error.response.data);
            }
        }

    } catch (error) {
        console.error('💥 Unexpected error:', error);
    }
}

debugToken();
