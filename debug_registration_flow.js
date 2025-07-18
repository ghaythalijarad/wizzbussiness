const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');

const BASE_URL = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';

console.log('🚀 Starting debug registration flow...');

async function debugRegistrationFlow() {
    const testEmail = `flow_test_${Date.now()}@example.com`;
    console.log('🔍 DEBUGGING REGISTRATION FLOW');
    console.log('===============================');
    console.log(`Test Email: ${testEmail}`);
    
    try {
        // Step 1: Upload business photo (similar to what Flutter does)
        console.log('\n1️⃣ STEP 1: Upload Business Photo');
        console.log('--------------------------------');
        
        // Create a test image file (1x1 pixel PNG)
        const testImageBuffer = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAHGg2hpgAAAAABJRU5ErkJggg==', 'base64');
        
        const formData = new FormData();
        formData.append('image', testImageBuffer, {
            filename: 'test-business.png',
            contentType: 'image/png'
        });
        formData.append('upload_type', 'business-photo');
        
        const uploadResponse = await axios.post(
            `${BASE_URL}/upload/product-image`,
            formData,
            {
                headers: {
                    ...formData.getHeaders(),
                    'x-upload-type': 'business-photo'
                }
            }
        );
        
        console.log('✅ Upload Response Status:', uploadResponse.status);
        console.log('📷 Upload Response:', uploadResponse.data);
        
        const businessPhotoUrl = uploadResponse.data.imageUrl;
        if (!businessPhotoUrl) {
            throw new Error('No imageUrl in upload response');
        }
        
        // Step 2: Register with business data (including photo URL)
        console.log('\n2️⃣ STEP 2: Register with Business Data');
        console.log('---------------------------------------');
        
        const registrationData = {
            email: testEmail,
            password: 'TestPass123!',
            businessName: 'Test Business Flow',
            businessType: 'restaurant',
            phoneNumber: '07712345678',
            firstName: 'Flow',
            lastName: 'Test',
            address: 'Test Address',
            city: 'Baghdad',
            district: 'Test District',
            country: 'Iraq',
            street: 'Test Street',
            businessPhotoUrl: businessPhotoUrl // ⚠️ KEY FIELD
        };
        
        console.log('📋 Registration Data:');
        console.log(JSON.stringify(registrationData, null, 2));
        
        const registerResponse = await axios.post(
            `${BASE_URL}/auth/register-with-business`,
            registrationData
        );
        
        console.log('✅ Registration Response Status:', registerResponse.status);
        console.log('📝 Registration Response:', registerResponse.data);
        
        // Step 3: Check DynamoDB to verify the business_photo_url was saved
        console.log('\n3️⃣ STEP 3: Verify Database Storage');
        console.log('----------------------------------');
        
        // Give a moment for DynamoDB to update
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        // We can't directly query DynamoDB from here, but we can check the logs
        console.log('🔍 To verify, check DynamoDB with:');
        console.log(`aws dynamodb scan --table-name order-receiver-businesses-dev --region us-east-1 --filter-expression "email = :email" --expression-attribute-values '{":email":{"S":"${testEmail}"}}' --projection-expression "email, business_photo_url" --no-cli-pager`);
        
        console.log('\n✅ REGISTRATION FLOW TEST COMPLETED');
        console.log('===================================');
        console.log('Expected: business_photo_url should be saved in DynamoDB');
        console.log(`Photo URL: ${businessPhotoUrl}`);
        
    } catch (error) {
        console.error('\n❌ REGISTRATION FLOW FAILED');
        console.error('============================');
        console.error('Error:', error.message);
        if (error.response) {
            console.error('Status:', error.response.status);
            console.error('Data:', error.response.data);
        }
    }
}

debugRegistrationFlow().catch(console.error);
