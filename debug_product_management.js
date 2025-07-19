const axios = require('axios');
const fs = require('fs');

// Configuration
const baseUrl = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

async function debugProductManagement() {
    try {
        console.log('🔍 Debugging Product Management API');
        console.log('=' .repeat(50));

        // Read access token
        let token;
        try {
            token = fs.readFileSync('access_token.txt', 'utf8').trim();
            console.log(`✅ Access token loaded: ${token.substring(0, 20)}...`);
        } catch (error) {
            console.log('❌ Failed to read access token file:', error.message);
            return;
        }

        const authHeader = `Bearer ${token}`;
        
        console.log('\n1. Testing GET /products endpoint...');
        try {
            const productsResponse = await axios.get(`${baseUrl}/products`, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': authHeader
                }
            });

            console.log(`✅ Products endpoint status: ${productsResponse.status}`);
            console.log(`📦 Products response:`, JSON.stringify(productsResponse.data, null, 2));
        } catch (error) {
            console.log(`❌ Products endpoint failed: ${error.response?.status} - ${error.response?.statusText}`);
            if (error.response?.data) {
                console.log(`📄 Error response:`, JSON.stringify(error.response.data, null, 2));
            }
            console.log(`🔍 Full error:`, error.message);
        }

        console.log('\n2. Testing GET /categories endpoint...');
        try {
            const categoriesResponse = await axios.get(`${baseUrl}/categories`, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': authHeader
                }
            });

            console.log(`✅ Categories endpoint status: ${categoriesResponse.status}`);
            console.log(`📋 Categories response:`, JSON.stringify(categoriesResponse.data, null, 2));
        } catch (error) {
            console.log(`❌ Categories endpoint failed: ${error.response?.status} - ${error.response?.statusText}`);
            if (error.response?.data) {
                console.log(`📄 Error response:`, JSON.stringify(error.response.data, null, 2));
            }
            console.log(`🔍 Full error:`, error.message);
        }

        console.log('\n3. Testing public categories endpoint...');
        try {
            const publicCategoriesResponse = await axios.get(`${baseUrl}/categories/business-type/restaurant`, {
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            console.log(`✅ Public categories endpoint status: ${publicCategoriesResponse.status}`);
            console.log(`📋 Public categories response:`, JSON.stringify(publicCategoriesResponse.data, null, 2));
        } catch (error) {
            console.log(`❌ Public categories endpoint failed: ${error.response?.status} - ${error.response?.statusText}`);
            if (error.response?.data) {
                console.log(`📄 Error response:`, JSON.stringify(error.response.data, null, 2));
            }
            console.log(`🔍 Full error:`, error.message);
        }

        console.log('\n4. Testing token validation...');
        try {
            // Test with an authenticated endpoint to verify token is working
            const testResponse = await axios.get(`${baseUrl}/test-auth`, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': authHeader
                }
            });
            console.log(`✅ Token validation successful: ${testResponse.status}`);
        } catch (error) {
            console.log(`ℹ️  Token validation endpoint not available or failed: ${error.response?.status}`);
        }

        console.log('\n5. Testing GET /discounts endpoint...');
        try {
            const discountsResponse = await axios.get(`${baseUrl}/discounts`, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': authHeader
                }
            });
            console.log(`✅ Discounts endpoint status: ${discountsResponse.status}`);
            console.log(`🗒️ Discounts response:`, JSON.stringify(discountsResponse.data, null, 2));
        } catch (error) {
            console.log(`❌ Discounts endpoint failed: ${error.response?.status} - ${error.response?.statusText}`);
            if (error.response?.data) {
                console.log(`📄 Error response:`, JSON.stringify(error.response.data, null, 2));
            }
            console.log(`🔍 Full error:`, error.message);
        }

    } catch (error) {
        console.error('💥 Unexpected error:', error.message);
    }
}

// Run the debug function
debugProductManagement();
