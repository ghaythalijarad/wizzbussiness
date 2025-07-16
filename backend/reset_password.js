const AWS = require('aws-sdk');

// Configure AWS
const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });

const USER_POOL_ID = 'us-east-1_bDqnKdrqo';
const CLIENT_ID = '6n752vrmqmbss6nmlg6be2nn9a';
const EMAIL = 'g87_a@yahoo.com';

async function resetPassword() {
    console.log('🔄 Initiating Password Reset Process');
    console.log('===================================');
    console.log(`Email: ${EMAIL}`);
    console.log('');

    try {
        // Initiate forgot password flow
        const response = await cognito.forgotPassword({
            ClientId: CLIENT_ID,
            Username: EMAIL
        }).promise();

        console.log('✅ Password reset initiated successfully!');
        console.log('📧 Reset code sent to email');
        console.log('Code delivery details:', response.CodeDeliveryDetails);
        
        console.log('');
        console.log('📋 Next steps:');
        console.log('1. Check your email for the reset code');
        console.log('2. Use the code to set a new password');
        console.log('3. Try logging in with the new password');
        
    } catch (error) {
        console.log('❌ Failed to initiate password reset');
        console.log('Error Code:', error.code);
        console.log('Error Message:', error.message);
    }
}

resetPassword().catch(error => {
    console.error('💥 Script failed with error:');
    console.error('Error message:', error.message);
});
