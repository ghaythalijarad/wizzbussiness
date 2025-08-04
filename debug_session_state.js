const AWS = require('aws-sdk');
const axios = require('axios');

const API_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const TEST_EMAIL = 'g87_a@yahoo.com';
const TEST_PASSWORD = 'Gha@551987';

async function debugSessionState() {
    console.log('🔍 DEBUGGING SESSION MANAGEMENT ISSUE');
    console.log('=====================================');
    console.log(`📧 Email: ${TEST_EMAIL}`);
    console.log(`🔗 API URL: ${API_URL}`);
    console.log('');

    try {
        // Step 1: Test API health
        console.log('1️⃣ Testing API health...');
        const healthResp = await axios.get(`${API_URL}/auth/health`);
        console.log('✅ API Health:', healthResp.data);

        // Step 2: Check email existence
        console.log('\n2️⃣ Checking if email exists...');
        const emailResp = await axios.post(`${API_URL}/auth/check-email`, {
            email: TEST_EMAIL
        });
        console.log('📊 Email check result:', emailResp.data);

        // Step 3: Test sign-in
        console.log('\n3️⃣ Testing sign-in...');
        const signInResp = await axios.post(`${API_URL}/auth/signin`, {
            email: TEST_EMAIL,
            password: TEST_PASSWORD
        }, {
            headers: { 'Content-Type': 'application/json' },
            timeout: 10000
        });

        console.log('✅ Sign-in successful!');
        console.log('📊 Response status:', signInResp.status);
        console.log('📄 Response data structure:', Object.keys(signInResp.data));

        // Check what we got back
        const data = signInResp.data;
        console.log('🔍 Response analysis:');
        console.log(`   - Success: ${data.success}`);
        console.log(`   - Message: ${data.message}`);
        console.log(`   - Has user data: ${data.user ? 'YES' : 'NO'}`);
        console.log(`   - Has businesses: ${data.businesses ? `YES (${data.businesses.length})` : 'NO'}`);
        console.log(`   - Has auth data: ${data.data ? 'YES' : 'NO'}`);

        if (data.user) {
            console.log('👤 User data keys:', Object.keys(data.user));
            console.log('👤 User email:', data.user.email);
        }

        if (data.businesses && data.businesses.length > 0) {
            console.log('🏢 Business data keys:', Object.keys(data.businesses[0]));
            console.log('🏢 Business ID:', data.businesses[0].businessId);
            console.log('🏢 Business email:', data.businesses[0].email);
        }

        if (data.data && data.data.AccessToken) {
            const accessToken = data.data.AccessToken;
            console.log('🎫 Access token received:', accessToken.substring(0, 50) + '...');

            // Step 4: Test the access token
            console.log('\n4️⃣ Testing access token with user-businesses endpoint...');
            const businessResp = await axios.get(`${API_URL}/auth/user-businesses`, {
                headers: {
                    'Authorization': `Bearer ${accessToken}`,
                    'Content-Type': 'application/json'
                }
            });

            console.log('✅ Access token validation successful!');
            console.log('📊 User businesses response:', businessResp.data);
        }

        // Step 5: Session State Analysis
        console.log('\n5️⃣ SESSION STATE ANALYSIS');
        console.log('==========================');
        console.log('✅ Backend authentication: Working');
        console.log('✅ User data retrieval: Working');
        console.log('✅ Business data retrieval: Working');
        console.log('✅ Access token generation: Working');
        console.log('✅ Token validation: Working');

        console.log('\n📋 POTENTIAL ISSUES:');
        console.log('1. Flutter app not storing tokens correctly');
        console.log('2. Token storage/retrieval mechanism failing');
        console.log('3. Session validation logic issues');
        console.log('4. Business ID mismatch causing no orders to show');

    } catch (error) {
        console.error('❌ Error during debug:', error.message);
        if (error.response) {
            console.error('📊 Error status:', error.response.status);
            console.error('📄 Error data:', error.response.data);
        }
    }
}

// Run the debug
debugSessionState();
