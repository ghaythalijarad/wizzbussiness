'use strict';

const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
const { createResponse } = require('./utils');

// Initialize AWS clients
const cognito = new AWS.CognitoIdentityServiceProvider({ region: process.env.COGNITO_REGION || 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });

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
        street = ''
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

        const queryParams = {
            TableName: USERS_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': email }
        };
        const { Items } = await dynamodb.query(queryParams).promise();

        if (Items && Items.length > 0) {
            const user = Items[0];
            const updateParams = {
                TableName: USERS_TABLE,
                Key: { 'user_id': user.user_id },
                UpdateExpression: 'set email_verified = :v, updated_at = :t',
                ExpressionAttributeValues: {
                    ':v': true,
                    ':t': new Date().toISOString()
                }
            };
            await dynamodb.update(updateParams).promise();
            console.log(`Updated email verification status for user: ${user.user_id}`);
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
        return createResponse(200, { success: true, message: 'Sign in successful', data: response.AuthenticationResult });
    } catch (error) {
        console.error('Error signing in:', error);
        if (error.code === 'NotAuthorizedException' || error.code === 'UserNotFoundException') {
            return createResponse(401, { success: false, message: 'Invalid credentials' });
        }
        return createResponse(500, { success: false, message: 'Sign in failed' });
    }
}

async function handleResendCode(body) {
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

function handleHealth() {
    return createResponse(200, { success: true, message: 'Auth service is healthy' });
}
