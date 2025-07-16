const AWS = require('aws-sdk');

const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });

async function testSignInState() {
    try {
        console.log('Testing sign-in state for g87_a@yahoo.com...');
        
        const result = await cognito.initiateAuth({
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: '6n752vrmqmbss6nmlg6be2nn9a',
            AuthParameters: {
                USERNAME: 'g87_a@yahoo.com',
                PASSWORD: 'Gha@551987'
            }
        }).promise();
        
        console.log('Sign-in result:', JSON.stringify(result, null, 2));
        
        if (result.ChallengeName) {
            console.log('Challenge detected:', result.ChallengeName);
            console.log('Challenge parameters:', result.ChallengeParameters);
        }
        
    } catch (error) {
        console.error('Sign-in error:', error.code, error.message);
        
        if (error.code === 'NotAuthorizedException') {
            console.log('Invalid credentials - password might be incorrect');
        } else if (error.code === 'UserNotConfirmedException') {
            console.log('User not confirmed - need to verify email');
        } else if (error.code === 'PasswordResetRequiredException') {
            console.log('Password reset required');
        } else if (error.code === 'UserNotFoundException') {
            console.log('User not found');
        }
    }
}

testSignInState();
