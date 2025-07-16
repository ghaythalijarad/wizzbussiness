const AWS = require('aws-sdk');
const readline = require('readline');

// Configure AWS
const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });

const CLIENT_ID = '6n752vrmqmbss6nmlg6be2nn9a';
const EMAIL = 'g87_a@yahoo.com';

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

async function confirmPasswordReset() {
    console.log('🔐 Password Reset Confirmation');
    console.log('=============================');
    console.log(`Email: ${EMAIL}`);
    console.log('');
    console.log('Please check your email for the verification code.');
    console.log('');

    try {
        const verificationCode = await askQuestion('Enter the verification code from your email: ');
        const newPassword = await askQuestion('Enter your new password: ');
        const confirmPassword = await askQuestion('Confirm your new password: ');

        if (newPassword !== confirmPassword) {
            console.log('❌ Passwords do not match. Please try again.');
            rl.close();
            return;
        }

        console.log('');
        console.log('🔄 Confirming password reset...');

        const response = await cognito.confirmForgotPassword({
            ClientId: CLIENT_ID,
            Username: EMAIL,
            ConfirmationCode: verificationCode.trim(),
            Password: newPassword
        }).promise();

        console.log('✅ Password reset successful!');
        console.log('🎉 You can now log in with your new password.');
        console.log('');
        console.log('📋 Next steps:');
        console.log('1. Try logging in to the Flutter app');
        console.log('2. Use the new password you just set');

    } catch (error) {
        console.log('❌ Password reset failed');
        console.log('Error Code:', error.code);
        console.log('Error Message:', error.message);
        console.log('');
        
        if (error.code === 'CodeMismatchException') {
            console.log('💡 The verification code is incorrect. Please check your email and try again.');
        } else if (error.code === 'ExpiredCodeException') {
            console.log('💡 The verification code has expired. Please request a new password reset.');
        } else if (error.code === 'InvalidPasswordException') {
            console.log('💡 The password does not meet the requirements. Please try a stronger password.');
        }
    }

    rl.close();
}

function askQuestion(question) {
    return new Promise((resolve) => {
        rl.question(question, (answer) => {
            resolve(answer);
        });
    });
}

confirmPasswordReset().catch(error => {
    console.error('💥 Script failed with error:');
    console.error('Error message:', error.message);
    rl.close();
});
