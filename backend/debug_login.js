const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });

const cognito = new AWS.CognitoIdentityServiceProvider();
const dynamodb = new AWS.DynamoDB.DocumentClient();

const USER_POOL_ID = 'us-east-1_bDqnKdrqo';
const CLIENT_ID = '6n752vrmqmbss6nmlg6be2nn9a';
const USERS_TABLE = 'order-receiver-users-dev';
const BUSINESSES_TABLE = 'order-receiver-businesses-dev';

async function debugLogin() {
    const email = 'g87_a@yahoo.com';
    const password = 'Gha@551987';
    
    console.log('🔍 DEBUGGING LOGIN FOR:', email);
    console.log('================================');
    
    try {
        // 1. Check if user exists in Cognito
        console.log('\n1️⃣ Checking user in Cognito...');
        try {
            const cognitoUser = await cognito.adminGetUser({
                UserPoolId: USER_POOL_ID,
                Username: email
            }).promise();
            
            console.log('✅ User exists in Cognito');
            console.log('User status:', cognitoUser.UserStatus);
            console.log('Enabled:', cognitoUser.Enabled);
            console.log('Attributes:', cognitoUser.UserAttributes.map(attr => ({
                name: attr.Name,
                value: attr.Value
            })));
        } catch (error) {
            console.log('❌ User not found in Cognito:', error.code);
            return;
        }
        
        // 2. Try to authenticate
        console.log('\n2️⃣ Testing authentication...');
        try {
            const authParams = {
                AuthFlow: 'USER_PASSWORD_AUTH',
                ClientId: CLIENT_ID,
                AuthParameters: {
                    USERNAME: email,
                    PASSWORD: password
                }
            };
            
            const authResult = await cognito.initiateAuth(authParams).promise();
            console.log('✅ Authentication successful!');
            console.log('Access Token:', authResult.AuthenticationResult.AccessToken.substring(0, 50) + '...');
        } catch (error) {
            console.log('❌ Authentication failed:', error.code);
            console.log('Error message:', error.message);
            
            // Check if user needs to change password
            if (error.code === 'NewPasswordRequired') {
                console.log('⚠️ User needs to set a new password');
            }
            if (error.code === 'UserNotConfirmedException') {
                console.log('⚠️ User email not confirmed');
            }
            if (error.code === 'NotAuthorizedException') {
                console.log('⚠️ Invalid username or password');
            }
        }
        
        // 3. Check user in DynamoDB
        console.log('\n3️⃣ Checking user in DynamoDB...');
        try {
            const userQuery = {
                TableName: USERS_TABLE,
                IndexName: 'email-index',
                KeyConditionExpression: 'email = :email',
                ExpressionAttributeValues: {
                    ':email': email
                }
            };
            
            const userResult = await dynamodb.query(userQuery).promise();
            console.log('User records found:', userResult.Items.length);
            
            if (userResult.Items.length > 0) {
                const user = userResult.Items[0];
                console.log('User data:', {
                    userId: user.userId,
                    email: user.email,
                    email_verified: user.email_verified,
                    is_active: user.is_active,
                    created_at: user.created_at
                });
            }
        } catch (error) {
            console.log('❌ Error querying DynamoDB:', error.message);
        }
        
        // 4. Check business in DynamoDB
        console.log('\n4️⃣ Checking business in DynamoDB...');
        try {
            const businessQuery = {
                TableName: BUSINESSES_TABLE,
                IndexName: 'email-index',
                KeyConditionExpression: 'email = :email',
                ExpressionAttributeValues: {
                    ':email': email
                }
            };
            
            const businessResult = await dynamodb.query(businessQuery).promise();
            console.log('Business records found:', businessResult.Items.length);
            
            if (businessResult.Items.length > 0) {
                const business = businessResult.Items[0];
                console.log('Business data:', {
                    businessId: business.businessId,
                    business_name: business.business_name,
                    owner_id: business.owner_id,
                    status: business.status,
                    is_active: business.is_active
                });
            }
        } catch (error) {
            console.log('❌ Error querying business DynamoDB:', error.message);
        }
        
    } catch (error) {
        console.log('💥 Unexpected error:', error);
    }
}

debugLogin().then(() => {
    console.log('\n✅ Debug complete');
}).catch(error => {
    console.log('💥 Debug failed:', error);
});
