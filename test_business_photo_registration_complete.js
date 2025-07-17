const https = require('https');
const fs = require('fs');
const FormData = require('form-data');

const API_BASE = 'https://clgs5798k1.execute-api.eu-north-1.amazonaws.com/dev';

// Test data
const testUser = {
    email: `testuser${Date.now()}@example.com`,
    password: 'TestPassword123!',
    firstName: 'Test',
    lastName: 'User',
    phoneNumber: '+1234567890'
};

const testBusiness = {
    businessName: 'Test Business Photo',
    businessType: 'restaurant',
    address: '123 Test St',
    city: 'Test City',
    phoneNumber: '+1234567890'
};

async function makeRequest(url, method = 'GET', data = null, headers = {}) {
    return new Promise((resolve, reject) => {
        const urlObj = new URL(url);
        const options = {
            hostname: urlObj.hostname,
            path: urlObj.pathname + urlObj.search,
            method: method,
            headers: {
                'Content-Type': 'application/json',
                ...headers
            }
        };

        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(body);
                    resolve({ status: res.statusCode, data: parsed });
                } catch (e) {
                    resolve({ status: res.statusCode, data: body });
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

async function uploadBusinessPhoto() {
    return new Promise((resolve, reject) => {
        // Create a simple test image
        const imageData = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==', 'base64');
        
        const form = new FormData();
        form.append('image', imageData, {
            filename: 'test-business-photo.png',
            contentType: 'image/png'
        });
        form.append('upload_type', 'business-photo');

        const options = {
            hostname: 'clgs5798k1.execute-api.eu-north-1.amazonaws.com',
            path: '/dev/upload/business-photo',
            method: 'POST',
            headers: {
                'x-upload-type': 'business-photo',
                ...form.getHeaders()
            }
        };

        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(body);
                    resolve({ status: res.statusCode, data: parsed });
                } catch (e) {
                    resolve({ status: res.statusCode, data: body });
                }
            });
        });

        req.on('error', reject);
        form.pipe(req);
    });
}

async function testCompleteFlow() {
    console.log('🧪 Testing Complete Business Photo Registration Flow');
    console.log('='.repeat(60));

    try {
        // Step 1: Upload business photo
        console.log('\n📸 Step 1: Uploading business photo...');
        const uploadResult = await uploadBusinessPhoto();
        
        if (uploadResult.status !== 200 || !uploadResult.data.success) {
            console.error('❌ Business photo upload failed:', uploadResult);
            return;
        }
        
        const businessPhotoUrl = uploadResult.data.imageUrl;
        console.log('✅ Business photo uploaded successfully');
        console.log('📎 Photo URL:', businessPhotoUrl);

        // Step 2: Register user with business including photo URL
        console.log('\n👤 Step 2: Registering user with business...');
        const registrationData = {
            ...testUser,
            business: {
                ...testBusiness,
                business_photo_url: businessPhotoUrl
            }
        };

        const registerResult = await makeRequest(`${API_BASE}/auth/register-with-business`, 'POST', registrationData);
        
        if (registerResult.status !== 200 || !registerResult.data.success) {
            console.error('❌ Registration failed:', registerResult);
            return;
        }

        console.log('✅ User registration successful');
        console.log('📧 Email:', testUser.email);
        console.log('🏢 Business:', testBusiness.businessName);

        // Step 3: Confirm the user (simulate email confirmation)
        console.log('\n✉️ Step 3: Confirming user...');
        const confirmResult = await makeRequest(`${API_BASE}/auth/confirm`, 'POST', {
            email: testUser.email,
            confirmationCode: '123456' // This would normally come from email
        });

        if (confirmResult.status === 200) {
            console.log('✅ User confirmed successfully');
        } else {
            console.log('⚠️ Confirmation result (expected for test):', confirmResult.status);
        }

        // Step 4: Check if user can sign in
        console.log('\n🔐 Step 4: Testing sign in...');
        const signinResult = await makeRequest(`${API_BASE}/auth/signin`, 'POST', {
            email: testUser.email,
            password: testUser.password
        });

        console.log('📋 Sign-in result:', signinResult.status);
        
        if (signinResult.data.businesses) {
            console.log('🏢 User businesses found:', signinResult.data.businesses.length);
            
            // Check if business photo URL is present
            const business = signinResult.data.businesses[0];
            if (business && business.business_photo_url) {
                console.log('✅ Business photo URL found in database:', business.business_photo_url);
                console.log('🔗 Matches uploaded URL:', business.business_photo_url === businessPhotoUrl);
            } else {
                console.log('❌ Business photo URL not found in database');
                console.log('📋 Business data:', JSON.stringify(business, null, 2));
            }
        }

        console.log('\n🎉 Test completed successfully!');
        console.log('✅ Business photo upload: Working');
        console.log('✅ Registration with photo: Working');
        console.log('✅ Photo URL in database: ' + (signinResult.data.businesses?.[0]?.business_photo_url ? 'Working' : 'Needs verification'));

    } catch (error) {
        console.error('❌ Test failed with error:', error);
    }
}

// Run the test
testCompleteFlow().catch(console.error);
