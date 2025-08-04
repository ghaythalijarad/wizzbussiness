const axios = require('axios');

// Configuration
const API_BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

console.log('🧪 Testing Complete Authentication Flow...\n');

async function testCompleteAuthFlow() {
    try {
        // Step 1: Health check
        console.log('1️⃣ Testing auth service health...');
        const healthResponse = await axios.get(`${API_BASE_URL}/auth/health`);
        console.log('✅ Auth service health:', healthResponse.data);

        // Step 2: Check if email is available
        console.log('\n2️⃣ Checking email availability...');
        const emailCheckResponse = await axios.post(`${API_BASE_URL}/auth/check-email`, {
            email: 'test-temp@example.com'
        });
        console.log('✅ Email check:', emailCheckResponse.data);

        // Step 3: Try sign-in with existing account
        console.log('\n3️⃣ Testing sign-in with existing account...');
        try {
            const signInResponse = await axios.post(`${API_BASE_URL}/auth/signin`, {
                email: 'zikbiot@yahoo.com',
                password: 'Test123!'
            });
            
            console.log('✅ Sign-in successful!');
            console.log('Response keys:', Object.keys(signInResponse.data));
            
            const accessToken = signInResponse.data.accessToken;
            const businessData = signInResponse.data.business;
            
            if (accessToken) {
                console.log(`✅ Access token obtained (length: ${accessToken.length})`);
                console.log('✅ Business data:', businessData);
                
                // Step 4: Test user businesses endpoint
                console.log('\n4️⃣ Testing user businesses endpoint...');
                const businessesResponse = await axios.get(`${API_BASE_URL}/auth/user-businesses`, {
                    headers: {
                        'Authorization': `Bearer ${accessToken}`
                    }
                });
                
                console.log('✅ User businesses response:', businessesResponse.data);
                
                console.log('\n🎉 AUTHENTICATION FLOW TEST RESULTS 🎉');
                console.log('✅ Auth service health: WORKING');
                console.log('✅ Email check: WORKING');
                console.log('✅ Sign-in: WORKING');
                console.log('✅ Access tokens: WORKING');
                console.log('✅ User businesses: WORKING');
                console.log('\n🚀 AWS SDK v3 MIGRATION VERIFIED!');
                console.log('🔐 The "User not logged in" issue should be RESOLVED!');
                
            } else {
                console.log('❌ No access token received');
                console.log('Response data:', signInResponse.data);
            }
            
        } catch (signInError) {
            console.log('❌ Sign-in failed:', signInError.response?.data || signInError.message);
            console.log('Status:', signInError.response?.status);
        }

    } catch (error) {
        console.error('❌ Test failed:', error.response?.data || error.message);
        if (error.response?.status) {
            console.error('Status:', error.response.status);
        }
    }
}

// Execute the test
testCompleteAuthFlow().then(() => {
    console.log('\n📝 Test completed!');
    process.exit(0);
}).catch(error => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
});
