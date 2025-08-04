'use strict';

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand, QueryCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');
const {
    CognitoIdentityProviderClient,
    SignUpCommand,
    ConfirmSignUpCommand,
    AdminUpdateUserAttributesCommand,
    AdminGetUserCommand,
    AdminDeleteUserCommand,
    InitiateAuthCommand,
    GetUserCommand,
    ResendConfirmationCodeCommand
} = require('@aws-sdk/client-cognito-identity-provider');
const { v4: uuidv4 } = require('uuid');
const { createResponse } = require('./utils');

// Environment variables
const USERS_TABLE = process.env.USERS_TABLE;
const BUSINESSES_TABLE = process.env.BUSINESSES_TABLE;
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;
const CLIENT_ID = process.env.COGNITO_CLIENT_ID;

exports.handler = async (event) => {
    console.log(`Processing ${event.httpMethod} ${event.path}`);
    let body;
    try {
        let requestBody = event.body;
        if (event.isBase64Encoded) {
            requestBody = Buffer.from(requestBody, 'base64').toString('utf-8');
        }
        // Handle both stringified and non-stringified bodies
        body = typeof requestBody === 'string' ? JSON.parse(requestBody) : requestBody;
    } catch (e) {
        console.error("Failed to parse request body:", e);
        // If parsing fails, it might be because the body is not JSON.
        // For now, we can assign the raw body
        body = event.body;
    }
    body = body || {};


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
    const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.COGNITO_REGION || 'us-east-1' });
    const dynamoDbClient = new DynamoDBClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });
    const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

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
        address,
        city: directCity = '',
        district: directDistrict = '',
        country: directCountry = 'Iraq',
        street: directStreet = '',
        businessPhotoUrl
    } = body;

    // Extract address components from nested address object or use direct fields as fallback
    let addressObj, city, district, country, street;
    if (address && typeof address === 'object') {
        // Frontend sends structured address object
        addressObj = address;
        city = address.city || directCity;
        district = address.district || directDistrict;
        country = address.country || directCountry || 'Iraq';
        street = address.street || directStreet;
        console.log('✅ Address parsed from structured object:', { city, district, country, street });
    } else {
        // Fallback to direct fields for backward compatibility
        city = directCity;
        district = directDistrict;
        country = directCountry;
        street = directStreet;
        addressObj = address || '';
        console.log('⚠️ Address using direct fields (fallback):', { city, district, country, street });
    }

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
        const cognitoResponse = await cognitoClient.send(new SignUpCommand(signUpParams));
        const userSub = cognitoResponse.UserSub;
        console.log(`Created Cognito user: ${userSub}`);

        const userId = uuidv4();
        const businessId = uuidv4();
        const timestamp = new Date().toISOString();

        const userItem = {
            userId: userId,
            cognitoUserId: userSub,
            email: email,
            firstName: firstName || 'User',
            lastName: lastName || '',
            phoneNumber: finalPhoneNumber || '',
            businessId: businessId,
            isActive: true,
            emailVerified: false,
            createdAt: timestamp,
            updatedAt: timestamp
        };

        const businessItem = {
            businessId: businessId,
            cognitoUserId: userSub,
            email: email,
            ownerId: userId,
            ownerName: finalOwnerName || 'Business Owner',
            businessName: finalBusinessName,
            businessType: finalBusinessType,
            phoneNumber: finalPhoneNumber || '',
            address: addressObj, // Store the structured address object
            city: city,
            district: district,
            country: country,
            street: street,
            businessPhotoUrl: businessPhotoUrl || null,
            // Document URLs
            businessLicenseUrl: body.businessLicenseUrl || null,
            ownerIdentityUrl: body.ownerIdentityUrl || null,
            healthCertificateUrl: body.healthCertificateUrl || null,
            ownerPhotoUrl: body.ownerPhotoUrl || null,
            isActive: true,
            status: 'pending',
            createdAt: timestamp,
            updatedAt: timestamp
        };

        await dynamodb.send(new PutCommand({ TableName: USERS_TABLE, Item: userItem }));
        await dynamodb.send(new PutCommand({ TableName: BUSINESSES_TABLE, Item: businessItem }));
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
        
        if (error.name === 'UsernameExistsException') {
            return createResponse(409, { success: false, message: 'User with this email already exists' });
        }
        if (error.name === 'InvalidPasswordException') {
            return createResponse(400, { success: false, message: 'Password does not meet requirements. Must be at least 8 characters with uppercase, lowercase, and numbers.' });
        }
        if (error.name === 'InvalidParameterException') {
            return createResponse(400, { success: false, message: 'Invalid email format or other parameter issue.' });
        }
        
        // Basic cleanup if DynamoDB fails after user creation
        if (error.name && error.name.includes('DynamoDB')) {
             try {
                 await cognitoClient.send(new AdminDeleteUserCommand({ UserPoolId: USER_POOL_ID, Username: email }));
             } catch (cleanupError) {
                console.error('Failed to cleanup Cognito user:', cleanupError);
             }
        }
        return createResponse(500, { success: false, message: `Failed to create account: ${error.message || error.name || 'Unknown error'}` });
    }
}

async function handleConfirmSignup(body) {
    // Instantiate AWS clients for this invocation (supports Jest mocks)
    const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.COGNITO_REGION || 'us-east-1' });
    const dynamoDbClient = new DynamoDBClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });
    const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

    const { email: rawEmail, verificationCode } = body;
    const email = rawEmail ? rawEmail.toLowerCase().trim() : '';

    if (!email || !verificationCode) {
        return createResponse(400, { success: false, message: 'Email and verification code are required' });
    }

    try {
        await cognitoClient.send(new ConfirmSignUpCommand({
            ClientId: CLIENT_ID,
            Username: email,
            ConfirmationCode: verificationCode
        }));
        console.log(`Email verified for user: ${email}`);

        await cognitoClient.send(new AdminUpdateUserAttributesCommand({
            UserPoolId: USER_POOL_ID,
            Username: email,
            UserAttributes: [{ Name: 'email_verified', Value: 'true' }]
        }));
        console.log(`Updated email_verified attribute for user: ${email}`);

        // Query user to get userId
        const queryParams = {
            TableName: USERS_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': email }
        };
        const result = await dynamodb.send(new QueryCommand(queryParams));
        const Items = result.Items;
        console.log(`Query found ${Items ? Items.length : 0} users with email: ${email}`);

        if (Items && Items.length > 0) {
            const user = Items[0]; // user has camelCase fields now
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
            
            const updateResult = await dynamodb.send(new UpdateCommand(updateParams));
            console.log(`DynamoDB update result:`, JSON.stringify(updateResult, null, 2));
            console.log(`✅ Updated email verification status for user: ${userIdKey}`);

            // After successful verification, get user's businesses and return login data
            console.log(`🔍 Fetching user businesses for dashboard navigation...`);
            
            // Query businesses by user email
            const businessQueryParams = {
                TableName: BUSINESSES_TABLE,
                IndexName: 'email-index',
                KeyConditionExpression: 'email = :email',
                ExpressionAttributeValues: { ':email': email }
            };
            
            const businessResult = await dynamodb.send(new QueryCommand(businessQueryParams));
            const businesses = businessResult.Items || [];
            console.log(`Found ${businesses.length} businesses for user`);

            // Return user and business data for frontend to handle dashboard navigation
            return createResponse(200, { 
                success: true, 
                message: 'Email verified successfully! Welcome to your business dashboard.',
                verified: true,
                user: {
                    userId: userIdKey,
                    email: email,
                    firstName: user.firstName || user.first_name,
                    lastName: user.lastName || user.last_name
                },
                businesses: businesses
            });
        } else {
            console.error(`❌ No user found with email: ${email}`);
            throw new Error('User not found in database');
        }

    } catch (error) {
        console.error('Error confirming signup:', error);
        if (error.name === 'CodeMismatchException') {
            return createResponse(400, { success: false, message: 'Invalid verification code' });
        }
        if (error.name === 'ExpiredCodeException') {
            return createResponse(400, { success: false, message: 'Verification code has expired' });
        }
        return createResponse(500, { success: false, message: 'Failed to verify account' });
    }
}

async function handleCheckEmail(body) {
    // Instantiate AWS client for this invocation (supports Jest mocks)
    const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.COGNITO_REGION || 'us-east-1' });

    const { email: rawEmail } = body;
    const email = rawEmail ? rawEmail.toLowerCase().trim() : '';

    if (!email) {
        return createResponse(400, { success: false, message: 'Valid email is required' });
    }

    try {
        await cognitoClient.send(new AdminGetUserCommand({ UserPoolId: USER_POOL_ID, Username: email }));
        return createResponse(200, { success: true, exists: true, message: 'Email is already registered' });
    } catch (error) {
        if (error.name === 'UserNotFoundException') {
            return createResponse(200, { success: true, exists: false, message: 'Email is available' });
        }
        console.error('Error checking email in Cognito:', error);
        return createResponse(500, { success: false, message: 'Failed to check email availability' });
    }
}

async function handleSignin(body) {
    // Instantiate AWS clients for this invocation (supports Jest mocks)
    const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.COGNITO_REGION || 'us-east-1' });
    const dynamoDbClient = new DynamoDBClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });
    const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

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
        const response = await cognitoClient.send(new InitiateAuthCommand(authParams));
        console.log(`User ${email} signed in successfully.`);

        // Fetch user data from DynamoDB
        const userQueryParams = {
            TableName: USERS_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': email }
        };
        const userResult = await dynamodb.send(new QueryCommand(userQueryParams));
        const userItems = userResult.Items;
        console.log(`Found ${userItems ? userItems.length : 0} user records for: ${email}`);

        // Fetch business data from DynamoDB
        const businessQueryParams = {
            TableName: BUSINESSES_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': email }
        };
        const businessResult = await dynamodb.send(new QueryCommand(businessQueryParams));
        const businessItems = businessResult.Items;
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
    const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.COGNITO_REGION || 'us-east-1' });

    const { email: rawEmail } = body;
    const email = rawEmail ? rawEmail.toLowerCase().trim() : '';

    if (!email) {
        return createResponse(400, { success: false, message: 'Email is required' });
    }

    try {
        const response = await cognitoClient.send(new ResendConfirmationCodeCommand({
            ClientId: CLIENT_ID,
            Username: email
        }));
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
    const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.COGNITO_REGION || 'us-east-1' });
    const dynamoDbClient = new DynamoDBClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });
    const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

    // Extract access token from Authorization header
    const authHeader = event.headers?.Authorization || event.headers?.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return createResponse(401, { success: false, message: 'Missing or invalid authorization header' });
    }

    const accessToken = authHeader.replace('Bearer ', '');

    try {
        // Verify the access token with Cognito
        const userResponse = await cognitoClient.send(new GetUserCommand({ AccessToken: accessToken }));
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

        const result = await dynamodb.send(new QueryCommand(queryParams));
        const Items = result.Items;
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
        if (error.name === 'NotAuthorizedException') {
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
