const AWS = require('aws-sdk');
const fs = require('fs');
const FormData = require('form-data');
const axios = require('axios');
const path = require('path');

// Configure AWS
AWS.config.update({
    region: 'us-east-1'
});

const s3 = new AWS.S3();

async function testImageUpload() {
    console.log('🧪 Starting comprehensive image upload test...\n');

    // API endpoints for image upload
    const businessPhotoEndpoint = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/upload/business-photo';
    const productImageEndpoint = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/upload/product-image';
    
    // Get access token
    const fs = require('fs');
    let accessToken = '';
    try {
        accessToken = fs.readFileSync('/Users/ghaythallaheebi/order-receiver-app-2/access_token.txt', 'utf8').trim();
        console.log('📋 Using saved access token for authentication');
    } catch (error) {
        console.log('⚠️ No access token found, testing without authentication');
    }
    
    // Test with both PNG and JPG images for both endpoints
    const testCases = [
        { file: 'test_image.png', expectedType: 'image/png', expectedExt: 'png', endpoint: businessPhotoEndpoint, type: 'business-photo', needsAuth: false },
        { file: 'test_image.jpg', expectedType: 'image/jpeg', expectedExt: 'jpg', endpoint: businessPhotoEndpoint, type: 'business-photo', needsAuth: false },
        { file: 'test_image.png', expectedType: 'image/png', expectedExt: 'png', endpoint: productImageEndpoint, type: 'product-image', needsAuth: true },
        { file: 'test_image.jpg', expectedType: 'image/jpeg', expectedExt: 'jpg', endpoint: productImageEndpoint, type: 'product-image', needsAuth: true }
    ];

    for (const testCase of testCases) {
        console.log(`📤 Testing upload of ${testCase.file} to ${testCase.type} endpoint...`);
        
        // Skip auth-required tests if no token
        if (testCase.needsAuth && !accessToken) {
            console.log(`⚠️ Skipping ${testCase.type} test - requires authentication`);
            continue;
        }
        
        try {
            // Check if test image exists
            if (!fs.existsSync(testCase.file)) {
                console.log(`⚠️ Test image ${testCase.file} not found, skipping...`);
                continue;
            }

            // Create form data
            const form = new FormData();
            form.append('image', fs.createReadStream(testCase.file));
            if (testCase.type === 'business-photo') {
                form.append('upload_type', 'business-photo');
            }

            // Prepare headers
            const headers = {
                ...form.getHeaders(),
                'Content-Type': 'multipart/form-data'
            };
            
            if (testCase.needsAuth && accessToken) {
                headers['Authorization'] = `Bearer ${accessToken}`;
            }
            
            if (testCase.type === 'business-photo') {
                headers['x-upload-type'] = 'business-photo';
            }

            // Upload image
            const response = await axios.post(testCase.endpoint, form, {
                headers: headers,
                timeout: 30000
            });

            if (response.status === 200 && response.data.success) {
                const imageUrl = response.data.imageUrl;
                console.log(`✅ Upload successful: ${imageUrl}`);

                // Extract S3 key from URL
                const urlParts = new URL(imageUrl);
                const s3Key = urlParts.pathname.substring(1); // Remove leading slash

                // Check S3 metadata
                console.log(`🔍 Checking S3 metadata for key: ${s3Key}`);
                
                try {
                    const headResult = await s3.headObject({
                        Bucket: 'order-receiver-business-photos-dev',
                        Key: s3Key
                    }).promise();

                    const actualContentType = headResult.ContentType;
                    const actualExtension = path.extname(s3Key).toLowerCase();

                    console.log(`📋 S3 Metadata:`);
                    console.log(`   Content-Type: ${actualContentType}`);
                    console.log(`   File Extension: ${actualExtension}`);
                    console.log(`   Expected Content-Type: ${testCase.expectedType}`);
                    console.log(`   Expected Extension: .${testCase.expectedExt}`);

                    // Verify content type
                    if (actualContentType === testCase.expectedType) {
                        console.log(`✅ Content-Type is correct!`);
                    } else {
                        console.log(`❌ Content-Type mismatch! Expected: ${testCase.expectedType}, Got: ${actualContentType}`);
                    }

                    // Verify file extension
                    if (actualExtension === `.${testCase.expectedExt}`) {
                        console.log(`✅ File extension is correct!`);
                    } else {
                        console.log(`❌ File extension mismatch! Expected: .${testCase.expectedExt}, Got: ${actualExtension}`);
                    }

                } catch (s3Error) {
                    console.log(`❌ Error checking S3 metadata: ${s3Error.message}`);
                }

            } else {
                console.log(`❌ Upload failed: ${response.data.message || 'Unknown error'}`);
            }

        } catch (error) {
            console.log(`❌ Error uploading ${testCase.file} to ${testCase.type}: ${error.message}`);
            if (error.response) {
                console.log(`   Response status: ${error.response.status}`);
                console.log(`   Response data: ${JSON.stringify(error.response.data)}`);
            }
        }

        console.log(''); // Empty line for readability
    }
}

async function checkExistingImages() {
    console.log('🔍 Checking existing images in S3 bucket...\n');

    try {
        const listResult = await s3.listObjectsV2({
            Bucket: 'order-receiver-business-photos-dev',
            MaxKeys: 10 // Just check a few recent ones
        }).promise();

        if (listResult.Contents && listResult.Contents.length > 0) {
            console.log(`Found ${listResult.Contents.length} objects in bucket:`);

            for (const obj of listResult.Contents.slice(0, 5)) { // Check first 5
                try {
                    const headResult = await s3.headObject({
                        Bucket: 'order-receiver-app-images',
                        Key: obj.Key
                    }).promise();

                    const extension = path.extname(obj.Key).toLowerCase();
                    console.log(`📄 ${obj.Key}`);
                    console.log(`   Content-Type: ${headResult.ContentType}`);
                    console.log(`   Extension: ${extension}`);
                    console.log(`   Size: ${obj.Size} bytes`);
                    console.log(`   Last Modified: ${obj.LastModified}`);
                    console.log('');
                } catch (error) {
                    console.log(`❌ Error getting metadata for ${obj.Key}: ${error.message}`);
                }
            }
        } else {
            console.log('No objects found in bucket');
        }

    } catch (error) {
        console.log(`❌ Error listing S3 objects: ${error.message}`);
    }
}

async function main() {
    console.log('🚀 Image Upload Fix Verification\n');
    console.log('This test will:');
    console.log('1. Upload test images (PNG and JPG)');
    console.log('2. Verify S3 metadata shows correct content types');
    console.log('3. Check existing images in the bucket\n');

    // First check existing images
    await checkExistingImages();

    // Then test new uploads
    await testImageUpload();

    console.log('🏁 Test completed!');
}

// Handle errors
process.on('unhandledRejection', (error) => {
    console.error('Unhandled promise rejection:', error);
    process.exit(1);
});

// Run the test
main().catch(console.error);
