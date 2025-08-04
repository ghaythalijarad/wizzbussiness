const axios = require('axios');

const API_BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

async function quickTest() {
    try {
        console.log('🧪 Quick Merchant Endpoint Test');
        console.log('Testing GET /merchant/orders/test-business-123');
        
        const response = await axios.get(`${API_BASE_URL}/merchant/orders/test-business-123`);
        
        console.log('✅ Success!');
        console.log('Status:', response.status);
        console.log('Response:', JSON.stringify(response.data, null, 2));
        
    } catch (error) {
        console.log('❌ Error occurred:');
        console.log('Status:', error.response?.status);
        console.log('Error:', error.response?.data || error.message);
    }
}

quickTest();
