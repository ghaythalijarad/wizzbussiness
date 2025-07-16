const AWS = require('aws-sdk');

// Configure AWS
const cognito = new AWS.CognitoIdentityServiceProvider({ region: 'us-east-1' });

const USER_POOL_ID = 'us-east-1_bDqnKdrqo';
const EMAIL = 'g87_a@outlook.com'; // The email the app is trying to use

async function checkUser() {
    console.log('🔍 Checking User Status');
    console.log('=====================');
    console.log(`Email: ${EMAIL}`);
    console.log('');

    try {
        // List users to check if email exists
        const response = await cognito.listUsers({
            UserPoolId: USER_POOL_ID,
            Filter: `email = "${EMAIL}"`,
            Limit: 1
        }).promise();

        if (response.Users && response.Users.length > 0) {
            const user = response.Users[0];
            console.log('✅ User found!');
            console.log('Username:', user.Username);
            console.log('User Status:', user.UserStatus);
            console.log('Email Verified:', user.Attributes.find(attr => attr.Name === 'email_verified')?.Value);
            console.log('Created:', user.UserCreateDate);
            console.log('Last Modified:', user.UserLastModifiedDate);
            
            console.log('\n📋 User Attributes:');
            user.Attributes.forEach(attr => {
                console.log(`  ${attr.Name}: ${attr.Value}`);
            });
        } else {
            console.log('❌ User not found');
            console.log('This email is not registered in the Cognito User Pool');
            
            // Check if there are any users with similar emails
            console.log('\n🔍 Checking for similar emails...');
            const allUsersResponse = await cognito.listUsers({
                UserPoolId: USER_POOL_ID,
                Limit: 10
            }).promise();
            
            console.log(`Found ${allUsersResponse.Users.length} total users in the pool:`);
            allUsersResponse.Users.forEach((user, index) => {
                const email = user.Attributes.find(attr => attr.Name === 'email')?.Value;
                console.log(`  ${index + 1}. ${email} (Status: ${user.UserStatus})`);
            });
        }
        
    } catch (error) {
        console.log('❌ Error checking user');
        console.log('Error Code:', error.code);
        console.log('Error Message:', error.message);
    }
}

checkUser().catch(error => {
    console.error('💥 Script failed with error:');
    console.error('Error message:', error.message);
});
