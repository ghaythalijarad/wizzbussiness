// Test login with provided credentials
const axios = require('axios');

async function testLogin() {
    console.log('🧪 Testing Login with Provided Credentials');
    console.log('==========================================');
    
    const email = 'g87_a@yahoo.com';
    const password = 'Gha@551987';
    const baseUrl = 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev';
    
    try {
        console.log(`\n📧 Testing login for: ${email}`);
        console.log(`🌐 Backend URL: ${baseUrl}`);
        
        // Test 1: Check if email exists
        console.log('\n1️⃣ Checking if email exists...');
        try {
            const checkEmailResponse = await axios.post(`${baseUrl}/auth/check-email`, {
                email: email
            });
            console.log('✅ Email check response:', checkEmailResponse.data);
        } catch (emailError) {
            console.log('❌ Email check error:', emailError.response?.data || emailError.message);
        }
        
        // Test 2: Attempt login
        console.log('\n2️⃣ Attempting login...');
        const loginResponse = await axios.post(`${baseUrl}/auth/signin`, {
            email: email,
            password: password
        }, {
            headers: {
                'Content-Type': 'application/json'
            },
            timeout: 10000
        });
        
        console.log('✅ Login successful!');
        console.log('Response status:', loginResponse.status);
        console.log('Response data:', JSON.stringify(loginResponse.data, null, 2));
        
        // Check if we got authentication tokens
        if (loginResponse.data.data) {
            console.log('\n🎫 Authentication tokens received:');
            console.log('- Access Token:', loginResponse.data.data.AccessToken ? '✅ Present' : '❌ Missing');
            console.log('- ID Token:', loginResponse.data.data.IdToken ? '✅ Present' : '❌ Missing');
            console.log('- Refresh Token:', loginResponse.data.data.RefreshToken ? '✅ Present' : '❌ Missing');
        }
        
        // Check if we got user data
        if (loginResponse.data.user) {
            console.log('\n👤 User data received:');
            console.log('- User ID:', loginResponse.data.user.userId || 'Not provided');
            console.log('- Email:', loginResponse.data.user.email || 'Not provided');
            console.log('- Email Verified:', loginResponse.data.user.email_verified || 'Not provided');
        }
        
        // Check if we got business data
        if (loginResponse.data.businesses) {
            console.log('\n🏢 Business data received:');
            console.log('- Number of businesses:', loginResponse.data.businesses.length);
            if (loginResponse.data.businesses.length > 0) {
                console.log('- First business:', loginResponse.data.businesses[0].business_name || 'Name not provided');
            }
        }
        
    } catch (error) {
        console.log('\n❌ Login failed');
        console.log('Error status:', error.response?.status || 'No status');
        console.log('Error data:', JSON.stringify(error.response?.data || error.message, null, 2));
        
        if (error.response?.status === 401) {
            console.log('\n🔍 Analysis: Invalid credentials or unverified email');
            console.log('Possible causes:');
            console.log('- Incorrect password');
            console.log('- Email not verified');
            console.log('- User does not exist');
        } else if (error.response?.status === 400) {
            console.log('\n🔍 Analysis: Bad request');
            console.log('Possible causes:');
            console.log('- Missing email or password');
            console.log('- Invalid email format');
        } else if (error.response?.status >= 500) {
            console.log('\n🔍 Analysis: Server error');
            console.log('Possible causes:');
            console.log('- Backend service issue');
            console.log('- AWS Cognito service issue');
            console.log('- DynamoDB connection issue');
        }
    }
}

testLogin().catch(console.error);
