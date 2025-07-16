const axios = require('axios');

async function testLoginWithDetailedLogging() {
    const baseUrl = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
    const credentials = {
        email: 'g87_a@yahoo.com',
        password: 'Gha@551987'
    };
    
    console.log('🔍 Testing Login with Detailed Analysis');
    console.log('=====================================');
    console.log(`Email: ${credentials.email}`);
    console.log(`Backend URL: ${baseUrl}`);
    
    try {
        console.log('\n1️⃣ Testing health endpoint...');
        const healthResponse = await axios.get(`${baseUrl}/auth/health`);
        console.log('✅ Backend is healthy:', healthResponse.data);
        
        console.log('\n2️⃣ Testing email check...');
        const emailCheckResponse = await axios.post(`${baseUrl}/auth/check-email`, {
            email: credentials.email
        });
        console.log('Email check result:', emailCheckResponse.data);
        
        console.log('\n3️⃣ Attempting login...');
        const loginResponse = await axios.post(`${baseUrl}/auth/signin`, credentials, {
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        console.log('✅ Login successful!');
        console.log('Response:', JSON.stringify(loginResponse.data, null, 2));
        
    } catch (error) {
        console.log('❌ Login failed');
        
        if (error.response) {
            console.log('Status:', error.response.status);
            console.log('Status Text:', error.response.statusText);
            console.log('Response Data:', JSON.stringify(error.response.data, null, 2));
            console.log('Response Headers:', error.response.headers);
        } else if (error.request) {
            console.log('No response received:', error.request);
        } else {
            console.log('Error setting up request:', error.message);
        }
        
        // Check for specific error patterns
        if (error.response?.status === 401) {
            console.log('\n💡 Analysis: 401 Unauthorized');
            console.log('Possible causes:');
            console.log('1. Password is incorrect');
            console.log('2. User account is not verified');
            console.log('3. User account is disabled');
            console.log('4. Cognito User Pool configuration issue');
        }
    }
}

testLoginWithDetailedLogging().catch(console.error);
