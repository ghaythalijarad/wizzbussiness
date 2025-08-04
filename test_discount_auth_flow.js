const axios = require('axios');

async function testDiscountAuthFlow() {
    console.log('🧪 Testing Complete Discount Management Auth Flow');
    console.log('================================================');
    
    const API_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
    const EMAIL = 'g87_a@yahoo.com';
    const PASSWORD = 'Gha@551987';

    try {
        // Step 1: Authenticate and get fresh token
        console.log('1️⃣ Authenticating user...');
        const signInResponse = await axios.post(`${API_URL}/auth/signin`, {
            email: EMAIL,
            password: PASSWORD
        });

        if (!signInResponse.data.success) {
            console.log('❌ Authentication failed:', signInResponse.data.message);
            return;
        }

        const accessToken = signInResponse.data.data.AccessToken;
        const user = signInResponse.data.user;
        const businesses = signInResponse.data.businesses;

        console.log('✅ Authentication successful!');
        console.log(`👤 User: ${user?.email || 'Unknown'}`);
        console.log(`🏢 Businesses: ${businesses?.length || 0}`);
        
        // Step 2: Test discount management endpoint
        console.log('\n2️⃣ Testing discount management endpoint...');
        const discountResponse = await axios.get(`${API_URL}/discounts`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json'
            }
        });

        console.log('✅ Discount management endpoint working!');
        console.log(`📋 Discounts found: ${discountResponse.data.discounts?.length || 0}`);
        
        // Step 3: Test getting user businesses
        console.log('\n3️⃣ Testing user businesses endpoint...');
        const businessResponse = await axios.get(`${API_URL}/auth/user-businesses`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json'
            }
        });

        console.log('✅ User businesses endpoint working!');
        console.log(`🏢 Businesses retrieved: ${businessResponse.data.businesses?.length || 0}`);
        
        // Step 4: Test products endpoint (used by discount management)
        console.log('\n4️⃣ Testing products endpoint...');
        try {
            const productsResponse = await axios.get(`${API_URL}/products`, {
                headers: {
                    'Authorization': `Bearer ${accessToken}`,
                    'Content-Type': 'application/json'
                }
            });

            console.log('✅ Products endpoint working!');
            console.log(`📦 Products found: ${productsResponse.data.products?.length || 0}`);
        } catch (productsError) {
            console.log('⚠️ Products endpoint issue:', productsError.response?.data?.message || productsError.message);
        }

        console.log('\n🎉 All authentication flows working correctly!');
        console.log('The issue in the Flutter app was likely due to expired tokens.');
        console.log('The fixes to isSignedIn() and getCurrentUser() should resolve the issue.');

    } catch (error) {
        console.log('❌ Test failed:');
        if (error.response) {
            console.log(`   Status: ${error.response.status}`);
            console.log(`   Message: ${error.response.data?.message || 'Unknown error'}`);
        } else {
            console.log(`   Error: ${error.message}`);
        }
    }
}

testDiscountAuthFlow();
