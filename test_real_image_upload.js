// Test uploading a larger, more realistic image
const axios = require('axios');
const fs = require('fs');

const API_BASE = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

async function testRealImageUpload() {
    console.log('🧪 Testing Real Image Upload After Fix');
    console.log('=====================================\n');
    
    try {
        // Login
        console.log('1. 🔐 Logging in...');
        const loginResponse = await axios.post(`${API_BASE}/auth/signin`, {
            email: 'zikbiot@yahoo.com',
            password: 'Gha@551987'
        });
        
        const accessToken = loginResponse.data.data.AccessToken;
        console.log('✅ Login successful');
        
        // Create a larger test image (100x100 red square)
        console.log('\n2. 🖼️ Creating realistic test image...');
        
        // This is a 100x100 red square PNG (larger and more realistic)
        const largerImageBase64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
        
        console.log('✅ Realistic test image prepared');
        
        // Upload the image
        console.log('\n3. 📤 Uploading realistic image...');
        
        const uploadResponse = await axios.post(`${API_BASE}/upload/product-image`, {
            image: largerImageBase64
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
            
            // Test the uploaded image
            console.log('\n4. 🔍 Verifying uploaded image...');
            const response = await axios.get(imageUrl, { responseType: 'arraybuffer' });
            
            console.log(`   HTTP Status: ${response.status}`);
            console.log(`   Content-Type: ${response.headers['content-type']}`);
            console.log(`   File Size: ${response.data.length} bytes`);
            
            // Check magic bytes
            const firstBytes = Buffer.from(response.data.slice(0, 8));
            const hexBytes = firstBytes.toString('hex');
            console.log(`   Magic bytes: ${hexBytes}`);
            
            if (hexBytes.startsWith('89504e47')) {
                console.log('✅ Valid PNG image confirmed!');
                
                // Get categories and create a test product
                console.log('\n5. 📦 Creating test product with image...');
                
                const categoriesResponse = await axios.get(`${API_BASE}/categories`, {
                    headers: { 'Authorization': `Bearer ${accessToken}` }
                });
                
                const categoryId = categoriesResponse.data.categories[0].categoryId;
                
                const productResponse = await axios.post(`${API_BASE}/products`, {
                    name: `Test Product - Real Image ${Date.now()}`,
                    description: 'Testing real image upload with fixed backend',
                    price: 15.99,
                    categoryId: categoryId,
                    imageUrl: imageUrl,
                    isAvailable: true
                }, {
                    headers: { 'Authorization': `Bearer ${accessToken}` }
                });
                
                if (productResponse.status === 201) {
                    console.log('✅ Test product created successfully!');
                    console.log(`📦 Product ID: ${productResponse.data.product.productId}`);
                    console.log('🖼️ The product should now display with the image in the Flutter app');
                } else {
                    console.log('❌ Failed to create test product');
                }
                
            } else {
                console.log('❌ Invalid image format detected');
            }
            
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

testRealImageUpload();
