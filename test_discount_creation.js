const axios = require('axios');
const fs = require('fs');

// Configuration
const baseUrl = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

async function testDiscountCreation() {
    try {
        console.log('🔍 Testing Discount Creation');
        console.log('='.repeat(50));

        // Read access token
        let token;
        try {
            token = fs.readFileSync('access_token.txt', 'utf8').trim();
            console.log(`✅ Access token loaded: ${token.substring(0, 20)}...`);
        } catch (error) {
            console.log('❌ Failed to read access token file:', error.message);
            return;
        }

        const authHeader = `Bearer ${token}`;

        // Test discount data - simple percentage discount
        const testDiscountData = {
            title: "Test Discount",
            description: "A test discount for debugging",
            type: "percentage",
            value: 10.0,
            applicability: "allItems",
            applicableItemIds: [],
            applicableCategoryIds: [],
            minimumOrderAmount: 0.0,
            validFrom: new Date().toISOString(),
            validTo: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7 days from now
            usageLimit: null,
            usageCount: 0,
            status: "active",
            conditionalRule: null,
            conditionalParameters: {}
        };

        console.log('\n📤 Sending discount data:');
        console.log(JSON.stringify(testDiscountData, null, 2));

        console.log('\n🚀 Testing POST /discounts endpoint...');
        try {
            const response = await axios.post(`${baseUrl}/discounts`, testDiscountData, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': authHeader
                }
            });

            console.log(`✅ Discount creation status: ${response.status}`);
            console.log(`📋 Response:`, JSON.stringify(response.data, null, 2));
        } catch (error) {
            console.log(`❌ Discount creation failed: ${error.response?.status} - ${error.response?.statusText}`);
            if (error.response?.data) {
                console.log(`📄 Error response:`, JSON.stringify(error.response.data, null, 2));
            }
            console.log(`🔍 Full error:`, error.message);
        }

    } catch (error) {
        console.error('💥 Unexpected error:', error.message);
    }
}

// Run the test
testDiscountCreation();
