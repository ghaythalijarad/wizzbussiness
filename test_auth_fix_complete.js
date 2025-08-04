// Test script to verify authentication token validation works correctly
const https = require('https');

async function testAuthenticationFlow() {
    console.log('🧪 Testing Authentication Flow Post-Fix...\n');
    
    // Test credentials (replace with real test account)
    const testEmail = 'ghaythallaheebi@gmail.com';
    const testPassword = 'TempPass123!';
    
    try {
        // Step 1: Login to get tokens
        console.log('1️⃣ Testing login...');
        const loginResponse = await makeRequest('/auth/simple-signin', 'POST', {
            email: testEmail,
            password: testPassword
        });
        
        if (loginResponse.access_token) {
            console.log('✅ Login successful, got access token');
            
            // Step 2: Test token validation by getting user businesses
            console.log('\n2️⃣ Testing token validation...');
            const businessResponse = await makeRequest('/auth/user-businesses', 'GET', null, {
                'Authorization': `Bearer ${loginResponse.access_token}`
            });
            
            if (businessResponse.businesses) {
                console.log('✅ Token validation successful');
                console.log(`   Found ${businessResponse.businesses.length} businesses`);
                
                // Step 3: Test discount management endpoint
                console.log('\n3️⃣ Testing discount management access...');
                const discountResponse = await makeRequest('/discounts', 'GET', null, {
                    'Authorization': `Bearer ${loginResponse.access_token}`
                });
                
                if (discountResponse) {
                    console.log('✅ Discount management access successful');
                    console.log(`   Response: ${JSON.stringify(discountResponse).substring(0, 100)}...`);
                } else {
                    console.log('❌ Discount management access failed');
                }
            } else {
                console.log('❌ Token validation failed');
            }
        } else {
            console.log('❌ Login failed');
            console.log(`   Response: ${JSON.stringify(loginResponse)}`);
        }
    } catch (error) {
        console.error('❌ Test failed:', error.message);
    }
}

function makeRequest(path, method, body, headers = {}) {
    return new Promise((resolve, reject) => {
        const defaultHeaders = {
            'Content-Type': 'application/json',
            ...headers
        };
        
        const options = {
            hostname: '72nmgq5rc4.execute-api.us-east-1.amazonaws.com',
            port: 443,
            path: `/dev${path}`,
            method: method,
            headers: defaultHeaders
        };
        
        const req = https.request(options, (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                try {
                    const jsonData = JSON.parse(data);
                    resolve(jsonData);
                } catch (e) {
                    resolve(data);
                }
            });
        });
        
        req.on('error', (error) => {
            reject(error);
        });
        
        if (body) {
            req.write(JSON.stringify(body));
        }
        
        req.end();
    });
}

// Run the test
testAuthenticationFlow();
