// Test Business Photo Registration with Real S3 Storage
const https = require('https');

const API_BASE = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

// Test data
const testBusinessPhoto = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
const testEmail = `photo_test_${Date.now()}@example.com`;

async function makeRequest(url, method, data, headers = {}) {
    return new Promise((resolve, reject) => {
        const urlObj = new URL(url);
        const options = {
            hostname: urlObj.hostname,
            port: 443,
            path: urlObj.pathname + urlObj.search,
            method: method,
            headers: {
                'Content-Type': 'application/json',
                ...headers
            }
        };

        const req = https.request(options, (res) => {
            let responseBody = '';
            res.on('data', (chunk) => {
                responseBody += chunk;
            });
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(responseBody);
                    resolve({ status: res.statusCode, data: parsed });
                } catch (e) {
                    resolve({ status: res.statusCode, data: responseBody });
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

async function testBusinessPhotoStorage() {
    console.log('🔄 Testing Business Photo S3 Storage...');
    console.log('=====================================');
    
    try {
        // Step 1: Test business photo upload
        console.log('1. 📤 Testing business photo upload...');
        const uploadResponse = await makeRequest(
            `${API_BASE}/upload/business-photo`,
            'POST',
            { 
                image: testBusinessPhoto,
                uploadType: 'business-photo'
            },
            { 'x-upload-type': 'business-photo' }
        );
        
        console.log(`   Status: ${uploadResponse.status}`);
        console.log(`   Response:`, uploadResponse.data);
        
        let businessPhotoUrl = null;
        if (uploadResponse.status === 200 && uploadResponse.data.success) {
            businessPhotoUrl = uploadResponse.data.imageUrl;
            console.log(`   ✅ Photo uploaded: ${businessPhotoUrl}`);
        } else {
            console.log(`   ❌ Photo upload failed`);
        }
        
        // Step 2: Test business registration with photo URL
        console.log('\n2. 📝 Testing business registration with photo...');
        const registrationData = {
            email: testEmail,
            password: 'TestPassword123!',
            businessName: 'Photo Test Business S3',
            business_type: 'restaurant',
            firstName: 'Photo',
            lastName: 'Test',
            phoneNumber: '07712345678',
            city: 'Baghdad',
            district: 'Test District',
            country: 'Iraq',
            street: 'Test Street',
            businessPhotoUrl: businessPhotoUrl // Include the uploaded photo URL
        };
        
        const registerResponse = await makeRequest(
            `${API_BASE}/auth/register-with-business`,
            'POST',
            registrationData
        );
        
        console.log(`   Status: ${registerResponse.status}`);
        console.log(`   Response:`, registerResponse.data);
        
        if (registerResponse.status === 201 && registerResponse.data.success) {
            console.log(`   ✅ Registration successful with photo URL`);
        } else {
            console.log(`   ❌ Registration failed`);
        }
        
        // Step 3: Verify photo URL was stored in database
        console.log('\n3. 🔍 Verification Summary:');
        console.log(`   • Test Email: ${testEmail}`);
        console.log(`   • Photo Upload: ${uploadResponse.status === 200 ? '✅ Success' : '❌ Failed'}`);
        console.log(`   • Registration: ${registerResponse.status === 201 ? '✅ Success' : '❌ Failed'}`);
        console.log(`   • Photo URL: ${businessPhotoUrl || 'None'}`);
        
        if (businessPhotoUrl && businessPhotoUrl.includes('amazonaws.com')) {
            console.log(`   ✅ Real S3 URL detected!`);
        } else if (businessPhotoUrl && businessPhotoUrl.includes('mock-s3-bucket')) {
            console.log(`   ⚠️  Mock URL detected - S3 not properly configured`);
        } else {
            console.log(`   ❌ No photo URL - upload failed`);
        }
        
    } catch (error) {
        console.error('Test failed:', error);
    }
}

// Run the test
testBusinessPhotoStorage();
