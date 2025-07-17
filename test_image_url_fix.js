const https = require('https');

const API_BASE = 'https://clgs5798k1.execute-api.eu-north-1.amazonaws.com/dev';

// Use the test user credentials we set up earlier
const testEmail = 'testuser@example.com';
const testPassword = 'TestPass123!';

async function makeRequest(url, method = 'GET', data = null, headers = {}) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: url.replace('https://', '').split('/')[0],
            path: '/' + url.replace('https://', '').split('/').slice(1).join('/'),
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

        req.on('error', reject);
        
        if (data) {
            req.write(JSON.stringify(data));
        }
        req.end();
    });
}

async function testImageUrlFix() {
    console.log('🧪 Testing Image URL Field Fix');
    console.log('='.repeat(40));

    try {
        // Step 1: Login to get access token
        console.log('1. 🔐 Logging in...');
        const loginResponse = await makeRequest(
            `${API_BASE}/auth/login`,
            'POST',
            {
                email: testEmail,
                password: testPassword
            }
        );

        if (loginResponse.status !== 200 || !loginResponse.data.success) {
            console.error('❌ Login failed:', loginResponse);
            return;
        }

        const accessToken = loginResponse.data.accessToken;
        console.log('✅ Login successful');

        // Step 2: Get categories to pick one for our test product
        console.log('\n2. 📋 Getting categories...');
        const categoriesResponse = await makeRequest(
            `${API_BASE}/categories/business-type/restaurant`,
            'GET'
        );

        if (categoriesResponse.status !== 200) {
            console.error('❌ Failed to get categories:', categoriesResponse);
            return;
        }

        const categories = categoriesResponse.data.categories;
        if (!categories || categories.length === 0) {
            console.error('❌ No categories available');
            return;
        }

        const testCategoryId = categories[0].categoryId;
        console.log(`✅ Got categories, using: ${categories[0].name} (${testCategoryId})`);

        // Step 3: Create a product with image URL
        console.log('\n3. 🛍️ Creating product with image URL...');
        const testImageUrl = 'https://order-receiver-business-photos-dev.s3.us-east-1.amazonaws.com/product-images/test-product-123.jpg';
        
        const productData = {
            name: 'Test Product with Image',
            description: 'Testing image URL field mapping fix',
            price: 12.99,
            categoryId: testCategoryId,
            imageUrl: testImageUrl,
            isAvailable: true
        };

        console.log('📦 Product data being sent:', JSON.stringify(productData, null, 2));

        const createResponse = await makeRequest(
            `${API_BASE}/products`,
            'POST',
            productData,
            { 'Authorization': `Bearer ${accessToken}` }
        );

        console.log('\n📊 Create Product Response:');
        console.log(`   Status: ${createResponse.status}`);
        console.log(`   Response:`, JSON.stringify(createResponse.data, null, 2));

        if (createResponse.status === 201 && createResponse.data.success) {
            const createdProduct = createResponse.data.product;
            console.log('\n✅ Product created successfully!');
            console.log(`   Product ID: ${createdProduct.productId}`);
            console.log(`   Image URL in DB: ${createdProduct.imageUrl}`);
            console.log(`   Is Available: ${createdProduct.isAvailable}`);

            // Check if imageUrl was properly saved
            if (createdProduct.imageUrl === testImageUrl) {
                console.log('🎉 SUCCESS: Image URL was properly saved!');
            } else {
                console.log('❌ FAILURE: Image URL mismatch');
                console.log(`   Expected: ${testImageUrl}`);
                console.log(`   Got: ${createdProduct.imageUrl}`);
            }

            // Check if isAvailable was properly saved
            if (createdProduct.isAvailable === true) {
                console.log('🎉 SUCCESS: isAvailable was properly saved!');
            } else {
                console.log('❌ FAILURE: isAvailable mismatch');
                console.log(`   Expected: true`);
                console.log(`   Got: ${createdProduct.isAvailable}`);
            }

        } else {
            console.log('❌ Product creation failed');
        }

    } catch (error) {
        console.error('❌ Test failed:', error);
    }
}

// Run the test
testImageUrlFix();
