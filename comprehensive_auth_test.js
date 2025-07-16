const AWS = require('aws-sdk');
const axios = require('axios');

// Configure AWS
const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });

const CONFIG = {
    USER_POOL_ID: 'us-east-1_bDqnKdrqo',
    CLIENT_ID: '6n752vrmqmbss6nmlg6be2nn9a',
    BACKEND_URL: 'https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev',
    TEST_EMAIL: 'test_auth_' + Date.now() + '@example.com',
    TEST_PASSWORD: 'TestPass123!',
    EXISTING_EMAIL: 'g87_a@yahoo.com',
    EXISTING_PASSWORD: 'Gha@551987'
};

console.log('🧪 COMPREHENSIVE AUTHENTICATION TEST');
console.log('===================================');
console.log(`Backend URL: ${CONFIG.BACKEND_URL}`);
console.log(`Test Email: ${CONFIG.TEST_EMAIL}`);
console.log(`Existing Email: ${CONFIG.EXISTING_EMAIL}`);
console.log('');

async function testBackendHealth() {
    console.log('1️⃣ TESTING BACKEND HEALTH');
    console.log('========================');
    
    try {
        const response = await axios.get(`${CONFIG.BACKEND_URL}/auth/health`);
        console.log('✅ Backend health check:', response.data);
        return true;
    } catch (error) {
        console.log('❌ Backend health check failed:', error.message);
        return false;
    }
}

async function testRegistration() {
    console.log('\n2️⃣ TESTING REGISTRATION');
    console.log('======================');
    
    const registrationData = {
        email: CONFIG.TEST_EMAIL,
        password: CONFIG.TEST_PASSWORD,
        businessName: 'Test Business',
        businessType: 'restaurant',
        phoneNumber: '07712345678',
        firstName: 'Test',
        lastName: 'User',
        address: 'Test Address',
        city: 'Baghdad',
        district: 'Test District',
        country: 'Iraq'
    };
    
    try {
        console.log('📝 Testing backend registration...');
        const response = await axios.post(`${CONFIG.BACKEND_URL}/auth/register-with-business`, registrationData);
        console.log('✅ Registration successful:', response.data);
        
        if (response.data.success) {
            console.log('   - User Sub:', response.data.user_sub);
            console.log('   - Business ID:', response.data.business_id);
            console.log('   - Code delivery:', response.data.code_delivery_details);
        }
        
        return {
            success: true,
            userSub: response.data.user_sub,
            businessId: response.data.business_id
        };
    } catch (error) {
        console.log('❌ Registration failed:');
        if (error.response) {
            console.log('   Status:', error.response.status);
            console.log('   Data:', error.response.data);
        } else {
            console.log('   Error:', error.message);
        }
        return { success: false };
    }
}

async function testEmailCheck() {
    console.log('\n3️⃣ TESTING EMAIL CHECK');
    console.log('=====================');
    
    try {
        // Test existing email
        console.log('📧 Testing existing email check...');
        let response = await axios.post(`${CONFIG.BACKEND_URL}/auth/check-email`, {
            email: CONFIG.EXISTING_EMAIL
        });
        console.log('✅ Existing email check:', response.data);
        
        // Test new email
        console.log('📧 Testing new email check...');
        response = await axios.post(`${CONFIG.BACKEND_URL}/auth/check-email`, {
            email: 'nonexistent_' + Date.now() + '@example.com'
        });
        console.log('✅ New email check:', response.data);
        
        return true;
    } catch (error) {
        console.log('❌ Email check failed:');
        if (error.response) {
            console.log('   Status:', error.response.status);
            console.log('   Data:', error.response.data);
        } else {
            console.log('   Error:', error.message);
        }
        return false;
    }
}

async function testExistingUserLogin() {
    console.log('\n4️⃣ TESTING EXISTING USER LOGIN');
    console.log('==============================');
    
    try {
        console.log('🔐 Testing backend login with existing user...');
        const response = await axios.post(`${CONFIG.BACKEND_URL}/auth/signin`, {
            email: CONFIG.EXISTING_EMAIL,
            password: CONFIG.EXISTING_PASSWORD
        });
        console.log('✅ Login successful:', response.data);
        return { success: true, data: response.data };
    } catch (error) {
        console.log('❌ Login failed:');
        if (error.response) {
            console.log('   Status:', error.response.status);
            console.log('   Data:', error.response.data);
        } else {
            console.log('   Error:', error.message);
        }
        return { success: false, error: error.response?.data || error.message };
    }
}

async function testDirectCognitoAuth() {
    console.log('\n5️⃣ TESTING DIRECT COGNITO AUTH');
    console.log('=============================');
    
    try {
        console.log('🔐 Testing direct Cognito authentication...');
        const authParams = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: CONFIG.CLIENT_ID,
            AuthParameters: {
                USERNAME: CONFIG.EXISTING_EMAIL,
                PASSWORD: CONFIG.EXISTING_PASSWORD
            }
        };
        
        const response = await cognito.initiateAuth(authParams).promise();
        console.log('✅ Direct Cognito auth successful!');
        console.log('   - Challenge:', response.ChallengeName || 'None');
        console.log('   - Has tokens:', !!response.AuthenticationResult);
        return { success: true };
    } catch (error) {
        console.log('❌ Direct Cognito auth failed:');
        console.log('   Code:', error.code);
        console.log('   Message:', error.message);
        return { success: false, error: error };
    }
}

async function testPasswordReset() {
    console.log('\n6️⃣ TESTING PASSWORD RESET FLOW');
    console.log('=============================');
    
    try {
        console.log('📧 Testing forgot password initiation...');
        const response = await cognito.forgotPassword({
            ClientId: CONFIG.CLIENT_ID,
            Username: CONFIG.EXISTING_EMAIL
        }).promise();
        
        console.log('✅ Password reset initiated successfully!');
        console.log('   - Delivery details:', response.CodeDeliveryDetails);
        return { success: true };
    } catch (error) {
        console.log('❌ Password reset failed:');
        console.log('   Code:', error.code);
        console.log('   Message:', error.message);
        return { success: false };
    }
}

async function testCognitoUserStatus() {
    console.log('\n7️⃣ TESTING COGNITO USER STATUS');
    console.log('==============================');
    
    try {
        console.log('👤 Getting user details from Cognito...');
        const response = await cognito.adminGetUser({
            UserPoolId: CONFIG.USER_POOL_ID,
            Username: CONFIG.EXISTING_EMAIL
        }).promise();
        
        console.log('✅ User found in Cognito:');
        console.log('   - Status:', response.UserStatus);
        console.log('   - Enabled:', response.Enabled);
        console.log('   - Created:', response.UserCreateDate);
        console.log('   - Modified:', response.UserLastModifiedDate);
        
        const attributes = {};
        response.UserAttributes.forEach(attr => {
            attributes[attr.Name] = attr.Value;
        });
        console.log('   - Email verified:', attributes.email_verified);
        console.log('   - Email:', attributes.email);
        
        return { success: true, user: response };
    } catch (error) {
        console.log('❌ Failed to get user status:');
        console.log('   Code:', error.code);
        console.log('   Message:', error.message);
        return { success: false };
    }
}

async function testCognitoClientConfig() {
    console.log('\n8️⃣ TESTING COGNITO CLIENT CONFIG');
    console.log('===============================');
    
    try {
        console.log('⚙️ Getting Cognito client configuration...');
        const response = await cognito.describeUserPoolClient({
            UserPoolId: CONFIG.USER_POOL_ID,
            ClientId: CONFIG.CLIENT_ID
        }).promise();
        
        console.log('✅ Client configuration:');
        console.log('   - Client Name:', response.UserPoolClient.ClientName);
        console.log('   - Auth Flows:', response.UserPoolClient.ExplicitAuthFlows);
        console.log('   - Generate Secret:', response.UserPoolClient.GenerateSecret);
        console.log('   - Refresh Token Validity:', response.UserPoolClient.RefreshTokenValidity);
        
        return { success: true, config: response.UserPoolClient };
    } catch (error) {
        console.log('❌ Failed to get client config:');
        console.log('   Code:', error.code);
        console.log('   Message:', error.message);
        return { success: false };
    }
}

async function runComprehensiveTest() {
    const results = {
        backendHealth: false,
        registration: false,
        emailCheck: false,
        backendLogin: false,
        directCognitoAuth: false,
        passwordReset: false,
        userStatus: false,
        clientConfig: false
    };
    
    try {
        results.backendHealth = await testBackendHealth();
        results.emailCheck = await testEmailCheck();
        results.userStatus = await testCognitoUserStatus();
        results.clientConfig = await testCognitoClientConfig();
        results.directCognitoAuth = await testDirectCognitoAuth();
        results.backendLogin = await testExistingUserLogin();
        results.passwordReset = await testPasswordReset();
        
        // Only test registration if other tests pass
        if (results.backendHealth) {
            const regResult = await testRegistration();
            results.registration = regResult.success;
        }
        
        console.log('\n📊 TEST RESULTS SUMMARY');
        console.log('======================');
        console.log('✅ = Working | ❌ = Not Working | ⚠️ = Partial');
        console.log('');
        console.log(`${results.backendHealth ? '✅' : '❌'} Backend Health Check`);
        console.log(`${results.emailCheck ? '✅' : '❌'} Email Check Endpoint`);
        console.log(`${results.userStatus ? '✅' : '❌'} Cognito User Status`);
        console.log(`${results.clientConfig ? '✅' : '❌'} Cognito Client Config`);
        console.log(`${results.registration ? '✅' : '❌'} Registration Flow`);
        console.log(`${results.directCognitoAuth ? '✅' : '❌'} Direct Cognito Authentication`);
        console.log(`${results.backendLogin ? '✅' : '❌'} Backend Login Flow`);
        console.log(`${results.passwordReset ? '✅' : '❌'} Password Reset Initiation`);
        
        console.log('\n🔍 DIAGNOSIS');
        console.log('===========');
        
        if (!results.directCognitoAuth && !results.backendLogin) {
            console.log('⚠️ MAIN ISSUE: Authentication is failing at the Cognito level');
            console.log('   This suggests either:');
            console.log('   1. Wrong password for the existing user');
            console.log('   2. Cognito client configuration issue');
            console.log('   3. User account in an invalid state');
        } else if (results.directCognitoAuth && !results.backendLogin) {
            console.log('⚠️ MAIN ISSUE: Backend login wrapper has a problem');
            console.log('   Direct Cognito works but backend doesn\'t');
        } else if (results.backendLogin) {
            console.log('✅ LOGIN IS WORKING: Both Cognito and backend are functional');
        }
        
        if (!results.registration) {
            console.log('⚠️ Registration may have issues with validation or DynamoDB');
        }
        
        if (!results.passwordReset) {
            console.log('⚠️ Password reset flow has issues');
        }
        
    } catch (error) {
        console.error('💥 Test suite failed with error:', error.message);
    }
}

// Run the comprehensive test
runComprehensiveTest().catch(error => {
    console.error('💥 Fatal error:', error.message);
    process.exit(1);
});
