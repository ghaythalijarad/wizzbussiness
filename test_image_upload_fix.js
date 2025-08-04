// Test Image Upload After Fix
const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');

const API_BASE = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

async function testImageUploadFix() {
    console.log('🧪 Testing Image Upload Fix');
    console.log('============================\n');
    
    try {
        // Step 1: Login to get access token
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
        
        // Step 2: Create a test image
        console.log('\n2. 🖼️ Creating test image...');
        const testImageData = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==', 'base64');
        
        // Write test image to file
        fs.writeFileSync('test_upload_image.png', testImageData);
        console.log('✅ Test image created');
        
        // Step 3: Upload image using multipart form data (like Flutter does)
        console.log('\n3. 📤 Uploading image...');
        
        const form = new FormData();
        form.append('image', fs.createReadStream('test_upload_image.png'), {
            filename: 'test_upload.png',
            contentType: 'image/png'
        });
        
        const uploadResponse = await axios.post(`${API_BASE}/upload/product-image`, form, {
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                ...form.getHeaders()
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
        
        // Cleanup
        if (fs.existsSync('test_upload_image.png')) {
            fs.unlinkSync('test_upload_image.png');
        }
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        if (error.response) {
            console.error('Response data:', error.response.data);
        }
    }
}

async function testUploadedImage(imageUrl) {
    try {
        // Download and check the image
        const response = await axios.get(imageUrl, { responseType: 'arraybuffer' });
        
        console.log(`   HTTP Status: ${response.status}`);
        console.log(`   Content-Type: ${response.headers['content-type']}`);
        console.log(`   File Size: ${response.data.length} bytes`);
        
        // Check if it's a valid image by looking at magic bytes
        const firstBytes = Buffer.from(response.data.slice(0, 8));
        const hexBytes = firstBytes.toString('hex');
        console.log(`   Magic bytes: ${hexBytes}`);
        
        // PNG starts with 89504E47 (‰PNG)
        // JPEG starts with FFD8
        if (hexBytes.startsWith('89504e47')) {
            console.log('✅ Valid PNG image detected');
        } else if (hexBytes.startsWith('ffd8')) {
            console.log('✅ Valid JPEG image detected');
        } else {
            console.log('❌ Invalid image format - corrupted data');
            console.log(`   Expected PNG (89504e47) or JPEG (ffd8), got: ${hexBytes}`);
        }
        
    } catch (error) {
        console.log('❌ Error testing uploaded image:', error.message);
    }
}

// Run the test
testImageUploadFix();
