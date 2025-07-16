const AWS = require('aws-sdk');

// Configure AWS
const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });

const CLIENT_ID = '6n752vrmqmbss6nmlg6be2nn9a';
const EMAIL = 'g87_a@yahoo.com';
const VERIFICATION_CODE = '926419';
const NEW_PASSWORD = 'NewPass123!'; // Change this to your desired password

async function completePasswordReset() {
    console.log('🔐 Completing Password Reset');
    console.log('============================');
    console.log(`Email: ${EMAIL}`);
    console.log(`Code: ${VERIFICATION_CODE}`);
    console.log('');

    try {
        // Confirm forgot password with new password
        await cognito.confirmForgotPassword({
            ClientId: CLIENT_ID,
            Username: EMAIL,
            ConfirmationCode: VERIFICATION_CODE,
            Password: NEW_PASSWORD
        }).promise();

        console.log('✅ Password reset completed successfully!');
        console.log('🎉 You can now login with the new password');
        console.log('');
        console.log('📋 Next step: Test login');
        console.log(`Email: ${EMAIL}`);
        console.log(`Password: ${NEW_PASSWORD}`);
        
    } catch (error) {
        console.log('❌ Failed to complete password reset');
        console.log('Error Code:', error.code);
        console.log('Error Message:', error.message);
        
        if (error.code === 'ExpiredCodeException') {
            console.log('');
            console.log('💡 The verification code has expired.');
            console.log('   Please request a new password reset.');
        } else if (error.code === 'CodeMismatchException') {
            console.log('');
            console.log('💡 The verification code is incorrect.');
            console.log('   Please check your email for the correct code.');
        }
    }
}

completePasswordReset().catch(error => {
    console.error('💥 Script failed with error:');
    console.error('Error message:', error.message);
});
