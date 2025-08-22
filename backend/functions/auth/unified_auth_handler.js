'use strict';

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand, QueryCommand, ScanCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');
const {
    CognitoIdentityProviderClient,
    SignUpCommand,
    ConfirmSignUpCommand,
    AdminUpdateUserAttributesCommand,
    AdminGetUserCommand,
    AdminDeleteUserCommand,
    AdminAddUserToGroupCommand,
    InitiateAuthCommand,
    GetUserCommand,
    ResendConfirmationCodeCommand
} = require('@aws-sdk/client-cognito-identity-provider');
const { v4: uuidv4 } = require('uuid');
const { createResponse } = require('./utils');

// --- Contextual logging helpers (added) ---
function buildRequestContext(event) {
    const requestId = event?.requestContext?.requestId || event?.headers?.['x-request-id'] || `req-${Date.now()}`;
    const correlationId = event?.headers?.['x-correlation-id'] || event?.headers?.['x-correlationid'] || requestId;
    return { requestId, correlationId, rawPath: event?.rawPath || event?.path, httpMethod: event?.httpMethod };
}
function logCTX(ctx, msg, extra) {
    const base = `CTX | requestId=${ctx.requestId} corrId=${ctx.correlationId}` + (ctx.rawPath ? ` path=${ctx.rawPath}` : '') + (ctx.httpMethod ? ` method=${ctx.httpMethod}` : '');
    if (extra) console.log(base + ' | ' + msg, extra); else console.log(base + ' | ' + msg);
}
function logBizResolution(stage, details) {
    console.log(`BUSINESS_RESOLUTION | stage=${stage} |`, details);
}
// ------------------------------------------

// Environment variables
const USERS_TABLE = process.env.USERS_TABLE;
const BUSINESSES_TABLE = process.env.BUSINESSES_TABLE;
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;
const CLIENT_ID = process.env.COGNITO_CLIENT_ID;

exports.handler = async (event) => {
    const ctx = buildRequestContext(event);
    logCTX(ctx, `Processing auth request`);
    console.log(`Processing ${event.httpMethod} ${event.path}`);
    let body;
    try {
        let requestBody = event.body;
        if (event.isBase64Encoded) {
            requestBody = Buffer.from(requestBody, 'base64').toString('utf-8');
            logCTX(ctx, 'Decoded Base64 body');
        }
        body = typeof requestBody === 'string' ? JSON.parse(requestBody) : requestBody;
    } catch (e) {
        console.error('Failed to parse request body:', e);
        body = event.body;
    }
    body = body || {};

    try {
        switch (`${event.httpMethod} ${event.path}`) {
            case 'POST /auth/register-with-business':
                logCTX(ctx, 'Route matched register-with-business');
                return await handleRegisterWithBusiness(body);
            case 'POST /auth/confirm':
                logCTX(ctx, 'Route matched confirm');
                return await handleConfirmSignup(body);
            case 'POST /auth/check-email':
                logCTX(ctx, 'Route matched check-email');
                return await handleCheckEmail(body);
            case 'POST /auth/signin':
                logCTX(ctx, 'Route matched signin');
                return await handleSignin(body, ctx);
            case 'POST /auth/signout':
                logCTX(ctx, 'Route matched signout');
                return createResponse(200, { success: true, message: 'Signed out (stateless).' });
            case 'POST /auth/resend-code':
                logCTX(ctx, 'Route matched resend-code');
                return await handleResendCode(body);
            case 'GET /auth/user-businesses':
                logCTX(ctx, 'Route matched user-businesses');
                // TEMP DEBUG: log auth header presence
                try { console.log('DEBUG_AUTH_HEADER', { auth: event.headers?.Authorization || event.headers?.authorization }); } catch (_) { }
                return await handleGetUserBusinesses(event, ctx);
            case 'GET /auth/health':
                logCTX(ctx, 'Route matched health');
                return handleHealth();
            default:
                logCTX(ctx, 'No route matched');
                return createResponse(404, { success: false, message: 'Endpoint not found', requestId: ctx.requestId });
        }
    } catch (error) {
        console.error('Unexpected error in handler:', error);
        return createResponse(500, { success: false, message: 'Internal server error', requestId: ctx.requestId });
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
        businessPhotoUrl,
        // New optional field for business subcategories (array of ids)
        businessSubcategories
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
        // Build required Cognito attributes based on current User Pool schema
        const userAttributes = [{ Name: 'email', Value: email }];

        // Full name and given/family names
        if (finalOwnerName) {
            userAttributes.push({ Name: 'name', Value: String(finalOwnerName) });
        } else {
            const fallbackName = `${firstName || ''} ${lastName || ''}`.trim() || 'User';
            userAttributes.push({ Name: 'name', Value: fallbackName });
        }
        if (firstName) {
            userAttributes.push({ Name: 'given_name', Value: String(firstName) });
        }
        if (lastName) {
            userAttributes.push({ Name: 'family_name', Value: String(lastName) });
        }

        // Address attribute follows OIDC format as JSON string; include 'formatted' and parts if present
        const formattedAddressParts = [street, city, district, country]
            .filter(Boolean)
            .join(', ');
        const addressObjForCognito = {
            formatted: formattedAddressParts || undefined,
            street_address: street || undefined,
            locality: city || undefined,
            region: district || undefined,
            country: country || undefined,
        };
        // Remove undefined keys before stringify
        const cleanedAddressObj = Object.fromEntries(
            Object.entries(addressObjForCognito).filter(([_, v]) => v !== undefined && v !== '')
        );
        if (Object.keys(cleanedAddressObj).length > 0) {
            try {
                const addressString = JSON.stringify(cleanedAddressObj);
                console.log('🏠 Address attribute to be set:', addressString);
                userAttributes.push({ Name: 'address', Value: addressString });
            } catch (addrErr) {
                console.error('⚠️ Failed to stringify address, skipping address attribute:', addrErr);
            }
        }

        console.log('👤 User attributes to be sent to Cognito:', JSON.stringify(userAttributes, null, 2));

        const signUpParams = {
            ClientId: CLIENT_ID,
            Username: email,
            Password: password,
            UserAttributes: userAttributes,
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
            // Optional subcategories selection from UI
            businessSubcategories: Array.isArray(businessSubcategories) ? businessSubcategories : undefined,
            isActive: true,
            status: 'pending',
            createdAt: timestamp,
            updatedAt: timestamp
        };

        try {
            await dynamodb.send(new PutCommand({ TableName: USERS_TABLE, Item: userItem }));
        } catch (ddbErr) {
            console.error('❌ Failed writing to USERS_TABLE:', USERS_TABLE, ddbErr);
            try {
                await cognitoClient.send(new AdminDeleteUserCommand({ UserPoolId: USER_POOL_ID, Username: email }));
            } catch (cleanupError) {
                console.error('Failed to cleanup Cognito user after USERS_TABLE error:', cleanupError);
            }
            if (ddbErr.name === 'ResourceNotFoundException') {
                return createResponse(500, { success: false, message: `Failed to create account: DynamoDB table not found (${USERS_TABLE}). Please ensure it exists.` });
            }
            return createResponse(500, { success: false, message: `Failed to create account: ${ddbErr.message || ddbErr.name}` });
        }

        try {
            await dynamodb.send(new PutCommand({ TableName: BUSINESSES_TABLE, Item: businessItem }));
        } catch (ddbErr) {
            console.error('❌ Failed writing to BUSINESSES_TABLE:', BUSINESSES_TABLE, ddbErr);
            try {
                await cognitoClient.send(new AdminDeleteUserCommand({ UserPoolId: USER_POOL_ID, Username: email }));
            } catch (cleanupError) {
                console.error('Failed to cleanup Cognito user after BUSINESSES_TABLE error:', cleanupError);
            }
            try {
                await dynamodb.send(new DeleteCommand({ TableName: USERS_TABLE, Key: { userId } }));
            } catch (ignore) { /* noop */ }

            if (ddbErr.name === 'ResourceNotFoundException') {
                return createResponse(500, { success: false, message: `Failed to create account: DynamoDB table not found (${BUSINESSES_TABLE}). Please ensure it exists.` });
            }
            return createResponse(500, { success: false, message: `Failed to create account: ${ddbErr.message || ddbErr.name}` });
        }
        console.log(`Created user and business records: ${userId}, ${businessId}`);

        // Add user to merchants group
        try {
            await cognitoClient.send(new AdminAddUserToGroupCommand({
                UserPoolId: USER_POOL_ID,
                Username: email,
                GroupName: 'merchants'
            }));
            console.log(`✅ Added user ${email} to merchants group`);
        } catch (groupErr) {
            console.error('⚠️ Failed to add user to merchants group (non-critical):', groupErr);
        }

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
        console.error('Registration attempt details:', {
            email: email,
            hasPassword: !!password,
            businessName: finalBusinessName,
            phoneNumber: finalPhoneNumber,
            ownerName: finalOwnerName
        });
        
        if (error.name === 'UsernameExistsException') {
            return createResponse(409, { success: false, message: 'User with this email already exists' });
        }
        if (error.name === 'InvalidPasswordException') {
            return createResponse(400, { success: false, message: 'Password does not meet requirements. Must be at least 8 characters with uppercase, lowercase, and numbers.' });
        }
        if (error.name === 'InvalidParameterException') {
            const emailValid = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(email);
            return createResponse(400, {
                success: false,
                message: `Invalid parameter: ${error.message}`,
                code: 'INVALID_PARAMETER',
                details: { email, emailValid }
            });
        }
        if (error.name === 'ResourceNotFoundException') {
            return createResponse(500, { success: false, message: `Failed to create account: Requested resource not found (${error.message || 'DynamoDB/Cognito resource'})` });
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
                UpdateExpression: 'set emailVerified = :v, updatedAt = :t',
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
            
            let businessResult;
            try {
                businessResult = await dynamodb.send(new QueryCommand(businessQueryParams));
            } catch (qErr) {
                console.error('❌ Error querying businesses by email:', qErr);
                if (qErr.name === 'ValidationException' && /specified index: email-index/i.test(qErr.message || '')) {
                    return createResponse(500, { success: false, message: `Missing GSI 'email-index' on ${BUSINESSES_TABLE}. Please create the index on attribute 'email'.` });
                }
                return createResponse(500, { success: false, message: 'Failed to fetch user businesses after verification.' });
            }
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

async function handleSignin(body, parentCtx) {
    // Instantiate AWS clients for this invocation (supports Jest mocks)
    const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.COGNITO_REGION || 'us-east-1' });
    const dynamoDbClient = new DynamoDBClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });
    const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

    const { email: rawEmail, password } = body;
    const email = rawEmail ? rawEmail.toLowerCase().trim() : '';

    if (!email || !password) {
        return createResponse(400, { success: false, message: 'Email and password are required', requestId: parentCtx?.requestId });
    }

    try {
        const authParams = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: CLIENT_ID,
            AuthParameters: { USERNAME: email, PASSWORD: password }
        };
        logBizResolution('cognito_initiate_auth', { email });
        const response = await cognitoClient.send(new InitiateAuthCommand(authParams));
        console.log(`User ${email} signed in successfully.`);

        // Fetch user data from DynamoDB
        logBizResolution('query_user_by_email_start', { table: USERS_TABLE, email });
        const userQueryParams = {
            TableName: USERS_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': email }
        };
        let userResult;
        try {
            userResult = await dynamodb.send(new QueryCommand(userQueryParams));
        } catch (qErr) {
            logBizResolution('query_user_by_email_error', { email, error: qErr.name, message: qErr.message });
            console.error('❌ Error querying users by email:', qErr);
            if (qErr.name === 'ValidationException' && /specified index: email-index/i.test(qErr.message || '')) {
                return createResponse(500, { success: false, message: `Missing GSI 'email-index' on ${USERS_TABLE}. Please create the index on attribute 'email'.`, requestId: parentCtx?.requestId });
            }
            return createResponse(500, { success: false, message: 'Failed to fetch user record', requestId: parentCtx?.requestId });
        }
        const userItems = userResult.Items;
        logBizResolution('query_user_by_email_result', { email, count: userItems ? userItems.length : 0 });

        // Fetch business data from DynamoDB
        logBizResolution('query_business_by_email_start', { table: BUSINESSES_TABLE, email });
        const businessQueryParams = {
            TableName: BUSINESSES_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': email }
        };
        let businessResult;
        try {
            businessResult = await dynamodb.send(new QueryCommand(businessQueryParams));
        } catch (qErr) {
            logBizResolution('query_business_by_email_error', { email, error: qErr.name, message: qErr.message });
            console.error('❌ Error querying businesses by email:', qErr);
            if (qErr.name === 'ValidationException' && /specified index: email-index/i.test(qErr.message || '')) {
                return createResponse(500, { success: false, message: `Missing GSI 'email-index' on ${BUSINESSES_TABLE}. Please create the index on attribute 'email'.`, requestId: parentCtx?.requestId });
            }
            return createResponse(500, { success: false, message: 'Failed to fetch business records', requestId: parentCtx?.requestId });
        }
        const businessItems = businessResult.Items;
        logBizResolution('query_business_by_email_result', { email, count: businessItems ? businessItems.length : 0 });

        return createResponse(200, {
            success: true,
            message: 'Sign in successful',
            data: response.AuthenticationResult,
            user: userItems && userItems.length > 0 ? userItems[0] : null,
            businesses: businessItems || [],
            requestId: parentCtx?.requestId
        });
    } catch (error) {
        console.error('Error signing in:', error);
        const code = error.name || error.code;
        logBizResolution('signin_error', { email, code, message: error.message });
        if (code === 'UserNotConfirmedException') {
            return createResponse(403, { success: false, message: 'Account not confirmed. Please verify your email.', code: 'USER_NOT_CONFIRMED', requestId: parentCtx?.requestId });
        }
        if (code === 'NotAuthorizedException') {
            return createResponse(401, { success: false, message: 'Invalid email or password', code: 'INVALID_CREDENTIALS', requestId: parentCtx?.requestId });
        }
        if (code === 'UserNotFoundException') {
            return createResponse(404, { success: false, message: 'No account found for this email', code: 'USER_NOT_FOUND', requestId: parentCtx?.requestId });
        }
        if (code === 'PasswordResetRequiredException') {
            return createResponse(403, { success: false, message: 'Password reset required. Please reset your password.', code: 'PASSWORD_RESET_REQUIRED', requestId: parentCtx?.requestId });
        }
        return createResponse(500, { success: false, message: 'Failed to sign in', code: code || 'UNKNOWN_ERROR', requestId: parentCtx?.requestId });
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
        // Provide more actionable errors for frontend UX
        const code = error.name || error.code;
        if (code === 'UserNotFoundException') {
            return createResponse(404, { success: false, message: 'No account found for this email' });
        }
        if (code === 'NotAuthorizedException') {
            // Common when user is already confirmed
            return createResponse(409, { success: false, message: 'Account already verified. Please sign in.' });
        }
        if (code === 'LimitExceededException' || code === 'TooManyRequestsException') {
            return createResponse(429, { success: false, message: 'Too many attempts. Please wait a few minutes and try again.' });
        }
        if (code === 'CodeDeliveryFailureException') {
            return createResponse(502, { success: false, message: 'Failed to deliver verification code. Please check your email address or try again later.' });
        }
        return createResponse(500, { success: false, message: 'Failed to resend code' });
    }
}

async function handleGetUserBusinesses(event, parentCtx) {
    // Instantiate AWS clients for this invocation
    const dynamoDbClient = new DynamoDBClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });
    const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

    // Helper to resolve email from cognitoUserId (user sub) if AccessToken lacks email
    async function resolveEmailFromCognitoUserId(cognitoUserId) {
        if (!cognitoUserId) return null;
        logBizResolution('get_user_businesses_resolve_email_start', { cognitoUserId });
        // Try query via presumed GSI first
        const queryParams = {
            TableName: USERS_TABLE,
            IndexName: 'cognitoUserId-index', // if not present query will fail
            KeyConditionExpression: 'cognitoUserId = :cid',
            ExpressionAttributeValues: { ':cid': cognitoUserId }
        };
        try {
            const q = await dynamodb.send(new QueryCommand(queryParams));
            const item = q.Items && q.Items[0];
            if (item && (item.email || item.Email)) {
                logBizResolution('get_user_businesses_resolve_email_query_hit', { viaIndex: true });
                return (item.email || item.Email).toLowerCase();
            }
            logBizResolution('get_user_businesses_resolve_email_query_empty', { viaIndex: true });
        } catch (e) {
            if (e.name === 'ValidationException') {
                logBizResolution('get_user_businesses_resolve_email_index_missing', { index: 'cognitoUserId-index' });
            } else {
                logBizResolution('get_user_businesses_resolve_email_query_error', { error: e.name, message: e.message });
            }
        }
        // Fallback: scan (temporary – encourage adding GSI)
        try {
            const scanParams = {
                TableName: USERS_TABLE,
                FilterExpression: 'cognitoUserId = :cid',
                ExpressionAttributeValues: { ':cid': cognitoUserId },
                ProjectionExpression: 'email, cognitoUserId'
            };
            const s = await dynamodb.send(new ScanCommand(scanParams));
            const item = s.Items && s.Items[0];
            if (item && item.email) {
                logBizResolution('get_user_businesses_resolve_email_scan_hit', { count: s.Count });
                return item.email.toLowerCase();
            }
            logBizResolution('get_user_businesses_resolve_email_scan_empty', { count: s.Count });
        } catch (scanErr) {
            logBizResolution('get_user_businesses_resolve_email_scan_error', { error: scanErr.name, message: scanErr.message });
        }
        return null;
    }

    try {
        // Claims from API Gateway authorizer (if any)
        const claims = event.requestContext.authorizer?.claims;
        let email = claims?.email || claims?.Email;
        let tokenUseClaim = claims?.token_use;
        let cognitoUserId = claims?.sub || claims?.['cognito:username'] || claims?.username; // potential values

        // Always attempt local decode to enrich data (covers AccessToken path where gateway strips claims or provides none)
        const authHeader = event.headers?.Authorization || event.headers?.authorization;
        let rawToken;
        if (authHeader) {
            if (authHeader.startsWith('Bearer ')) {
                rawToken = authHeader.slice(7);
                logBizResolution('get_user_businesses_bearer_format', { hasBearer: true });
            } else {
                // Direct token without Bearer prefix (for AWS API Gateway Cognito Authorizer)
                rawToken = authHeader.trim();
                logBizResolution('get_user_businesses_direct_format', { hasBearer: false });
            }

            try {
                const decoded = require('jwt-decode').jwtDecode(rawToken);
                // Access or ID token fields
                tokenUseClaim = tokenUseClaim || decoded.token_use;
                // Prefer email if present (IdToken) else attempt to collect identifiers
                email = email || decoded.email || decoded.Email;
                // Collect sub/username for later resolution
                cognitoUserId = cognitoUserId || decoded.sub || decoded['cognito:username'] || decoded.username;
                logBizResolution('get_user_businesses_local_decode', { tokenUse: decoded.token_use, hasEmail: !!email, hasSub: !!cognitoUserId });
            } catch (e) {
                logBizResolution('get_user_businesses_local_decode_failed', { message: e.message });
            }
        } else {
            logBizResolution('get_user_businesses_no_auth_header', { hasAuthHeader: !!authHeader });
        }

        // If we still do not have email but have cognitoUserId (typical AccessToken scenario), resolve via Users table
        if (!email && cognitoUserId) {
            email = await resolveEmailFromCognitoUserId(cognitoUserId);
            if (email) {
                logBizResolution('get_user_businesses_email_resolved_from_sub', { cognitoUserId });
            }
        }

        logBizResolution('get_user_businesses_claims', { claims: claims ? 'present' : 'absent', emailFound: !!email, tokenUse: tokenUseClaim, hasCognitoUserId: !!cognitoUserId });

        if (!email) {
            logBizResolution('get_user_businesses_error', { error: 'MISSING_EMAIL', message: 'Email not found in token or database resolution failed' });
            return createResponse(401, { success: false, message: 'Email not found in user token', requestId: parentCtx?.requestId });
        }

        const normalizedEmail = email.toLowerCase().trim();
        logBizResolution('get_user_businesses_start', { email: normalizedEmail, tokenUse: tokenUseClaim || 'unknown' });

        const queryParams = {
            TableName: BUSINESSES_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': normalizedEmail }
        };

        let result;
        try {
            result = await dynamodb.send(new QueryCommand(queryParams));
        } catch (qErr) {
            logBizResolution('get_user_businesses_error', { email: normalizedEmail, error: qErr.name, message: qErr.message });
            console.error('❌ Error querying businesses by email:', qErr);
            if (qErr.name === 'ValidationException' && /specified index: email-index/i.test(qErr.message || '')) {
                return createResponse(500, { success: false, message: `Missing GSI 'email-index' on ${BUSINESSES_TABLE}. Please create the index on attribute 'email'.`, requestId: parentCtx?.requestId });
            }
            return createResponse(500, { success: false, message: 'Failed to fetch user businesses', requestId: parentCtx?.requestId });
        }
        const Items = result.Items;
        logBizResolution('get_user_businesses_result', { email: normalizedEmail, count: Items ? Items.length : 0 });

        if (Items && Items.length > 0) {
            return createResponse(200, { success: true, businesses: Items, message: `Found ${Items.length} business(es)`, requestId: parentCtx?.requestId });
        } else {
            return createResponse(200, { success: true, businesses: [], message: 'No businesses found for this user', requestId: parentCtx?.requestId });
        }

    } catch (error) {
        console.error('Error fetching user businesses:', error);
        logBizResolution('get_user_businesses_exception', { message: error.message, name: error.name });
        if (error.name === 'NotAuthorizedException') {
            return createResponse(401, { success: false, message: 'Invalid or expired access token', requestId: parentCtx?.requestId });
        }
        return createResponse(500, { success: false, message: 'Failed to fetch user businesses', requestId: parentCtx?.requestId });
    }
}

function handleHealth() {
    return createResponse(200, { success: true, message: 'Auth service is healthy' });
}

// Export internal functions for testing
module.exports.handleRegisterWithBusiness = handleRegisterWithBusiness;
module.exports.handleSignin = handleSignin;
