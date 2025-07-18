const AWS = require('aws-sdk');
const axios = require('axios');
const fs = require('fs');

// Configuration
const baseUrl = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const cognitoConfig = {
    UserPoolId: 'us-east-1_bDqnKdrqo',
    ClientId: '6n752vrmqmbss6nmlg6be2nn9a',
    region: 'us-east-1'
};

// Login credentials
const credentials = {
    email: 'zikbiot@yahoo.com',
    password: 'Gha@551987'
};

async function loginAndDebug() {
    try {
        console.log('🔐 Logging in with credentials...');
        console.log('=' .repeat(50));
        console.log('Email:', credentials.email);
        console.log('Region:', cognitoConfig.region);
        console.log('UserPoolId:', cognitoConfig.UserPoolId);
        console.log('ClientId:', cognitoConfig.ClientId);

        // Initialize Cognito client
        console.log('Initializing AWS Cognito client...');
        AWS.config.update({ region: cognitoConfig.region });
        const cognito = new AWS.CognitoIdentityServiceProvider();
        console.log('Cognito client initialized');

        // Step 1: Login to get tokens
        console.log('1. Attempting login...');
        const loginParams = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: cognitoConfig.ClientId,
            AuthParameters: {
                USERNAME: credentials.email,
                PASSWORD: credentials.password
            }
        };

        const loginResult = await cognito.initiateAuth(loginParams).promise();
        
        if (loginResult.AuthenticationResult) {
            const accessToken = loginResult.AuthenticationResult.AccessToken;
            const idToken = loginResult.AuthenticationResult.IdToken;
            const refreshToken = loginResult.AuthenticationResult.RefreshToken;

            console.log('✅ Login successful!');
            console.log(`📝 Access Token: ${accessToken.substring(0, 50)}...`);
            
            // Save the access token
            fs.writeFileSync('access_token.txt', accessToken);
            console.log('💾 Access token saved to access_token.txt');

            // Step 2: Test the products endpoint
            console.log('\n2. Testing product management endpoints...');
            
            const authHeader = `Bearer ${accessToken}`;
            
            // Test GET /products
            console.log('\n   Testing GET /products...');
            try {
                const productsResponse = await axios.get(`${baseUrl}/products`, {
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': authHeader
                    }
                });

                console.log(`   ✅ Products endpoint: ${productsResponse.status}`);
                console.log(`   📦 Found ${productsResponse.data.products?.length || 0} products`);
                if (productsResponse.data.products?.length > 0) {
                    console.log(`   📋 Sample product:`, JSON.stringify(productsResponse.data.products[0], null, 4));
                }
            } catch (error) {
                console.log(`   ❌ Products endpoint failed: ${error.response?.status} - ${error.response?.statusText}`);
                if (error.response?.data) {
                    console.log(`   📄 Error details:`, JSON.stringify(error.response.data, null, 4));
                }
                console.log(`   🔍 Error message: ${error.message}`);
            }

            // Test GET /categories
            console.log('\n   Testing GET /categories...');
            try {
                const categoriesResponse = await axios.get(`${baseUrl}/categories`, {
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': authHeader
                    }
                });

                console.log(`   ✅ Categories endpoint: ${categoriesResponse.status}`);
                console.log(`   📋 Found ${categoriesResponse.data.categories?.length || 0} categories`);
                if (categoriesResponse.data.categories?.length > 0) {
                    console.log(`   📑 Sample category:`, JSON.stringify(categoriesResponse.data.categories[0], null, 4));
                }
            } catch (error) {
                console.log(`   ❌ Categories endpoint failed: ${error.response?.status} - ${error.response?.statusText}`);
                if (error.response?.data) {
                    console.log(`   📄 Error details:`, JSON.stringify(error.response.data, null, 4));
                }
                console.log(`   🔍 Error message: ${error.message}`);
            }

            // Test public categories endpoint
            console.log('\n   Testing public categories endpoint...');
            try {
                const publicCategoriesResponse = await axios.get(`${baseUrl}/categories/business-type/restaurant`, {
                    headers: {
                        'Content-Type': 'application/json'
                    }
                });

                console.log(`   ✅ Public categories endpoint: ${publicCategoriesResponse.status}`);
                console.log(`   📋 Found ${publicCategoriesResponse.data.categories?.length || 0} public categories`);
            } catch (error) {
                console.log(`   ❌ Public categories endpoint failed: ${error.response?.status} - ${error.response?.statusText}`);
                if (error.response?.data) {
                    console.log(`   📄 Error details:`, JSON.stringify(error.response.data, null, 4));
                }
            }

            console.log('\n🎉 Debug complete! Check the results above.');

        } else if (loginResult.ChallengeName) {
            console.log(`⚠️  Login requires challenge: ${loginResult.ChallengeName}`);
            console.log('Challenge parameters:', loginResult.ChallengeParameters);
        } else {
            console.log('❌ Unexpected login response:', loginResult);
        }

    } catch (error) {
        console.error('💥 Login failed:', error.message);
        if (error.code) {
            console.error('Error code:', error.code);
        }
        if (error.message) {
            console.error('Error details:', error.message);
        }
    }
}

// Run the login and debug
loginAndDebug();
