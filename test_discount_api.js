const axios = require('axios');

// Configuration
const API_BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
const EMAIL = 'g87_a@yahoo.com';
const PASSWORD = 'Gha@551987';

async function testDiscountAPI() {
    console.log('🧪 Testing Discount Management API');
    console.log('==================================');
    console.log(`📧 Email: ${EMAIL}`);
    console.log(`🔗 API URL: ${API_BASE_URL}`);
    console.log('');

    try {
        // Step 1: Sign in to get access token
        console.log('1️⃣ Signing in...');
        const signInResponse = await axios.post(`${API_BASE_URL}/auth/signin`, {
            email: EMAIL,
            password: PASSWORD
        }, {
            headers: {
                'Content-Type': 'application/json'
            }
        });

        if (!signInResponse.data.success || !signInResponse.data.data.AccessToken) {
            throw new Error('Sign in failed: ' + (signInResponse.data.message || 'No access token received'));
        }

        const accessToken = signInResponse.data.data.AccessToken;
        console.log('✅ Successfully signed in');
        console.log(`🎫 Access token: ${accessToken.substring(0, 20)}...`);

        const headers = {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken}`
        };

        // Step 2: Test GET /discounts endpoint
        console.log('\n2️⃣ Testing GET /discounts...');
        try {
            const getDiscountsResponse = await axios.get(`${API_BASE_URL}/discounts`, {
                headers: headers
            });
            console.log('✅ GET /discounts successful');
            console.log('📊 Response:', JSON.stringify(getDiscountsResponse.data, null, 2));
        } catch (error) {
            console.log('❌ GET /discounts failed:', error.response?.status, error.response?.data);
        }

        // Step 3: Test creating a discount
        console.log('\n3️⃣ Testing POST /discounts...');
        const testDiscount = {
            title: 'Test Discount',
            description: 'A test discount for debugging',
            type: 'percentage',
            value: 10,
            applicability: 'allItems',
            validFrom: new Date().toISOString(),
            validTo: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7 days from now
            status: 'active'
        };

        try {
            const createDiscountResponse = await axios.post(`${API_BASE_URL}/discounts`, testDiscount, {
                headers: headers
            });
            console.log('✅ POST /discounts successful');
            console.log('📊 Response:', JSON.stringify(createDiscountResponse.data, null, 2));

            const createdDiscountId = createDiscountResponse.data.discount.discountId;

            // Step 4: Test GET specific discount
            console.log('\n4️⃣ Testing GET /discounts/{id}...');
            try {
                const getDiscountResponse = await axios.get(`${API_BASE_URL}/discounts/${createdDiscountId}`, {
                    headers: headers
                });
                console.log('✅ GET /discounts/{id} successful');
                console.log('📊 Response:', JSON.stringify(getDiscountResponse.data, null, 2));
            } catch (error) {
                console.log('❌ GET /discounts/{id} failed:', error.response?.status, error.response?.data);
            }

            // Step 5: Test discount validation
            console.log('\n5️⃣ Testing POST /discounts/validate-discount...');
            const validationData = {
                discountId: createdDiscountId,
                orderTotal: 100,
                items: [
                    { id: 'item-1', dishId: 'item-1', price: 50, quantity: 1 },
                    { id: 'item-2', dishId: 'item-2', price: 50, quantity: 1 }
                ]
            };

            try {
                const validateResponse = await axios.post(`${API_BASE_URL}/discounts/validate-discount`, validationData, {
                    headers: headers
                });
                console.log('✅ POST /discounts/validate-discount successful');
                console.log('📊 Response:', JSON.stringify(validateResponse.data, null, 2));
            } catch (error) {
                console.log('❌ POST /discounts/validate-discount failed:', error.response?.status, error.response?.data);
            }

            // Step 6: Test discount stats
            console.log('\n6️⃣ Testing GET /discounts/stats...');
            try {
                const statsResponse = await axios.get(`${API_BASE_URL}/discounts/stats`, {
                    headers: headers
                });
                console.log('✅ GET /discounts/stats successful');
                console.log('📊 Response:', JSON.stringify(statsResponse.data, null, 2));
            } catch (error) {
                console.log('❌ GET /discounts/stats failed:', error.response?.status, error.response?.data);
            }

            // Step 7: Clean up - delete the test discount
            console.log('\n7️⃣ Cleaning up test discount...');
            try {
                const deleteResponse = await axios.delete(`${API_BASE_URL}/discounts/${createdDiscountId}`, {
                    headers: headers
                });
                console.log('✅ DELETE /discounts/{id} successful');
                console.log('📊 Response:', JSON.stringify(deleteResponse.data, null, 2));
            } catch (error) {
                console.log('❌ DELETE /discounts/{id} failed:', error.response?.status, error.response?.data);
            }

        } catch (error) {
            console.log('❌ POST /discounts failed:', error.response?.status, error.response?.data);
        }

    } catch (error) {
        console.error('💥 Test failed:', error.message);
        if (error.response) {
            console.error('Status:', error.response.status);
            console.error('Data:', error.response.data);
        }
    }
}

// Run the test
testDiscountAPI().catch(console.error);
