const axios = require('axios');

async function testLogin() {
    try {
        console.log('🧪 Testing login credentials...');
        
        const response = await axios.post('https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/auth/login', {
            email: 'g87_a@yahoo.com',
            password: 'Gha@551987'
        });

        console.log('✅ Login successful!');
        console.log('Response:', JSON.stringify(response.data, null, 2));
        
        // Test getting businesses
        if (response.data.accessToken) {
            console.log('\n🏢 Testing get businesses...');
            const businessResponse = await axios.get('https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/auth/user-businesses', {
                headers: {
                    'Authorization': `Bearer ${response.data.accessToken}`
                }
            });
            console.log('Businesses:', JSON.stringify(businessResponse.data, null, 2));
        }
        
    } catch (error) {
        console.error('❌ Login failed:', error.response?.data || error.message);
        console.error('Status:', error.response?.status);
    }
}

testLogin();
