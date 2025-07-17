// Test the image URL field mapping fix with real user credentials
const https = require('https');

console.log('🚀 Starting image URL fix test...');

const API_BASE = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

// Real user credentials
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
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(body);
                    resolve({ status: res.statusCode, data: parsed });
                } catch (e) {
                    resolve({ status: res.statusCode, data: body });
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
    
    console.log(`   Status: ${response.status}`);
    console.log(`   Response:`, response.data);
    
    if (response.status === 200 && response.data.success) {
        console.log('✅ Login successful');
        return response.data.data.AccessToken;
    } else {
        throw new Error('Login failed: ' + (response.data.message || 'Unknown error'));
    }
}

async function uploadTestImage(accessToken) {
    console.log('📤 Uploading test image...');
    
    // Create a simple test image in base64
    const testImageBase64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
    
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

async function createProductWithImage(accessToken, imageUrl) {
    console.log('📦 Creating product with image...');
    
    // Get categories first
    const categoriesResponse = await makeRequest(`${API_BASE}/categories`, 'GET', null, {
        'Authorization': `Bearer ${accessToken}`
    });
    
    if (categoriesResponse.status !== 200 || !categoriesResponse.data.success) {
        throw new Error('Failed to get categories');
    }
    
    const categories = categoriesResponse.data.categories;
    if (categories.length === 0) {
        throw new Error('No categories available');
    }
    
    const firstCategory = categories[0];
    console.log(`   Using category: ${firstCategory.name} (${firstCategory.categoryId})`);
    
    // Create product with the uploaded image URL
    const productData = {
        name: `Test Product ${Date.now()}`,
        description: 'Test product with image URL',
        price: 19.99,
        categoryId: firstCategory.categoryId,
        imageUrl: imageUrl,  // This should now use the correct field name
        isAvailable: true    // This should now use the correct field name
    };
    
    console.log('   Product data being sent:', JSON.stringify(productData, null, 2));
    
    const response = await makeRequest(`${API_BASE}/products`, 'POST', productData, {
        'Authorization': `Bearer ${accessToken}`
    });
    
    console.log(`   Status: ${response.status}`);
    console.log(`   Response:`, JSON.stringify(response.data, null, 2));
    
    if (response.status === 201 && response.data.success) {
        console.log('✅ Product created successfully');
        return response.data.product;
    } else {
        throw new Error('Product creation failed: ' + (response.data.message || 'Unknown error'));
    }
}

async function verifyProductInDatabase(product) {
    console.log('🔍 Verifying product data...');
    console.log(`   Product ID: ${product.productId}`);
    console.log(`   Product Name: ${product.name}`);
    console.log(`   Image URL: ${product.imageUrl}`);
    console.log(`   Is Available: ${product.isAvailable}`);
    
    // Check if imageUrl is properly saved
    if (product.imageUrl && product.imageUrl.trim() !== '') {
        console.log('✅ Image URL is properly saved in the database!');
        console.log(`   Image URL: ${product.imageUrl}`);
    } else {
        console.log('❌ Image URL is empty or missing in the database');
        console.log('   This indicates the field mapping issue still exists');
    }
    
    // Check if isAvailable is properly saved
    if (typeof product.isAvailable === 'boolean') {
        console.log('✅ isAvailable field is properly saved in the database!');
        console.log(`   isAvailable: ${product.isAvailable}`);
    } else {
        console.log('❌ isAvailable field has incorrect type or is missing');
        console.log(`   isAvailable: ${product.isAvailable} (type: ${typeof product.isAvailable})`);
    }
}

async function testImageUrlFix() {
    console.log('🧪 Testing Image URL Field Mapping Fix');
    console.log('=====================================');
    
    try {
        // Step 1: Login
        const accessToken = await loginUser();
        
        // Step 2: Upload image
        const imageUrl = await uploadTestImage(accessToken);
        
        // Step 3: Create product with image
        const product = await createProductWithImage(accessToken, imageUrl);
        
        // Step 4: Verify the fix worked
        await verifyProductInDatabase(product);
        
        console.log('\n🎉 Test completed successfully!');
        console.log('\n📊 Summary:');
        console.log(`   • Login: ✅ Successful`);
        console.log(`   • Image Upload: ✅ Successful`);
        console.log(`   • Product Creation: ✅ Successful`);
        console.log(`   • Image URL Saved: ${product.imageUrl ? '✅ Yes' : '❌ No'}`);
        console.log(`   • isAvailable Saved: ${typeof product.isAvailable === 'boolean' ? '✅ Yes' : '❌ No'}`);
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        console.error('Full error:', error);
    }
}

// Run the test
testImageUrlFix();
