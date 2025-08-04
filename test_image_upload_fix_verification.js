const AWS = require('aws-sdk');
const fs = require('fs');
const FormData = require('form-data');
const axios = require('axios');

async function testImageUploadAfterFix() {
    console.log('🔧 Testing Image Upload After Binary Handling Fix\n');

    // Test with a fresh new product image upload
    let accessToken;
    try {
        accessToken = fs.readFileSync('/Users/ghaythallaheebi/order-receiver-app-2/access_token.txt', 'utf8').trim();
        console.log('✅ Access token loaded');
    } catch (error) {
        console.log('❌ Failed to load access token:', error.message);
        return;
    }
    
    console.log('📤 Testing upload with fixed handler...');
    
    try {
        // Check if test image exists
        if (!fs.existsSync('test_image.jpg')) {
            console.log('⚠️ test_image.jpg not found, skipping test...');
            return;
        }
        console.log('✅ Test image found');

        // Create form data
        const form = new FormData();
        form.append('image', fs.createReadStream('test_image.jpg'));
        console.log('✅ Form data created');

        // Upload to product image endpoint (with auth)
        console.log('🚀 Sending upload request...');
        const response = await axios.post(
            'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/upload/product-image',
            form,
            {
                headers: {
                    ...form.getHeaders(),
                    'Authorization': `Bearer ${accessToken}`
                },
                timeout: 30000
            }
        );
        console.log('✅ Upload request completed');

        if (response.status === 200 && response.data.success) {
            const imageUrl = response.data.imageUrl;
            console.log(`✅ Upload successful: ${imageUrl}`);

            // Now test if the uploaded image is valid by downloading first few bytes
            console.log('🔍 Testing image validity...');
            
            try {
                const imageResponse = await axios.get(imageUrl, {
                    responseType: 'arraybuffer',
                    headers: {
                        'Range': 'bytes=0-19'  // First 20 bytes
                    }
                });

                const buffer = Buffer.from(imageResponse.data);
                console.log('📋 First 20 bytes of uploaded image:');
                console.log(buffer.toString('hex'));
                
                // Check for valid JPEG header (FF D8)
                if (buffer[0] === 0xFF && buffer[1] === 0xD8) {
                    console.log('✅ Valid JPEG header detected!');
                    console.log('🎉 Image upload fix is working correctly!');
                } else {
                    console.log('❌ Invalid JPEG header detected');
                    console.log(`Got: ${buffer[0].toString(16)} ${buffer[1].toString(16)}, Expected: FF D8`);
                }

            } catch (downloadError) {
                console.log(`❌ Error downloading image: ${downloadError.message}`);
            }

        } else {
            console.log(`❌ Upload failed: ${response.data.message || 'Unknown error'}`);
        }

    } catch (error) {
        console.log(`❌ Error: ${error.message}`);
        if (error.response) {
            console.log(`   Status: ${error.response.status}`);
            console.log(`   Data: ${JSON.stringify(error.response.data)}`);
        }
    }
}

// Run the test
testImageUploadAfterFix().catch(console.error);
