const AWS = require('aws-sdk');

// Configure AWS
const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });

const USER_POOL_ID = 'us-east-1_bDqnKdrqo';
const CLIENT_ID = '6n752vrmqmbss6nmlg6be2nn9a';
const EMAIL = 'g87_a@yahoo.com';
const VERIFICATION_CODE = '926419';
const NEW_PASSWORD = 'NewSecure123!'; // You can change this to your preferred password

async function confirmPasswordReset() {
    console.log('🔐 Confirming Password Reset');
    console.log('===========================');
    console.log(`Email: ${EMAIL}`);
    console.log(`Verification Code: ${VERIFICATION_CODE}`);
    console.log(`New Password: ${'*'.repeat(NEW_PASSWORD.length)}`);
    console.log('');

    try {
        // Confirm the password reset
        const response = await cognito.confirmForgotPassword({
            ClientId: CLIENT_ID,
            Username: EMAIL,
            ConfirmationCode: VERIFICATION_CODE,
            Password: NEW_PASSWORD
        }).promise();

        console.log('✅ Password reset confirmed successfully!');
        console.log('🎉 You can now login with your new password');
        console.log('');
        console.log('📋 Your new login credentials:');
        console.log(`Email: ${EMAIL}`);
        console.log(`Password: ${NEW_PASSWORD}`);
        console.log('');
        console.log('🧪 Testing login with new credentials...');
        
        // Test the new credentials immediately
        const authParams = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: CLIENT_ID,
            AuthParameters: {
                USERNAME: EMAIL,
                PASSWORD: NEW_PASSWORD
            }
        };

        const authResponse = await cognito.initiateAuth(authParams).promise();
        
        if (authResponse.AuthenticationResult) {
            console.log('✅ Login test successful!');
            console.log('🔑 Authentication tokens received');
            console.log('🎯 Login is now working properly');
        } else {
            console.log('⚠️ Login test partially successful but may require additional steps');
        }
        
    } catch (error) {
        console.log('❌ Failed to reset password');
        console.log('Error Code:', error.code);
        console.log('Error Message:', error.message);
        
        if (error.code === 'ExpiredCodeException') {
            console.log('💡 The verification code has expired. Please request a new one.');
        } else if (error.code === 'CodeMismatchException') {
            console.log('💡 The verification code is incorrect. Please check the code in your email.');
        } else if (error.code === 'InvalidPasswordException') {
            console.log('💡 The password does not meet the requirements.');
            console.log('   Password must contain:');
            console.log('   - At least 8 characters');
            console.log('   - At least one uppercase letter');
            console.log('   - At least one lowercase letter');
            console.log('   - At least one number');
            console.log('   - At least one special character');
        }
    }
}

confirmPasswordReset().catch(error => {
    console.error('💥 Script failed with error:');
    console.error('Error message:', error.message);
});
