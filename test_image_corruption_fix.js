// Test script to verify the image corruption fix
const https = require('https');
const fs = require('fs');

const API_BASE = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const testUser = {
    email: 'zikbiot@yahoo.com',
    password: 'Gha@551987'
};

async function makeRequest(url, method = 'GET', data = null, headers = {}) {
    return new Promise((resolve, reject) => {
        const urlObj = new URL(url);
        const options = {
            hostname: urlObj.hostname,
            path: urlObj.pathname + urlObj.search,
            method: method,
            headers: {
                'Content-Type': 'application/json',
                ...headers
            }
        };

        const req = https.request(options, (res) => {
            let responseData = '';
            res.on('data', chunk => responseData += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(responseData);
                    resolve({ status: res.statusCode, data: parsed });
                } catch (e) {
                    resolve({ status: res.statusCode, data: responseData });
                }
            });
        });

        req.on('error', reject);
        
        if (data) {
            req.write(JSON.stringify(data));
        }
        req.end();
    });
}

async function loginUser() {
    console.log('🔐 Logging in user...');
    const response = await makeRequest(`${API_BASE}/auth/signin`, 'POST', {
        email: testUser.email,
        password: testUser.password
    });
    
    if (response.status === 200 && response.data.success) {
        console.log('✅ Login successful');
        return response.data.accessToken;
    } else {
        throw new Error('Login failed: ' + JSON.stringify(response.data));
    }
}

async function uploadTestImage(accessToken) {
    console.log('📤 Uploading test image...');
    
    // Create a simple 1x1 red PNG image
    const testImageBase64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    
    const response = await makeRequest(`${API_BASE}/upload/product-image`, 'POST', {
        image: testImageBase64
    }, {
        'Authorization': `Bearer ${accessToken}`
    });
    
    console.log(`   Status: ${response.status}`);
    console.log(`   Response:`, response.data);
    
    if (response.status === 200 && response.data.success) {
        console.log('✅ Image uploaded successfully');
        return response.data.imageUrl;
    } else {
        throw new Error('Image upload failed: ' + (response.data.message || 'Unknown error'));
    }
}

async function verifyImageIntegrity(imageUrl) {
    console.log('🔍 Verifying image integrity...');
    
    return new Promise((resolve, reject) => {
        const urlObj = new URL(imageUrl);
        const options = {
            hostname: urlObj.hostname,
            path: urlObj.pathname,
            method: 'GET'
        };

        const req = https.request(options, (res) => {
            let imageData = Buffer.alloc(0);
            
            res.on('data', chunk => {
                imageData = Buffer.concat([imageData, chunk]);
            });
            
            res.on('end', () => {
                console.log(`   Status: ${res.statusCode}`);
                console.log(`   Content-Type: ${res.headers['content-type']}`);
                console.log(`   Content-Length: ${res.headers['content-length']}`);
                console.log(`   Image size: ${imageData.length} bytes`);
                
                // Check if it's a valid PNG
                const isPNG = imageData.slice(0, 8).equals(Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]));
                console.log(`   Is valid PNG: ${isPNG ? '✅ Yes' : '❌ No'}`);
                
                // Check for corruption markers (UTF-8 replacement characters)
                const hasCorruption = imageData.includes(Buffer.from([0xEF, 0xBF, 0xBD]));
                console.log(`   Has corruption: ${hasCorruption ? '❌ Yes' : '✅ No'}`);
                
                resolve({
                    isValid: isPNG && !hasCorruption,
                    contentType: res.headers['content-type'],
                    size: imageData.length,
                    isPNG,
                    hasCorruption
                });
            });
        });

        req.on('error', reject);
        req.end();
    });
}

async function testImageCorruptionFix() {
    console.log('🧪 Testing Image Corruption Fix');
    console.log('===============================');
    
    try {
        // Step 1: Login
        const accessToken = await loginUser();
        
        // Step 2: Upload image
        const imageUrl = await uploadTestImage(accessToken);
        
        // Step 3: Verify image integrity
        const verification = await verifyImageIntegrity(imageUrl);
        
        console.log('\n📊 Test Results:');
        console.log(`   • Login: ✅ Successful`);
        console.log(`   • Image Upload: ✅ Successful`);
        console.log(`   • Image URL: ${imageUrl}`);
        console.log(`   • Image Integrity: ${verification.isValid ? '✅ Valid' : '❌ Corrupted'}`);
        console.log(`   • Content-Type: ${verification.contentType}`);
        console.log(`   • File Size: ${verification.size} bytes`);
        
        if (verification.isValid) {
            console.log('\n🎉 SUCCESS: Image corruption fix is working!');
            console.log('   Images are now being stored correctly in S3.');
        } else {
            console.log('\n❌ FAILURE: Images are still corrupted');
            if (verification.hasCorruption) {
                console.log('   • UTF-8 corruption detected');
            }
            if (!verification.isPNG) {
                console.log('   • PNG header is invalid');
            }
        }
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
    }
}

// Run the test
testImageCorruptionFix();
