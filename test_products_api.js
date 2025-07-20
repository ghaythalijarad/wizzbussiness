const https = require('https');
const fs = require('fs');

// Read the access token
console.log('📖 Reading access token...');
const accessToken = fs.readFileSync('/Users/ghaythallaheebi/order-receiver-app-2/access_token.txt', 'utf8').trim();
console.log('✅ Access token loaded');

// API configuration
const API_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const endpoint = '/products';

function testProductsAPI() {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: '72nmgq5rc4.execute-api.us-east-1.amazonaws.com',
            port: 443,
            path: '/dev/products',
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${accessToken}`
            }
        };

        console.log('🔍 Testing /products API endpoint...');
        console.log(`URL: ${API_URL}${endpoint}`);
        console.log(`Token (first 50 chars): ${accessToken.substring(0, 50)}...`);

        const req = https.request(options, (res) => {
            let data = '';

            res.on('data', (chunk) => {
                data += chunk;
            });

            res.on('end', () => {
                console.log(`\n📊 Response Status: ${res.statusCode}`);
                console.log(`Response Headers:`, res.headers);
                
                try {
                    const jsonData = JSON.parse(data);
                    console.log('\n📋 Response Data:');
                    console.log(JSON.stringify(jsonData, null, 2));
                    
                    if (res.statusCode === 200) {
                        console.log('\n✅ Products API test successful!');
                        if (jsonData.products && jsonData.products.length > 0) {
                            console.log(`📦 Found ${jsonData.products.length} products`);
                        }
                    } else {
                        console.log('\n❌ Products API test failed');
                    }
                    
                    resolve(jsonData);
                } catch (error) {
                    console.log('\n❌ Failed to parse JSON response');
                    console.log('Raw response:', data);
                    reject(error);
                }
            });
        });

        req.on('error', (error) => {
            console.error('\n❌ Request error:', error);
            reject(error);
        });

        req.end();
    });
}

// Run the test
testProductsAPI()
    .then(() => {
        console.log('\n🎉 Test completed!');
    })
    .catch((error) => {
        console.error('\n💥 Test failed:', error);
    });
