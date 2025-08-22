const axios = require('axios');

const API_BASE_URL = 'https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev';
const EMAIL = 'g87_a@yahoo.com';
const PASSWORD = 'Gha@551987';

async function testAuth() {
    console.log('🔐 Testing authentication...');

    try {
        console.log(`Making POST request to: ${API_BASE_URL}/auth/signin`);
        const response = await axios.post(`${API_BASE_URL}/auth/signin`, {
            email: EMAIL,
            password: PASSWORD
        }, {
            headers: {
                'Content-Type': 'application/json'
            },
            timeout: 10000
        });

        console.log('✅ Auth response received!');
        console.log('Status:', response.status);
        console.log('Status text:', response.statusText);
        console.log('Response data keys:', Object.keys(response.data));

        if (response.data.idToken) {
            console.log('✅ ID Token received (length:', response.data.idToken.length, ')');
        }
        if (response.data.accessToken) {
            console.log('✅ Access Token received (length:', response.data.accessToken.length, ')');
        }

        return response.data;

    } catch (error) {
        console.error('❌ Authentication failed');
        if (error.response) {
            console.log('Status:', error.response.status);
            console.log('Status text:', error.response.statusText);
            console.log('Response data:', JSON.stringify(error.response.data, null, 2));
        } else if (error.request) {
            console.log('No response received. Request made but no response.');
            console.log('Error message:', error.message);
        } else {
            console.log('Error setting up request:', error.message);
        }
        throw error;
    }
}

testAuth().then(result => {
    console.log('Authentication test completed successfully');
}).catch(error => {
    console.log('Authentication test failed');
    process.exit(1);
});
