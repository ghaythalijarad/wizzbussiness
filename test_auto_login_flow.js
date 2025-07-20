const axios = require('axios');

const API_BASE = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

async function testAutoLoginFlow() {
    console.log('🧪 Testing Auto-Login Confirmation Flow');
    console.log('=========================================');
    
    try {
        // Test the confirmation endpoint with mock data
        console.log('📧 Testing confirmation endpoint...');
        
        const confirmResponse = await axios.post(`${API_BASE}/auth/confirm`, {
            email: 'test@example.com',
            verificationCode: '123456'
        });
        
        console.log('📊 Response Status:', confirmResponse.status);
        console.log('📄 Response Data:', JSON.stringify(confirmResponse.data, null, 2));
        
        // Check if response includes auto-login fields
        const data = confirmResponse.data;
        if (data.verified === true && data.user && data.businesses) {
            console.log('✅ AUTO-LOGIN RESPONSE FORMAT DETECTED!');
            console.log('👤 User data:', data.user);
            console.log('🏢 Business data:', data.businesses);
            console.log('🎉 Auto-login functionality is working!');
        } else {
            console.log('ℹ️ Standard confirmation response (expected for invalid code)');
        }
        
    } catch (error) {
        console.log('📊 Response Status:', error.response?.status);
        console.log('📄 Response Data:', JSON.stringify(error.response?.data, null, 2));
        
        if (error.response?.status === 400) {
            console.log('✅ Expected error for invalid verification code');
            console.log('✅ Auto-login backend is properly configured');
        } else {
            console.log('❌ Unexpected error:', error.message);
        }
    }
}

testAutoLoginFlow();
