#!/usr/bin/env node

console.log('🚀 Starting upload endpoint test...');

const axios = require('axios');

const BACKEND_URL = 'https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev';

async function simpleTest() {
    try {
        console.log('📸 Testing upload endpoint...');
        console.log('Backend URL:', BACKEND_URL);
        
        const response = await axios.post(`${BACKEND_URL}/upload`, {
            test: 'ping'
        }, {
            headers: {
                'Content-Type': 'application/json',
                'X-Registration-Upload': 'true'
            },
            timeout: 10000,
            validateStatus: () => true
        });
        
        console.log('✅ Got response');
        console.log('Status:', response.status);
        console.log('Data:', response.data);
        
        if (response.status === 401) {
            console.log('❌ Upload requires auth - fix not deployed');
        } else if (response.status === 400) {
            console.log('✅ Upload endpoint working - expects form data');
        } else {
            console.log('❓ Unexpected status:', response.status);
        }
        
    } catch (error) {
        console.log('❌ Error:', error.message);
        if (error.response) {
            console.log('Status:', error.response.status);
            console.log('Data:', error.response.data);
        }
    }
}

simpleTest().then(() => {
    console.log('✅ Test completed');
}).catch(error => {
    console.log('❌ Test failed:', error.message);
});
