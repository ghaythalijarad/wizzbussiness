const AWS = require('aws-sdk');

// Configure AWS
const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });

const CLIENT_ID = '6n752vrmqmbss6nmlg6be2nn9a';
const EMAIL = 'g87_a@yahoo.com';

async function initiatePasswordReset() {
    console.log('🔄 Initiating Fresh Password Reset');
    console.log('==================================');
    console.log(`Email: ${EMAIL}`);
    console.log('');

    try {
        const response = await cognito.forgotPassword({
            ClientId: CLIENT_ID,
            Username: EMAIL
        }).promise();

        console.log('✅ Password reset initiated successfully!');
        console.log('📧 New verification code sent to your email');
        console.log('Code delivery details:', response.CodeDeliveryDetails);
        
        console.log('');
        console.log('📋 Next steps:');
        console.log('1. Check your email for the NEW verification code');
        console.log('2. Share the code with me');
        console.log('3. I will help you complete the password reset');
        
    } catch (error) {
        console.log('❌ Failed to initiate password reset');
        console.log('Error Code:', error.code);
        console.log('Error Message:', error.message);
    }
}

initiatePasswordReset().catch(error => {
    console.error('💥 Script failed with error:');
    console.error('Error message:', error.message);
});
