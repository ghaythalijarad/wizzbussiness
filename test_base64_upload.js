// Test Image Upload with Base64 (simpler approach)
const axios = require('axios');
const fs = require('fs');

const API_BASE = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

async function testBase64Upload() {
    console.log('🧪 Testing Base64 Image Upload');
    console.log('==============================\n');
    
    try {
        // Step 1: Login
        console.log('1. 🔐 Logging in...');
        const loginResponse = await axios.post(`${API_BASE}/auth/signin`, {
            email: 'zikbiot@yahoo.com',
            password: 'Gha@551987'
        });
        
        if (!loginResponse.data.success) {
            throw new Error('Login failed: ' + loginResponse.data.message);
        }
        
        const accessToken = loginResponse.data.data.AccessToken;
        console.log('✅ Login successful');
        
        // Step 2: Create a test image in base64 format
        console.log('\n2. 🖼️ Creating test image (base64)...');
        
        // Create a simple test image - a 100x100 red square in PNG format
        const testImageBase64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
        
        console.log(`✅ Test image prepared (${testImageBase64.length} chars)`);
        
        // Step 3: Upload using base64 JSON format
        console.log('\n3. 📤 Uploading image (base64 JSON)...');
        
        const uploadResponse = await axios.post(`${API_BASE}/upload/product-image`, {
            image: testImageBase64
        }, {
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json'
            }
        });
        
        console.log(`   Status: ${uploadResponse.status}`);
        console.log(`   Response:`, JSON.stringify(uploadResponse.data, null, 2));
        
        if (uploadResponse.status === 200 && uploadResponse.data.success) {
            const imageUrl = uploadResponse.data.imageUrl;
            console.log('✅ Upload successful!');
            console.log(`📎 Image URL: ${imageUrl}`);
            
            // Step 4: Test the uploaded image
            console.log('\n4. 🔍 Testing uploaded image...');
            await testUploadedImage(imageUrl);
            
        } else {
            console.log('❌ Upload failed');
        }
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        if (error.response) {
            console.error('Response status:', error.response.status);
            console.error('Response data:', error.response.data);
        }
    }
}

async function testUploadedImage(imageUrl) {
    try {
        const response = await axios.get(imageUrl, { responseType: 'arraybuffer' });
        
        console.log(`   HTTP Status: ${response.status}`);
        console.log(`   Content-Type: ${response.headers['content-type']}`);
        console.log(`   File Size: ${response.data.length} bytes`);
        
        // Check magic bytes
        const firstBytes = Buffer.from(response.data.slice(0, 8));
        const hexBytes = firstBytes.toString('hex');
        console.log(`   Magic bytes: ${hexBytes}`);
        
        if (hexBytes.startsWith('89504e47')) {
            console.log('✅ Valid PNG image detected');
        } else if (hexBytes.startsWith('ffd8')) {
            console.log('✅ Valid JPEG image detected');
        } else {
            console.log('❌ Invalid image format');
            console.log(`   Expected PNG (89504e47) or JPEG (ffd8), got: ${hexBytes}`);
        }
        
        // Save for inspection
        fs.writeFileSync('downloaded_test_image.jpg', Buffer.from(response.data));
        console.log('💾 Downloaded image saved as downloaded_test_image.jpg');
        
    } catch (error) {
        console.log('❌ Error testing uploaded image:', error.message);
    }
}

// Run the test
testBase64Upload();
