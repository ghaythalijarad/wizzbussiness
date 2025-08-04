const axios = require('axios');

const API_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const EMAIL = 'g87_a@yahoo.com';
const PASSWORD = 'Gha@551987';

async function testAuthWithCredentials() {
    console.log('🧪 Testing Authentication with Provided Credentials');
    console.log('==================================================');
    console.log(`📧 Email: ${EMAIL}`);
    console.log('');

    try {
        // Step 1: Test sign in
        console.log('1️⃣ Testing sign in...');
        const signInResponse = await axios.post(`${API_URL}/auth/signin`, {
            email: EMAIL,
            password: PASSWORD
        }, {
            headers: {
                'Content-Type': 'application/json'
            },
            timeout: 10000
        });

        if (signInResponse.data.success) {
            console.log('✅ Sign in successful!');
            console.log('User data:', signInResponse.data.user ? 'Present' : 'Missing');
            console.log('Business data:', signInResponse.data.businesses ? `${signInResponse.data.businesses.length} businesses` : 'Missing');
            
            const accessToken = signInResponse.data.data?.AccessToken;
            if (accessToken) {
                console.log(`🔑 Access token received: ${accessToken.substring(0, 30)}...`);
                
                // Step 2: Test discount management endpoint
                console.log('\n2️⃣ Testing discount management endpoint...');
                try {
                    const discountResponse = await axios.get(`${API_URL}/discounts`, {
                        headers: {
                            'Authorization': `Bearer ${accessToken}`,
                            'Content-Type': 'application/json'
                        }
                    });
                    
                    console.log('✅ Discount endpoint successful!');
                    console.log(`📋 Discounts found: ${discountResponse.data.discounts?.length || 0}`);
                    
                } catch (discountError) {
                    console.log('❌ Discount endpoint failed:');
                    console.log(`   Status: ${discountError.response?.status}`);
                    console.log(`   Message: ${discountError.response?.data?.message}`);
                }
                
                // Step 3: Test user businesses endpoint
                console.log('\n3️⃣ Testing user businesses endpoint...');
                try {
                    const businessResponse = await axios.get(`${API_URL}/auth/user-businesses`, {
                        headers: {
                            'Authorization': `Bearer ${accessToken}`,
                            'Content-Type': 'application/json'
                        }
                    });
                    
                    console.log('✅ User businesses endpoint successful!');
                    console.log(`🏢 Businesses found: ${businessResponse.data.businesses?.length || 0}`);
                    
                } catch (businessError) {
                    console.log('❌ User businesses endpoint failed:');
                    console.log(`   Status: ${businessError.response?.status}`);
                    console.log(`   Message: ${businessError.response?.data?.message}`);
                }
                
            } else {
                console.log('❌ No access token in response');
            }
            
        } else {
            console.log('❌ Sign in failed:', signInResponse.data.message);
        }

    } catch (error) {
        console.log('❌ Authentication test failed:');
        if (error.response) {
            console.log(`   Status: ${error.response.status}`);
            console.log(`   Data:`, error.response.data);
        } else {
            console.log(`   Error: ${error.message}`);
        }
    }
}

testAuthWithCredentials();
