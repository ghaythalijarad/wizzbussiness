// Test Image Upload Quality and Fix Issues
// This script will test image upload and help identify quality problems

const axios = require('axios');
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const API_BASE = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const TEST_EMAIL = 'zikbiot@yahoo.com';
const TEST_PASSWORD = 'Gha@551987';

// Create a high-quality test image
async function createHighQualityTestImage() {
    console.log('📸 Creating high-quality test image...');
    
    // Create a test image with sharp (high quality)
    const testImageBuffer = await sharp({
        create: {
            width: 800,
            height: 600,
            channels: 3,
            background: { r: 255, g: 100, b: 50 }
        }
    })
    .png({ quality: 100, compressionLevel: 0 })
    .toBuffer();
    
    console.log(`✅ Created test image: ${testImageBuffer.length} bytes (${Math.round(testImageBuffer.length / 1024)} KB)`);
    
    // Convert to base64
    const base64Image = `data:image/png;base64,${testImageBuffer.toString('base64')}`;
    console.log(`📏 Base64 size: ${base64Image.length} characters`);
    
    return base64Image;
}

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

async function testImageUploadQuality(accessToken) {
    console.log('\n📤 Testing image upload quality...');
    
    // Create high-quality test image
    const testImage = await createHighQualityTestImage();
    
    // Test upload
    const uploadResponse = await makeRequest(
        `${API_BASE}/upload/product-image`,
        'POST',
        { image: testImage },
        { 'Authorization': `Bearer ${accessToken}` }
    );
    
    console.log(`   Upload Status: ${uploadResponse.status}`);
    console.log(`   Upload Response:`, JSON.stringify(uploadResponse.data, null, 2));
    
    if (uploadResponse.status === 200 && uploadResponse.data.success) {
        const imageUrl = uploadResponse.data.imageUrl;
        console.log(`✅ Image uploaded: ${imageUrl}`);
        
        // Test the uploaded image quality
        await analyzeUploadedImage(imageUrl);
        
        return imageUrl;
    } else {
        throw new Error('Image upload failed: ' + (uploadResponse.data?.message || 'Unknown error'));
    }
}

async function analyzeUploadedImage(imageUrl) {
    console.log('\n🔍 Analyzing uploaded image quality...');
    
    try {
        // Download the image to check its properties
        const response = await axios.get(imageUrl, { responseType: 'arraybuffer' });
        
        console.log(`   📊 Analysis Results:`);
        console.log(`   HTTP Status: ${response.status}`);
        console.log(`   Content-Type: ${response.headers['content-type']}`);
        console.log(`   Content-Length: ${response.headers['content-length']} bytes`);
        console.log(`   File Size: ${response.data.length} bytes (${Math.round(response.data.length / 1024)} KB)`);
        
        // Use sharp to analyze image properties
        if (response.data.length > 0) {
            try {
                const metadata = await sharp(Buffer.from(response.data)).metadata();
                console.log(`   Image Dimensions: ${metadata.width}x${metadata.height}`);
                console.log(`   Format: ${metadata.format}`);
                console.log(`   Channels: ${metadata.channels}`);
                console.log(`   Density: ${metadata.density || 'N/A'}`);
                console.log(`   Quality: ${metadata.quality || 'N/A'}`);
                
                // Quality assessment
                const fileSizeKB = Math.round(response.data.length / 1024);
                if (fileSizeKB < 50) {
                    console.log('⚠️  WARNING: Very small file size - possible over-compression');
                    console.log('   Recommendation: Increase image quality settings');
                } else if (fileSizeKB > 500) {
                    console.log('✅ Good file size - quality preserved');
                } else {
                    console.log('✅ Normal file size range');
                }
                
            } catch (sharpError) {
                console.log(`❌ Could not analyze image with sharp: ${sharpError.message}`);
            }
        }
        
    } catch (error) {
        console.log(`❌ Error downloading/analyzing image: ${error.message}`);
        
        // If download fails, it might be a network/CORS issue
        if (error.response?.status === 403) {
            console.log('   🔒 403 Forbidden - Possible S3 permissions issue');
        } else if (error.response?.status === 404) {
            console.log('   🚫 404 Not Found - Image URL is invalid');
        } else if (error.code === 'ENOTFOUND') {
            console.log('   🌐 Network error - DNS resolution failed');
        }
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
        
        let imagesFound = 0;
        for (const product of products) {
            if (product.image_url) {
                imagesFound++;
                console.log(`\n🔍 Testing image for product: ${product.name}`);
                console.log(`   Image URL: ${product.image_url}`);
                await analyzeUploadedImage(product.image_url);
                
                if (imagesFound >= 3) break; // Only test first 3 images
            }
        }
        
        if (imagesFound === 0) {
            console.log('❌ No products with images found');
        }
    }
}

async function recommendImageQualityImprovements() {
    console.log('\n💡 Image Quality Improvement Recommendations:');
    console.log('================================================');
    
    console.log('\n1. 📱 Flutter App Settings:');
    console.log('   - imageQuality: 95 (✅ Good - already implemented)');
    console.log('   - maxWidth/maxHeight: 1920 (✅ Good - already implemented)');
    console.log('   - Consider using PNG format for better quality');
    
    console.log('\n2. 🔧 Backend Processing:');
    console.log('   - Ensure S3 upload preserves original quality');
    console.log('   - Check for any image compression middleware');
    console.log('   - Verify ContentType is correct (image/jpeg, image/png)');
    
    console.log('\n3. 🌐 Network & Storage:');
    console.log('   - Ensure consistent S3 region (some images in eu-north-1, some in us-east-1)');
    console.log('   - Verify S3 bucket permissions for public read access');
    console.log('   - Check CORS settings for cross-origin access');
    
    console.log('\n4. 📋 Field Mapping:');
    console.log('   - API returns "image_url" (snake_case)');
    console.log('   - Flutter expects "imageUrl" (camelCase)');
    console.log('   - Product.fromJson handles both ✅ (should work)');
}

async function fixImageUploadQuality() {
    console.log('🔧 Image Upload Quality Test & Fix');
    console.log('===================================\n');
    
    try {
        // Step 1: Login
        const accessToken = await loginAndGetToken();
        
        // Step 2: Test new image upload
        await testImageUploadQuality(accessToken);
        
        // Step 3: Test existing product images
        await testExistingProductImages();
        
        // Step 4: Provide recommendations
        await recommendImageQualityImprovements();
        
        console.log('\n🎉 Image quality analysis completed!');
        
    } catch (error) {
        console.error('❌ Image quality test failed:', error.message);
        console.error('Full error:', error);
    }
}

// Run the test
fixImageUploadQuality();
