const https = require('https');

console.log('🧪 Starting Image URL Fix Test...');

const API_BASE = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const testEmail = 'testuser@example.com';
const testPassword = 'TestPass123!';

async function makeRequest(url, method = 'GET', data = null, headers = {}) {
    console.log(`📡 Making ${method} request to: ${url}`);
    
    return new Promise((resolve, reject) => {
        const urlParts = url.replace('https://', '').split('/');
        const hostname = urlParts[0];
        const path = '/' + urlParts.slice(1).join('/');
        
        const options = {
            hostname,
            path,
            method,
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

        req.on('error', (error) => {
            console.error('Request error:', error);
            reject(error);
        });
        
        if (data) {
            req.write(JSON.stringify(data));
        }
        req.end();
    });
}

async function testImageUrlFix() {
    try {
        console.log('1. 🔐 Attempting login...');
        
        const loginResponse = await makeRequest(
            `${API_BASE}/auth/login`,
            'POST',
            {
                email: testEmail,
                password: testPassword
            }
        );

        console.log(`Login response status: ${loginResponse.status}`);
        console.log('Login response:', JSON.stringify(loginResponse.data, null, 2));

        if (loginResponse.status !== 200 || !loginResponse.data.success) {
            console.error('❌ Login failed');
            return;
        }

        const accessToken = loginResponse.data.accessToken;
        console.log('✅ Login successful, got access token');

        // Get categories
        console.log('\n2. 📋 Getting categories...');
        const categoriesResponse = await makeRequest(
            `${API_BASE}/categories/business-type/restaurant`,
            'GET'
        );

        console.log(`Categories response status: ${categoriesResponse.status}`);
        
        if (categoriesResponse.status !== 200) {
            console.error('❌ Failed to get categories');
            return;
        }

        const categories = categoriesResponse.data.categories;
        const testCategoryId = categories[0].categoryId;
        console.log(`✅ Using category: ${categories[0].name} (${testCategoryId})`);

        // Create product with image URL
        console.log('\n3. 🛍️ Creating product with image URL...');
        const testImageUrl = 'https://order-receiver-business-photos-dev.s3.us-east-1.amazonaws.com/product-images/test-product-123.jpg';
        
        const productData = {
            name: 'Test Product with Image - Field Fix',
            description: 'Testing image URL field mapping fix',
            price: 15.99,
            categoryId: testCategoryId,
            imageUrl: testImageUrl,
            isAvailable: true
        };

        console.log('📦 Sending product data:', JSON.stringify(productData, null, 2));

        const createResponse = await makeRequest(
            `${API_BASE}/products`,
            'POST',
            productData,
            { 'Authorization': `Bearer ${accessToken}` }
        );

        console.log(`\n📊 Product creation response status: ${createResponse.status}`);
        console.log('Response:', JSON.stringify(createResponse.data, null, 2));

        if (createResponse.status === 201 && createResponse.data.success) {
            const createdProduct = createResponse.data.product;
            console.log('\n✅ Product created successfully!');
            console.log(`Product ID: ${createdProduct.productId}`);
            console.log(`Image URL saved: "${createdProduct.imageUrl}"`);
            console.log(`Is Available: ${createdProduct.isAvailable}`);

            // Verify the fix
            const imageUrlMatch = createdProduct.imageUrl === testImageUrl;
            const isAvailableMatch = createdProduct.isAvailable === true;

            console.log('\n🔍 VERIFICATION RESULTS:');
            console.log(`Image URL fix: ${imageUrlMatch ? '✅ SUCCESS' : '❌ FAILED'}`);
            console.log(`isAvailable fix: ${isAvailableMatch ? '✅ SUCCESS' : '❌ FAILED'}`);

            if (imageUrlMatch && isAvailableMatch) {
                console.log('\n🎉 ALL FIXES WORKING CORRECTLY!');
                console.log('Product image URLs will now be properly saved to DynamoDB.');
            } else {
                console.log('\n❌ Some fixes are not working:');
                if (!imageUrlMatch) {
                    console.log(`  - Expected imageUrl: "${testImageUrl}"`);
                    console.log(`  - Got imageUrl: "${createdProduct.imageUrl}"`);
                }
                if (!isAvailableMatch) {
                    console.log(`  - Expected isAvailable: true`);
                    console.log(`  - Got isAvailable: ${createdProduct.isAvailable}`);
                }
            }

        } else {
            console.log('❌ Product creation failed');
        }

    } catch (error) {
        console.error('❌ Test failed with error:', error);
    }
}

// Run the test
testImageUrlFix().then(() => {
    console.log('\n✅ Test completed');
    process.exit(0);
}).catch(error => {
    console.error('❌ Test failed:', error);
    process.exit(1);
});
