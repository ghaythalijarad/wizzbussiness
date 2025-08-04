const axios = require('axios');

// Configuration
const API_BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const EMAIL = 'g87_a@yahoo.com';
const PASSWORD = 'Gha@551987';

async function loginTest() {
    try {
        console.log('🧪 Testing Login Functionality...');

        // Step 1: Sign in
        console.log('\n1️⃣ Testing sign-in...');
        const signInResponse = await axios.post(`${API_BASE_URL}/auth/signin`, {
            email: EMAIL,
            password: PASSWORD
        });

        console.log('✅ Sign-in successful!');
        console.log('Response data:', JSON.stringify(signInResponse.data, null, 2));
        
        const accessToken = signInResponse.data.accessToken;
        const businessId = signInResponse.data.business?.businessId;

        if (!accessToken) {
            console.log('❌ No access token received');
            return;
        }

        console.log(`✅ Access token obtained (length: ${accessToken.length})`);
        console.log(`✅ Business ID: ${businessId}`);

        // Step 2: Test user businesses endpoint
        console.log('\n2️⃣ Testing user businesses endpoint...');
        const businessesResponse = await axios.get(`${API_BASE_URL}/auth/user-businesses`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`
            }
        });

        console.log('✅ User businesses response:', JSON.stringify(businessesResponse.data, null, 2));

        console.log('\n🎉 LOGIN TEST COMPLETE 🎉');
        console.log('✅ Sign-in: WORKING');
        console.log('✅ Access tokens: WORKING');
        console.log('✅ User businesses: WORKING');

    } catch (error) {
        console.error('❌ Test failed:', error.response?.data || error.message);
        if (error.response?.status) {
            console.error('Status:', error.response.status);
        }
    }
}

loginTest();
