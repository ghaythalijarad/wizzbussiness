'use strict';

const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
const { createResponse } = require('./utils');

// Environment variables
const USERS_TABLE = process.env.USERS_TABLE;
const BUSINESSES_TABLE = process.env.BUSINESSES_TABLE;
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;
const CLIENT_ID = process.env.COGNITO_CLIENT_ID;

exports.handler = async (event) => {
    console.log(`Processing ${event.httpMethod} ${event.path}`);
    const body = event.body ? JSON.parse(event.body) : {};

    try {
        switch (`${event.httpMethod} ${event.path}`) {
            case 'POST /auth/register-with-business':
                return await handleRegisterWithBusiness(body);
            case 'POST /auth/confirm':
                return await handleConfirmSignup(body);
            case 'POST /auth/check-email':
                return await handleCheckEmail(body);
            case 'POST /auth/signin':
                return await handleSignin(body);
            case 'POST /auth/resend-code':
                return await handleResendCode(body);
            case 'GET /auth/user-businesses':
                return await handleGetUserBusinesses(event);
            case 'GET /auth/health':
                return handleHealth();
            default:
                return createResponse(404, { success: false, message: 'Endpoint not found' });
        }
    } catch (error) {
        console.error('Unexpected error in handler:', error);
        return createResponse(500, { success: false, message: 'Internal server error' });
    }
};

async function handleRegisterWithBusiness(body) {
    // Instantiate AWS clients for this invocation (supports Jest mocks)
    const cognito = new AWS.CognitoIdentityServiceProvider({ region: process.env.COGNITO_REGION || 'us-east-1' });
    const dynamodb = new AWS.DynamoDB.DocumentClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });

    const {
        email: rawEmail,
        password,
        businessName,
        business_name,
        businessType,
        business_type = 'restaurant',
        phoneNumber,
        phone_number,
        firstName = '',
        lastName = '',
        ownerName,
        address = '',
        city = '',
        district = '',
        country = 'Iraq',
        street = '',
        businessPhotoUrl
    } = body;

    const email = rawEmail ? rawEmail.toLowerCase().trim() : '';
    const finalBusinessName = businessName || business_name;
    const finalPhoneNumber = phoneNumber || phone_number;
    const finalBusinessType = businessType || business_type;
    const finalOwnerName = ownerName || `${firstName} ${lastName}`.trim();

    if (!email || !password || !finalBusinessName) {
        return createResponse(400, { success: false, message: 'Email, password, and business name are required.' });
    }

    try {
        const signUpParams = {
            ClientId: CLIENT_ID,
            Username: email,
            Password: password,
            UserAttributes: [{ Name: 'email', Value: email }]
        };
        const cognitoResponse = await cognito.signUp(signUpParams).promise();
        const userSub = cognitoResponse.UserSub;
        console.log(`Created Cognito user: ${userSub}`);

        const userId = uuidv4();
        const businessId = uuidv4();
        const timestamp = new Date().toISOString();

        const userItem = {
            userId: userId,
            user_id: userId,
            cognito_user_id: userSub,
            email,
            first_name: firstName || 'User',
            last_name: lastName || '',
            phone_number: finalPhoneNumber || '',
            business_id: businessId,
            is_active: true,
            email_verified: false,
            created_at: timestamp,
            updated_at: timestamp
        };

        const businessItem = {
            businessId: businessId,
            business_id: businessId,
            cognito_user_id: userSub,
            email,
            owner_id: userId,
            owner_name: finalOwnerName || 'Business Owner',
            business_name: finalBusinessName,
            business_type: finalBusinessType,
            phone_number: finalPhoneNumber || '',
            address,
            city,
            district,
            country,
            street,
            business_photo_url: businessPhotoUrl || null,
            is_active: true,
            status: 'pending_verification',
            created_at: timestamp,
            updated_at: timestamp
        };

        await dynamodb.put({ TableName: USERS_TABLE, Item: userItem }).promise();
        await dynamodb.put({ TableName: BUSINESSES_TABLE, Item: businessItem }).promise();
        console.log(`Created user and business records: ${userId}, ${businessId}`);

        return createResponse(200, {
            success: true,
            message: 'Registration successful. Please check your email for verification code.',
            user_sub: userSub,
            business_id: businessId,
            code_delivery_details: cognitoResponse.CodeDeliveryDetails
        });

    } catch (error) {
        console.error('Error in register_with_business:', error);
        console.error('Error details:', JSON.stringify(error, null, 2));
        
        if (error.code === 'UsernameExistsException') {
            return createResponse(409, { success: false, message: 'User with this email already exists' });
        }
        if (error.code === 'InvalidPasswordException') {
            return createResponse(400, { success: false, message: 'Password does not meet requirements. Must be at least 8 characters with uppercase, lowercase, and numbers.' });
        }
        if (error.code === 'InvalidParameterException') {
            return createResponse(400, { success: false, message: 'Invalid email format or other parameter issue.' });
        }
        
        // Basic cleanup if DynamoDB fails after user creation
        if (error.code && error.code.includes('DynamoDB')) {
             try {
                await cognito.adminDeleteUser({ UserPoolId: USER_POOL_ID, Username: email }).promise();
             } catch (cleanupError) {
                console.error('Failed to cleanup Cognito user:', cleanupError);
             }
        }
        return createResponse(500, { success: false, message: `Failed to create account: ${error.message || error.code || 'Unknown error'}` });
    }
}

async function handleConfirmSignup(body) {
    // Instantiate AWS clients for this invocation (supports Jest mocks)
    const cognito = new AWS.CognitoIdentityServiceProvider({ region: process.env.COGNITO_REGION || 'us-east-1' });
    const dynamodb = new AWS.DynamoDB.DocumentClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });

    const { email: rawEmail, verificationCode } = body;
    const email = rawEmail ? rawEmail.toLowerCase().trim() : '';

    if (!email || !verificationCode) {
        return createResponse(400, { success: false, message: 'Email and verification code are required' });
    }

    try {
        await cognito.confirmSignUp({
            ClientId: CLIENT_ID,
            Username: email,
            ConfirmationCode: verificationCode
        }).promise();
        console.log(`Email verified for user: ${email}`);

        await cognito.adminUpdateUserAttributes({
            UserPoolId: USER_POOL_ID,
            Username: email,
            UserAttributes: [{ Name: 'email_verified', Value: 'true' }]
        }).promise();
        console.log(`Updated email_verified attribute for user: ${email}`);

        // Query user by email using the email-index
        const queryParams = {
            TableName: USERS_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': email }
        };
        const { Items } = await dynamodb.query(queryParams).promise();
        console.log(`Query found ${Items ? Items.length : 0} users with email: ${email}`);

        if (Items && Items.length > 0) {
            const user = Items[0];
            console.log(`Found user record:`, JSON.stringify(user, null, 2));
            
            // Check both possible userId fields
            const userIdKey = user.userId || user.user_id;
            console.log(`Using userId for update: ${userIdKey}`);
            
            if (!userIdKey) {
                console.error('No userId found in user record');
                throw new Error('User record missing userId');
            }
            
            const updateParams = {
                TableName: USERS_TABLE,
                Key: { 'userId': userIdKey },
                UpdateExpression: 'set email_verified = :v, updated_at = :t',
                ExpressionAttributeValues: {
                    ':v': true,
                    ':t': new Date().toISOString()
                }
            };
            console.log(`Update params:`, JSON.stringify(updateParams, null, 2));
            
            const updateResult = await dynamodb.update(updateParams).promise();
            console.log(`DynamoDB update result:`, JSON.stringify(updateResult, null, 2));
            console.log(`✅ Updated email verification status for user: ${userIdKey}`);
        } else {
            console.error(`❌ No user found with email: ${email}`);
            throw new Error('User not found in database');
        }

        return createResponse(200, { success: true, message: 'Email verified successfully. You can now sign in.' });

    } catch (error) {
        console.error('Error confirming signup:', error);
        if (error.code === 'CodeMismatchException') {
            return createResponse(400, { success: false, message: 'Invalid verification code' });
        }
        if (error.code === 'ExpiredCodeException') {
            return createResponse(400, { success: false, message: 'Verification code has expired' });
        }
        return createResponse(500, { success: false, message: 'Failed to verify account' });
    }
}

async function handleCheckEmail(body) {
    // Instantiate AWS client for this invocation (supports Jest mocks)
    const cognito = new AWS.CognitoIdentityServiceProvider({ region: process.env.COGNITO_REGION || 'us-east-1' });

    const { email: rawEmail } = body;
    const email = rawEmail ? rawEmail.toLowerCase().trim() : '';

    if (!email) {
        return createResponse(400, { success: false, message: 'Valid email is required' });
    }

    try {
        await cognito.adminGetUser({ UserPoolId: USER_POOL_ID, Username: email }).promise();
        return createResponse(200, { success: true, exists: true, message: 'Email is already registered' });
    } catch (error) {
        if (error.code === 'UserNotFoundException') {
            return createResponse(200, { success: true, exists: false, message: 'Email is available' });
        }
        console.error('Error checking email in Cognito:', error);
        return createResponse(500, { success: false, message: 'Failed to check email availability' });
    }
}

async function handleSignin(body) {
    // Instantiate AWS clients for this invocation (supports Jest mocks)
    const cognito = new AWS.CognitoIdentityServiceProvider({ region: process.env.COGNITO_REGION || 'us-east-1' });
    const dynamodb = new AWS.DynamoDB.DocumentClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });

    const { email: rawEmail, password } = body;
    const email = rawEmail ? rawEmail.toLowerCase().trim() : '';

    if (!email || !password) {
        return createResponse(400, { success: false, message: 'Email and password are required' });
    }

    try {
        const authParams = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: CLIENT_ID,
            AuthParameters: {
                USERNAME: email,
                PASSWORD: password
            }
        };
        const response = await cognito.initiateAuth(authParams).promise();
        console.log(`User ${email} signed in successfully.`);

        // Fetch user data from DynamoDB
        const userQueryParams = {
            TableName: USERS_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': email }
        };
        const { Items: userItems } = await dynamodb.query(userQueryParams).promise();
        console.log(`Found ${userItems ? userItems.length : 0} user records for: ${email}`);

        // Fetch business data from DynamoDB
        const businessQueryParams = {
            TableName: BUSINESSES_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': email }
        };
        const { Items: businessItems } = await dynamodb.query(businessQueryParams).promise();
        console.log(`Found ${businessItems ? businessItems.length : 0} business records for: ${email}`);

        return createResponse(200, { 
            success: true, 
            message: 'Sign in successful', 
            data: response.AuthenticationResult,
            user: userItems && userItems.length > 0 ? userItems[0] : null,
            businesses: businessItems || []
        });
    } catch (error) {
        console.error('Error signing in:', error);
        // Always return unauthorized for any sign-in error
        return createResponse(401, { success: false, message: 'Invalid credentials' });
    }
}

async function handleResendCode(body) {
    // Instantiate AWS client for this invocation (supports Jest mocks)
    const cognito = new AWS.CognitoIdentityServiceProvider({ region: process.env.COGNITO_REGION || 'us-east-1' });

    const { email: rawEmail } = body;
    const email = rawEmail ? rawEmail.toLowerCase().trim() : '';

    if (!email) {
        return createResponse(400, { success: false, message: 'Email is required' });
    }

    try {
        const response = await cognito.resendConfirmationCode({
            ClientId: CLIENT_ID,
            Username: email
        }).promise();
        console.log(`Resent confirmation code to ${email}`);
        return createResponse(200, {
            success: true,
            message: 'Verification code resent successfully.',
            data: response.CodeDeliveryDetails
        });
    } catch (error) {
        console.error('Error resending code:', error);
        return createResponse(500, { success: false, message: 'Failed to resend code' });
    }
}

async function handleGetUserBusinesses(event) {
    // Instantiate AWS clients for this invocation
    const cognito = new AWS.CognitoIdentityServiceProvider({ region: process.env.COGNITO_REGION || 'us-east-1' });
    const dynamodb = new AWS.DynamoDB.DocumentClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });

    // Extract access token from Authorization header
    const authHeader = event.headers?.Authorization || event.headers?.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return createResponse(401, { success: false, message: 'Missing or invalid authorization header' });
    }

    const accessToken = authHeader.replace('Bearer ', '');

    try {
        // Verify the access token with Cognito
        const userResponse = await cognito.getUser({ AccessToken: accessToken }).promise();
        const email = userResponse.UserAttributes.find(attr => attr.Name === 'email')?.Value;
        
        if (!email) {
            return createResponse(400, { success: false, message: 'Email not found in user attributes' });
        }

        console.log(`Fetching businesses for user: ${email}`);

        // Query businesses by email using the email-index
        const queryParams = {
            TableName: BUSINESSES_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': email.toLowerCase().trim() }
        };

        const { Items } = await dynamodb.query(queryParams).promise();
        console.log(`Found ${Items ? Items.length : 0} businesses for user: ${email}`);

        if (Items && Items.length > 0) {
            return createResponse(200, { 
                success: true, 
                businesses: Items,
                message: `Found ${Items.length} business(es)` 
            });
        } else {
            return createResponse(200, { 
                success: true, 
                businesses: [],
                message: 'No businesses found for this user' 
            });
        }

    } catch (error) {
        console.error('Error fetching user businesses:', error);
        if (error.code === 'NotAuthorizedException') {
            return createResponse(401, { success: false, message: 'Invalid or expired access token' });
        }
        return createResponse(500, { success: false, message: 'Failed to fetch user businesses' });
    }
}

function handleHealth() {
    return createResponse(200, { success: true, message: 'Auth service is healthy' });
}

// Export internal functions for testing
module.exports.handleRegisterWithBusiness = handleRegisterWithBusiness;
module.exports.handleSignin = handleSignin;
