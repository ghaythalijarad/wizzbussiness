const AWS = require('aws-sdk');

// Configure AWS
const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });

const USER_POOL_ID = 'us-east-1_bDqnKdrqo';
const CLIENT_ID = '6n752vrmqmbss6nmlg6be2nn9a';
const EMAIL = 'g87_a@yahoo.com';

async function debugUser() {
    console.log('🔍 Debugging Cognito User Status');
    console.log('================================');
    console.log(`Email: ${EMAIL}`);
    console.log(`User Pool ID: ${USER_POOL_ID}`);
    console.log(`Client ID: ${CLIENT_ID}`);
    console.log('');

    try {
        // 1. Check if user exists in Cognito
        console.log('1️⃣ Checking if user exists in Cognito...');
        const userResponse = await cognito.adminGetUser({
            UserPoolId: USER_POOL_ID,
            Username: EMAIL
        }).promise();

        console.log('✅ User exists in Cognito');
        console.log('User Status:', userResponse.UserStatus);
        console.log('Enabled:', userResponse.Enabled);
        console.log('Created:', userResponse.UserCreateDate);
        console.log('Modified:', userResponse.UserLastModifiedDate);
        
        console.log('\n📋 User Attributes:');
        userResponse.UserAttributes.forEach(attr => {
            console.log(`  ${attr.Name}: ${attr.Value}`);
        });

        // 2. Check if email is verified
        const emailVerified = userResponse.UserAttributes.find(attr => attr.Name === 'email_verified');
        console.log(`\n📧 Email Verified: ${emailVerified?.Value || 'Not set'}`);

        // 3. Try to authenticate with the provided credentials
        console.log('\n2️⃣ Testing authentication...');
        try {
            const authParams = {
                AuthFlow: 'USER_PASSWORD_AUTH',
                ClientId: CLIENT_ID,
                AuthParameters: {
                    USERNAME: EMAIL,
                    PASSWORD: 'Gha@551987'
                }
            };

            const authResponse = await cognito.initiateAuth(authParams).promise();
            console.log('✅ Authentication successful!');
            console.log('Challenge Name:', authResponse.ChallengeName || 'None');
            console.log('Session:', authResponse.Session ? 'Present' : 'None');
            
            if (authResponse.AuthenticationResult) {
                console.log('🎉 Got authentication tokens!');
                console.log('Access Token Length:', authResponse.AuthenticationResult.AccessToken?.length || 0);
                console.log('ID Token Length:', authResponse.AuthenticationResult.IdToken?.length || 0);
                console.log('Refresh Token Length:', authResponse.AuthenticationResult.RefreshToken?.length || 0);
            }

        } catch (authError) {
            console.log('❌ Authentication failed');
            console.log('Error Code:', authError.code);
            console.log('Error Message:', authError.message);
            
            // Check for specific error types
            switch (authError.code) {
                case 'NotAuthorizedException':
                    console.log('💡 This usually means wrong password or user not confirmed');
                    break;
                case 'UserNotConfirmedException':
                    console.log('💡 User exists but email is not confirmed');
                    break;
                case 'UserNotFoundException':
                    console.log('💡 User does not exist in Cognito');
                    break;
                case 'PasswordResetRequiredException':
                    console.log('💡 User must reset password');
                    break;
                case 'UserNotConfirmedException':
                    console.log('💡 User registration is not complete');
                    break;
                default:
                    console.log('💡 Unknown authentication error');
            }
        }

        // 4. Check user's confirmation status more specifically
        console.log('\n3️⃣ Checking user confirmation status...');
        if (userResponse.UserStatus === 'UNCONFIRMED') {
            console.log('❌ User is UNCONFIRMED - email verification needed');
            
            // Try to resend confirmation code
            try {
                await cognito.resendConfirmationCode({
                    ClientId: CLIENT_ID,
                    Username: EMAIL
                }).promise();
                console.log('📧 Resent confirmation code to email');
            } catch (resendError) {
                console.log('❌ Failed to resend confirmation code:', resendError.message);
            }
        } else if (userResponse.UserStatus === 'CONFIRMED') {
            console.log('✅ User is CONFIRMED');
        } else {
            console.log(`⚠️ User status is: ${userResponse.UserStatus}`);
        }

    } catch (getUserError) {
        console.log('❌ Failed to get user from Cognito');
        console.log('Error Code:', getUserError.code);
        console.log('Error Message:', getUserError.message);
        
        if (getUserError.code === 'UserNotFoundException') {
            console.log('💡 The user does not exist in Cognito User Pool');
            console.log('   - Either the email was never registered');
            console.log('   - Or there\'s a mismatch in User Pool configuration');
        }
    }

    // 5. List all users to see what's in the pool (first 10)
    console.log('\n4️⃣ Checking other users in the pool...');
    try {
        const listResponse = await cognito.listUsers({
            UserPoolId: USER_POOL_ID,
            Limit: 10
        }).promise();
        
        console.log(`Found ${listResponse.Users.length} users in pool:`);
        listResponse.Users.forEach((user, index) => {
            const email = user.Attributes.find(attr => attr.Name === 'email')?.Value;
            console.log(`  ${index + 1}. ${email} - Status: ${user.UserStatus}`);
        });
    } catch (listError) {
        console.log('❌ Failed to list users:', listError.message);
    }
}

debugUser().catch(error => {
    console.error('💥 Script failed with error:');
    console.error('Error name:', error.name);
    console.error('Error message:', error.message);
    console.error('Stack trace:', error.stack);
});
