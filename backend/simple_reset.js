const AWS = require('aws-sdk');

console.log('Starting password reset confirmation...');

const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });

const params = {
    ClientId: '6n752vrmqmbss6nmlg6be2nn9a',
    Username: 'g87_a@yahoo.com',
    ConfirmationCode: '926419',
    Password: 'NewSecure123!'
};

console.log('Calling confirmForgotPassword...');

cognito.confirmForgotPassword(params, (err, data) => {
    if (err) {
        console.log('❌ Error:', err.code, err.message);
    } else {
        console.log('✅ Success:', data);
        console.log('🎉 Password has been reset successfully!');
        console.log('');
        console.log('📋 Your new login credentials:');
        console.log('Email: g87_a@yahoo.com');
        console.log('Password: NewSecure123!');
    }
    process.exit(0);
});
