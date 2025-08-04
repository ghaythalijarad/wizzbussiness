// Debug Image Upload Quality Issues
// This script tests the image upload process to understand file size and format issues

const axios = require('axios');
const fs = require('fs');

const API_BASE = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

// Test credentials
const TEST_EMAIL = 'zikbiot@yahoo.com';
const TEST_PASSWORD = 'Gha@551987';

async function makeRequest(url, method = 'GET', data = null, headers = {}) {
    try {
        const config = {
            method,
            url,
            headers: {
                'Content-Type': 'application/json',
                ...headers
            }
        };

        if (data) {
            config.data = data;
        }

        const response = await axios(config);
        return response;
    } catch (error) {
        if (error.response) {
            return error.response;
        }
        throw error;
    }
}

async function createTestImage(quality = 95, size = 800) {
    // Create a simple test image in base64 format
    // This creates a small PNG image that we can use to test upload
    const testImageBase64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
    
    // For a more realistic test, create a larger base64 image
    const canvas = `data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=`;
    
    console.log(`📏 Original test image size: ${Buffer.from(testImageBase64.split(',')[1], 'base64').length} bytes`);
    
    return canvas;
}

async function loginAndGetToken() {
    console.log('🔐 Signing in...');
    
    const signInResponse = await makeRequest(`${API_BASE}/auth/signin`, 'POST', {
        email: TEST_EMAIL,
        password: TEST_PASSWORD
    });

    if (signInResponse.status === 200 && signInResponse.data.success) {
        console.log('✅ Login successful');
        return signInResponse.data.data.AccessToken;
    } else {
        throw new Error('Login failed: ' + (signInResponse.data?.message || 'Unknown error'));
    }
}

async function testImageUpload(accessToken) {
    console.log('\n📤 Testing image upload...');
    
    // Create test image
    const testImage = await createTestImage();
    
    // Test upload
    const uploadResponse = await makeRequest(
        `${API_BASE}/upload/product-image`,
        'POST',
        { image: testImage },
        { 'Authorization': `Bearer ${accessToken}` }
    );
    
    console.log(`   Status: ${uploadResponse.status}`);
    console.log(`   Response:`, JSON.stringify(uploadResponse.data, null, 2));
    
    if (uploadResponse.status === 200 && uploadResponse.data.success) {
        const imageUrl = uploadResponse.data.imageUrl;
        console.log(`✅ Image uploaded: ${imageUrl}`);
        
        // Test the uploaded image by downloading it
        await testUploadedImage(imageUrl);
        
        return imageUrl;
    } else {
        throw new Error('Image upload failed: ' + (uploadResponse.data?.message || 'Unknown error'));
    }
}

async function testUploadedImage(imageUrl) {
    console.log('\n🔍 Testing uploaded image...');
    
    try {
        // Download the image to check its properties
        const response = await axios.get(imageUrl, { responseType: 'arraybuffer' });
        
        console.log(`   HTTP Status: ${response.status}`);
        console.log(`   Content-Type: ${response.headers['content-type']}`);
        console.log(`   Content-Length: ${response.headers['content-length']} bytes`);
        console.log(`   File Size: ${response.data.length} bytes`);
        
        // Check if the image is accessible
        if (response.status === 200) {
            console.log('✅ Image is accessible and downloadable');
            
            // Analyze file size
            const fileSizeKB = Math.round(response.data.length / 1024);
            console.log(`📊 Image Analysis:`);
            console.log(`   File Size: ${fileSizeKB} KB`);
            console.log(`   Content Type: ${response.headers['content-type']}`);
            
            if (fileSizeKB < 50) {
                console.log('⚠️  WARNING: Very small file size - possible compression issues');
            } else if (fileSizeKB > 500) {
                console.log('ℹ️  Large file size - good quality retained');
            } else {
                console.log('✅ Normal file size range');
            }
            
        } else {
            console.log('❌ Image is not accessible');
        }
        
    } catch (error) {
        console.log('❌ Error accessing uploaded image:', error.message);
    }
}

async function testExistingProductImages() {
    console.log('\n🛍️ Testing existing product images...');
    
    const accessToken = await loginAndGetToken();
    
    // Get products to check their images
    const productsResponse = await makeRequest(
        `${API_BASE}/products`,
        'GET',
        null,
        { 'Authorization': `Bearer ${accessToken}` }
    );
    
    if (productsResponse.status === 200 && productsResponse.data.success) {
        const products = productsResponse.data.products;
        console.log(`📦 Found ${products.length} products`);
        
        for (const product of products.slice(0, 3)) { // Test first 3 products
            if (product.imageUrl) {
                console.log(`\n🔍 Testing image for product: ${product.name}`);
                console.log(`   Image URL: ${product.imageUrl}`);
                await testUploadedImage(product.imageUrl);
            } else {
                console.log(`\n📦 Product ${product.name} has no image`);
            }
        }
    }
}

async function debugImageUploadQuality() {
    console.log('🧪 Debug Image Upload Quality Issues');
    console.log('====================================\n');
    
    try {
        // Step 1: Login
        const accessToken = await loginAndGetToken();
        
        // Step 2: Test new image upload
        await testImageUpload(accessToken);
        
        // Step 3: Test existing product images
        await testExistingProductImages();
        
        console.log('\n🎉 Debug completed successfully!');
        
    } catch (error) {
        console.error('❌ Debug failed:', error.message);
        console.error('Full error:', error);
    }
}

// Run the debug
debugImageUploadQuality();
