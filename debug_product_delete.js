const axios = require('axios');

async function debugProductDelete() {
    console.log('🧪 Debug Product Delete Issue');
    console.log('==============================\n');

    const baseUrl = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
    
    // First, let's try to sign in and get a valid token
    try {
        console.log('1. Signing in to get access token...');
        const signInResponse = await axios.post(`${baseUrl}/auth/signin`, {
            email: 'zikbiot@yahoo.com',
            password: 'Gha@551987'
        });

        if (signInResponse.data.success) {
            console.log('✅ Sign in successful');
            const accessToken = signInResponse.data.data.AccessToken;
            console.log(`📝 Access Token (first 20 chars): ${accessToken.substring(0, 20)}...`);
            console.log(`📏 Access Token length: ${accessToken.length}`);
            
            // Check for any invalid characters in the token
            const invalidChars = accessToken.match(/[^A-Za-z0-9._-]/g);
            if (invalidChars) {
                console.log(`⚠️ Found potentially invalid characters: ${invalidChars.join(', ')}`);
            } else {
                console.log('✅ Token contains only valid characters');
            }

            // Test the authorization header format
            const authHeader = `Bearer ${accessToken}`;
            console.log(`🔑 Authorization header format: ${authHeader.substring(0, 30)}...`);

            // Get products to find one to delete
            console.log('\n2. Getting products list...');
            const productsResponse = await axios.get(`${baseUrl}/products`, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': authHeader
                }
            });

            if (productsResponse.data.success && productsResponse.data.products.length > 0) {
                const testProduct = productsResponse.data.products[0];
                console.log(`✅ Found test product: ${testProduct.name} (ID: ${testProduct.productId})`);

                // Try to delete the product
                console.log('\n3. Attempting to delete product...');
                console.log(`📡 DELETE ${baseUrl}/products/${testProduct.productId}`);
                console.log(`🔑 Authorization: ${authHeader.substring(0, 30)}...`);

                try {
                    const deleteResponse = await axios.delete(`${baseUrl}/products/${testProduct.productId}`, {
                        headers: {
                            'Content-Type': 'application/json',
                            'Authorization': authHeader
                        }
                    });

                    console.log('✅ Delete successful!');
                    console.log(`📤 Response: ${JSON.stringify(deleteResponse.data)}`);
                } catch (deleteError) {
                    console.log('❌ Delete failed!');
                    if (deleteError.response) {
                        console.log(`📤 Status: ${deleteError.response.status}`);
                        console.log(`📤 Response: ${JSON.stringify(deleteError.response.data)}`);
                        console.log(`📤 Headers sent:`, deleteError.config.headers);
                    } else {
                        console.log(`📤 Error: ${deleteError.message}`);
                    }
                }
            } else {
                console.log('❌ No products found to test delete');
            }

        } else {
            console.log('❌ Sign in failed');
            console.log(`📤 Response: ${JSON.stringify(signInResponse.data)}`);
        }

    } catch (error) {
        console.log('❌ Error during debug:');
        if (error.response) {
            console.log(`📤 Status: ${error.response.status}`);
            console.log(`📤 Response: ${JSON.stringify(error.response.data)}`);
        } else {
            console.log(`📤 Error: ${error.message}`);
        }
    }
}

debugProductDelete().catch(console.error);
