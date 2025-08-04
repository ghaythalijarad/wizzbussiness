// Simple test with console output
console.log('🧪 Testing image upload...');

const axios = require('axios');
const API_BASE = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

async function quickTest() {
    try {
        console.log('Logging in...');
        
        const loginResponse = await axios.post(`${API_BASE}/auth/signin`, {
            email: 'zikbiot@yahoo.com',
            password: 'Gha@551987'
        });
        
        console.log('Login status:', loginResponse.status);
        console.log('Login success:', loginResponse.data.success);
        
        if (loginResponse.data.success) {
            const token = loginResponse.data.data.AccessToken;
            console.log('Got token, length:', token.length);
            
            // Test base64 upload
            const testImage = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
            
            console.log('Uploading image...');
            
            const uploadResponse = await axios.post(`${API_BASE}/upload/product-image`, {
                image: testImage
            }, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });
            
            console.log('Upload status:', uploadResponse.status);
            console.log('Upload response:', uploadResponse.data);
            
        }
        
    } catch (error) {
        console.log('Error:', error.message);
        if (error.response) {
            console.log('Response status:', error.response.status);
            console.log('Response data:', error.response.data);
        }
    }
}

quickTest();
