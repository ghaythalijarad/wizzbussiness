const { CognitoIdentityProviderClient, AdminGetUserCommand, SignUpCommand, ConfirmSignUpCommand, InitiateAuthCommand, ResendConfirmationCodeCommand } = require('@aws-sdk/client-cognito-identity-provider');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, QueryCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

const cognitoClient = new CognitoIdentityProviderClient({ region: 'us-east-1' });
const dynamoClient = new DynamoDBClient({ region: 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoClient);

const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
};

// Helper function to create response
function createResponse(statusCode, body) {
    return {
        statusCode,
        headers,
        body: JSON.stringify(body),
    };
}

module.exports.handler = async (event) => {
    console.log('Received event in Auth Handler:', JSON.stringify(event, null, 2));
    const { httpMethod, path } = event;

    if (httpMethod === 'OPTIONS') {
        return createResponse(204, {});
    }

    try {
        // Handle health check
        if (path === '/auth/health') {
            return createResponse(200, {
                success: true,
                message: 'Auth service is healthy',
                timestamp: new Date().toISOString()
            });
        }

        // Handle get user by email for password reset validation
        if (path === '/auth/get-user-by-email' && httpMethod === 'POST') {
            const body = JSON.parse(event.body || '{}');
            const { email } = body;

            if (!email) {
                return createResponse(400, {
                    success: false,
                    message: 'Email is required'
                });
            }

            try {
                // Check if user exists in Cognito without sending emails
                const params = {
                    UserPoolId: process.env.COGNITO_USER_POOL_ID || 'us-east-1_PHPkG78b5',
                    Username: email
                };

                const command = new AdminGetUserCommand(params);
                const userResponse = await cognitoClient.send(command);

                // User exists, check status
                const userStatus = userResponse.UserStatus;
                const isConfirmed = userStatus === 'CONFIRMED';

                return createResponse(200, {
                    success: true,
                    user: {
                        email: email,
                        status: isConfirmed ? 'confirmed' : 'unconfirmed',
                        userStatus: userStatus
                    },
                    message: isConfirmed
                        ? 'User found and confirmed'
                        : 'User found but not confirmed'
                });

            } catch (cognitoError) {
                if (cognitoError.code === 'UserNotFoundException') {
                    return createResponse(200, {
                        success: false,
                        message: 'User does not exist',
                        error: 'USER_NOT_FOUND'
                    });
                } else {
                    console.error('Cognito error:', cognitoError);
                    return createResponse(500, {
                        success: false,
                        message: 'Error checking user status',
                        error: cognitoError.message
                    });
                }
            }
        }

        // Handle registration with business data
        if (path === '/auth/register-with-business' && httpMethod === 'POST') {
            const body = JSON.parse(event.body || '{}');
            const { 
                email, 
                password, 
                businessName, 
                firstName, 
                lastName, 
                businessType, 
                phoneNumber, 
                address, 
                businessPhotoUrl,
                licenseUrl,
                identityUrl,
                healthCertificateUrl,
                ownerPhotoUrl
            } = body;

            if (!email || !password || !businessName || !firstName || !lastName) {
                return createResponse(400, {
                    success: false,
                    message: 'Email, password, business name, first name, and last name are required'
                });
            }

            try {
                // Format phone number to international format for Cognito
                let formattedPhoneNumber = '+1234567890'; // Default fallback
                if (phoneNumber) {
                    // Remove any spaces, dashes, or other formatting
                    const cleanPhone = phoneNumber.replace(/[\s\-\(\)]/g, '');
                    
                    if (cleanPhone.startsWith('+')) {
                        // Already international format
                        formattedPhoneNumber = cleanPhone;
                    } else if (cleanPhone.startsWith('07') && cleanPhone.length === 11) {
                        // Iraqi mobile format: 07XXXXXXXXX -> +9647XXXXXXXXX
                        formattedPhoneNumber = '+964' + cleanPhone.substring(1);
                    } else if (cleanPhone.startsWith('964') && cleanPhone.length === 14) {
                        // Iraq format without +: 964XXXXXXXXXXX -> +964XXXXXXXXXXX
                        formattedPhoneNumber = '+' + cleanPhone;
                    } else if (cleanPhone.startsWith('0') && cleanPhone.length >= 10) {
                        // Generic format starting with 0: assume Iraq
                        formattedPhoneNumber = '+964' + cleanPhone.substring(1);
                    } else if (cleanPhone.length >= 10) {
                        // Assume it's missing country code, add Iraq
                        formattedPhoneNumber = '+964' + cleanPhone;
                    }
                }
                
                console.log('Phone number formatting:', phoneNumber, '->', formattedPhoneNumber);

                // Create user in Cognito
                const signUpParams = {
                    ClientId: process.env.COGNITO_CLIENT_ID || '1tl9g7nk2k2chtj5fg960fgdth',
                    Username: email,
                    Password: password,
                    UserAttributes: [
                        { Name: 'email', Value: email },
                        { Name: 'given_name', Value: firstName },
                        { Name: 'family_name', Value: lastName },
                        { Name: 'name', Value: `${firstName} ${lastName}` }, // Add formatted name
                        { Name: 'phone_number', Value: formattedPhoneNumber },
                    ]
                    // Removed MessageAction: 'SUPPRESS' to allow Cognito to send verification emails automatically
                };

                const signUpCommand = new SignUpCommand(signUpParams);
                const signUpResponse = await cognitoClient.send(signUpCommand);
                console.log('User created in Cognito:', signUpResponse.UserSub);

                // Generate unique IDs
                const businessId = `business_${Date.now()}_${Math.random().toString(36).substring(2, 15)}`;
                const ownerId = signUpResponse.UserSub;
                const currentTime = new Date().toISOString();

                // Create business entry in DynamoDB
                const businessData = {
                    businessId: businessId,
                    businessName: businessName,
                    businessType: businessType || 'restaurant',
                    email: email.toLowerCase().trim(),
                    ownerName: `${firstName} ${lastName}`,
                    phoneNumber: formattedPhoneNumber,
                    ownerId: ownerId,
                    cognitoUserId: signUpResponse.UserSub,
                    status: 'pending', // Pending approval
                    isActive: true,
                    createdAt: currentTime,
                    updatedAt: currentTime,
                    businessPhotoUrl: businessPhotoUrl || null,
                    licenseUrl: licenseUrl || null,
                    identityUrl: identityUrl || null,
                    healthCertificateUrl: healthCertificateUrl || null,
                    ownerPhotoUrl: ownerPhotoUrl || null,
                    address: address || {},
                    city: address?.city || '',
                    country: address?.country || 'Iraq',
                    district: address?.district || '',
                    street: address?.street || ''
                };

                // Save business to DynamoDB
                const businessCommand = new PutCommand({
                    TableName: process.env.BUSINESSES_TABLE || 'WhizzMerchants_Businesses',
                    Item: businessData
                });

                await dynamodb.send(businessCommand);
                console.log('Business created in DynamoDB:', businessId);

                // Create user entry in DynamoDB (if using separate users table)
                const userData = {
                    userId: signUpResponse.UserSub,
                    email: email.toLowerCase().trim(),
                    firstName: firstName,
                    lastName: lastName,
                    fullName: `${firstName} ${lastName}`,
                    phoneNumber: formattedPhoneNumber,
                    userType: 'business_owner',
                    cognitoUserId: signUpResponse.UserSub,
                    primaryBusinessId: businessId,
                    status: 'pending_verification',
                    isActive: true,
                    createdAt: currentTime,
                    updatedAt: currentTime
                };

                // Save user to DynamoDB (if users table exists)
                try {
                    const userCommand = new PutCommand({
                        TableName: process.env.USERS_TABLE || 'WhizzMerchants_Users',
                        Item: userData
                    });
                    await dynamodb.send(userCommand);
                    console.log('User created in DynamoDB:', signUpResponse.UserSub);
                } catch (userError) {
                    console.log('Users table not found or error saving user:', userError.message);
                    // Continue anyway - business is the main entity
                }

                return createResponse(200, {
                    success: true,
                    message: 'Registration initiated successfully. Please check your email for verification code.',
                    user_sub: signUpResponse.UserSub,
                    business_id: businessId,
                    code_delivery_details: signUpResponse.CodeDeliveryDetails,
                    business_data: {
                        businessId: businessId,
                        businessName: businessName,
                        status: 'pending'
                    }
                });

            } catch (cognitoError) {
                console.error('Cognito registration error:', cognitoError);
                if (cognitoError.code === 'UsernameExistsException') {
                    return createResponse(400, {
                        success: false,
                        message: 'An account with this email already exists. Please try logging in instead.'
                    });
                }
                return createResponse(500, {
                    success: false,
                    message: 'Registration failed',
                    error: cognitoError.message
                });
            }
        }

        // Handle email verification
        if (path === '/auth/confirm' && httpMethod === 'POST') {
            const body = JSON.parse(event.body || '{}');
            const { email, verificationCode } = body;

            if (!email || !verificationCode) {
                return createResponse(400, {
                    success: false,
                    message: 'Email and verification code are required'
                });
            }

            try {
                const confirmParams = {
                    ClientId: process.env.COGNITO_CLIENT_ID || '1tl9g7nk2k2chtj5fg960fgdth',
                    Username: email,
                    ConfirmationCode: verificationCode
                };

                const confirmCommand = new ConfirmSignUpCommand(confirmParams);
                await cognitoClient.send(confirmCommand);
                console.log('User confirmed successfully:', email);

                return createResponse(200, {
                    success: true,
                    message: 'Email verification successful! Your account is now active.',
                    user: { email: email },
                    business: null // Business data would be populated from DynamoDB here
                });

            } catch (cognitoError) {
                console.error('Cognito confirmation error:', cognitoError);
                if (cognitoError.code === 'CodeMismatchException') {
                    return createResponse(400, {
                        success: false,
                        message: 'Invalid verification code. Please check the code and try again.'
                    });
                }
                if (cognitoError.code === 'ExpiredCodeException') {
                    return createResponse(400, {
                        success: false,
                        message: 'Verification code has expired. Please request a new code.'
                    });
                }
                return createResponse(500, {
                    success: false,
                    message: 'Email verification failed',
                    error: cognitoError.message
                });
            }
        }

        // Handle resend verification code
        if (path === '/auth/resend-code' && httpMethod === 'POST') {
            const body = JSON.parse(event.body || '{}');
            const { email } = body;

            if (!email) {
                return createResponse(400, {
                    success: false,
                    message: 'Email is required'
                });
            }

            try {
                const resendParams = {
                    ClientId: process.env.COGNITO_CLIENT_ID || '1tl9g7nk2k2chtj5fg960fgdth',
                    Username: email
                };

                const resendCommand = new ResendConfirmationCodeCommand(resendParams);
                const resendResponse = await cognitoClient.send(resendCommand);
                console.log('Verification code resent to:', email);

                return createResponse(200, {
                    success: true,
                    message: 'Verification code resent successfully. Please check your email.',
                    code_delivery_details: resendResponse.CodeDeliveryDetails
                });

            } catch (cognitoError) {
                console.error('Cognito resend error:', cognitoError);
                if (cognitoError.code === 'UserNotFoundException') {
                    return createResponse(400, {
                        success: false,
                        message: 'No account found with this email address.'
                    });
                }
                return createResponse(500, {
                    success: false,
                    message: 'Failed to resend verification code',
                    error: cognitoError.message
                });
            }
        }

        // Handle login/signin
        if (path === '/auth/signin' && httpMethod === 'POST') {
            const body = JSON.parse(event.body || '{}');
            const { email, password } = body;

            if (!email || !password) {
                return createResponse(400, {
                    success: false,
                    message: 'Email and password are required'
                });
            }

            try {
                const authParams = {
                    ClientId: process.env.COGNITO_CLIENT_ID || '1tl9g7nk2k2chtj5fg960fgdth',
                    AuthFlow: 'USER_PASSWORD_AUTH',
                    AuthParameters: {
                        USERNAME: email,
                        PASSWORD: password
                    }
                };

                const authCommand = new InitiateAuthCommand(authParams);
                const authResponse = await cognitoClient.send(authCommand);

                if (authResponse.AuthenticationResult) {
                    const tokens = authResponse.AuthenticationResult;

                    // Get user info from Cognito
                    const getUserParams = {
                        UserPoolId: process.env.COGNITO_USER_POOL_ID || 'us-east-1_PHPkG78b5',
                        Username: email
                    };

                    const getUserCommand = new AdminGetUserCommand(getUserParams);
                    const userResponse = await cognitoClient.send(getUserCommand);

                    // Extract user attributes
                    const userAttributes = {};
                    userResponse.UserAttributes?.forEach(attr => {
                        userAttributes[attr.Name] = attr.Value;
                    });

                    const user = {
                        email: email,
                        userId: userResponse.Username,
                        sub: userAttributes['sub'],
                        firstName: userAttributes['given_name'],
                        lastName: userAttributes['family_name'],
                        phoneNumber: userAttributes['phone_number'],
                        email_verified: userAttributes['email_verified'] === 'true'
                    };

                    // Query real business data from DynamoDB
                    let businesses = [];
                    try {
                        const businessQueryParams = {
                            TableName: process.env.BUSINESSES_TABLE || 'WhizzMerchants_Businesses',
                            IndexName: 'email-index',
                            KeyConditionExpression: 'email = :email',
                            ExpressionAttributeValues: {
                                ':email': email.toLowerCase().trim()
                            }
                        };

                        const businessResult = await dynamodb.send(new QueryCommand(businessQueryParams));

                        if (businessResult.Items && businessResult.Items.length > 0) {
                            businesses = businessResult.Items.map(business => ({
                                businessId: business.businessId,
                                name: business.businessName || business.name,
                                email: business.email,
                                ownerId: business.ownerId,
                                cognitoUserId: business.cognitoUserId,
                                status: business.status || 'approved',
                                businessType: business.businessType || 'restaurant',
                                address: business.address,
                                phoneNumber: business.phoneNumber || business.phone,
                                city: business.city,
                                district: business.district,
                                country: business.country
                            }));
                            console.log(`✅ Found ${businesses.length} businesses for user: ${email}`);
                            
                            // Check if any business has pending status
                            const hasPendingBusiness = businesses.some(business => business.status === 'pending');
                            if (hasPendingBusiness) {
                                console.log(`⚠️ User ${email} has pending business status - blocking login`);
                                return createResponse(200, {
                                    success: false,
                                    message: 'Your account is currently under review. Please wait for approval before accessing your account.',
                                    accountStatus: 'pending',
                                    businesses: businesses
                                });
                            }
                        } else {
                            console.log(`⚠️ No businesses found for user: ${email}`);
                            // Create a fallback business entry if none exists
                            businesses = [{
                                businessId: `business_${user.userId}`,
                                name: `Business for ${user.firstName} ${user.lastName}`,
                                email: email,
                                ownerId: user.userId,
                                cognitoUserId: user.sub,
                                status: 'approved',
                                businessType: 'restaurant',
                                address: 'Default Address',
                                phoneNumber: user.phoneNumber || '+1234567890'
                            }];
                        }
                    } catch (businessError) {
                        console.error('Error querying businesses:', businessError);
                        // Create a fallback business entry if query fails
                        businesses = [{
                            businessId: `business_${user.userId}`,
                            name: `Business for ${user.firstName} ${user.lastName}`,
                            email: email,
                            ownerId: user.userId,
                            cognitoUserId: user.sub,
                            status: 'approved',
                            businessType: 'restaurant',
                            address: 'Default Address',
                            phoneNumber: user.phoneNumber || '+1234567890'
                        }];
                    }

                    return createResponse(200, {
                        success: true,
                        message: 'Sign in successful',
                        user: user,
                        businesses: businesses,
                        data: {
                            AccessToken: tokens.AccessToken,
                            IdToken: tokens.IdToken,
                            RefreshToken: tokens.RefreshToken,
                            ExpiresIn: tokens.ExpiresIn,
                            TokenType: tokens.TokenType
                        }
                    });
                } else {
                    return createResponse(401, {
                        success: false,
                        message: 'Authentication failed'
                    });
                }

            } catch (cognitoError) {
                console.error('Cognito signin error:', cognitoError);

                if (cognitoError.name === 'NotAuthorizedException') {
                    return createResponse(401, {
                        success: false,
                        message: 'Invalid email or password'
                    });
                }
                if (cognitoError.name === 'UserNotConfirmedException') {
                    return createResponse(400, {
                        success: false,
                        message: 'User is not confirmed. Please verify your email first.'
                    });
                }
                if (cognitoError.name === 'UserNotFoundException') {
                    return createResponse(401, {
                        success: false,
                        message: 'Invalid email or password'
                    });
                }

                return createResponse(500, {
                    success: false,
                    message: 'Authentication service error',
                    error: cognitoError.message
                });
            }
        }

        // Handle login tracking using WebSocket service
        if (path === '/auth/track-login' && httpMethod === 'POST') {
            const body = JSON.parse(event.body || '{}');
            const { businessId, userId, email } = body;

            if (!businessId || !userId || !email) {
                return createResponse(400, {
                    success: false,
                    message: 'BusinessId, userId, and email are required'
                });
            }

            try {
                // Use WebSocket service for professional login tracking
                const WebSocketService = require('../websocket/websocket_service');
                
                const result = await WebSocketService.handleUserLogin(businessId, userId, email);

                console.log(`✅ Professional login tracking created for business: ${businessId}, user: ${userId}, email: ${email}`);

                return createResponse(200, {
                    success: true,
                    message: 'Login tracking created successfully',
                    ...result
                });

            } catch (error) {
                console.error('Error creating login tracking:', error);
                return createResponse(500, {
                    success: false,
                    message: 'Failed to create login tracking',
                    error: error.message
                });
            }
        }

        // Handle logout tracking using WebSocket service
        if (path === '/auth/track-logout' && httpMethod === 'POST') {
            const body = JSON.parse(event.body || '{}');
            const { businessId, userId } = body;

            if (!businessId || !userId) {
                return createResponse(400, {
                    success: false,
                    message: 'BusinessId and userId are required'
                });
            }

            try {
                // Use local WebSocket service for professional logout handling
                const WebSocketService = require('./websocket_service');
                
                const result = await WebSocketService.handleUserLogout(businessId, userId);

                console.log(`✅ Professional logout tracking processed for business: ${businessId}, user: ${userId}`);

                return createResponse(200, {
                    success: true,
                    message: `Successfully processed logout tracking`,
                    ...result
                });

            } catch (error) {
                console.error('Error processing logout tracking:', error);
                return createResponse(500, {
                    success: false,
                    message: 'Failed to process logout tracking',
                    error: error.message
                });
            }
        }

        // Handle getting user businesses (used by business provider)
        if (path === '/auth/user-businesses' && httpMethod === 'GET') {
            console.log('🏢 Getting user businesses from access token...');
            
            const authHeader = event.headers?.Authorization || event.headers?.authorization;
            
            if (!authHeader || !authHeader.startsWith('Bearer ')) {
                return createResponse(401, {
                    success: false,
                    message: 'Authorization header is missing or invalid'
                });
            }

            const accessToken = authHeader.replace('Bearer ', '');

            try {
                // Verify the access token and get user info
                const getUserCommand = new GetUserCommand({ AccessToken: accessToken });
                const userResponse = await cognitoClient.send(getUserCommand);
                
                const email = userResponse.UserAttributes.find(attr => attr.Name === 'email')?.Value;
                const userId = userResponse.UserAttributes.find(attr => attr.Name === 'sub')?.Value || userResponse.Username;
                const firstName = userResponse.UserAttributes.find(attr => attr.Name === 'given_name')?.Value;
                const lastName = userResponse.UserAttributes.find(attr => attr.Name === 'family_name')?.Value;

                console.log(`🔐 Authenticated user: ${email} (${userId})`);

                // Query businesses for this user
                let businesses = [];
                try {
                    // Try to get businesses from DynamoDB (same logic as signin)
                    const businessQueryCommand = new QueryCommand({
                        TableName: process.env.BUSINESSES_TABLE || 'wizzgo-dev-businesses',
                        IndexName: 'GSI1',
                        KeyConditionExpression: 'GSI1PK = :userPK',
                        ExpressionAttributeValues: {
                            ':userPK': `USER#${userId}`
                        }
                    });

                    const businessResult = await dynamoClient.send(businessQueryCommand);
                    
                    if (businessResult.Items && businessResult.Items.length > 0) {
                        businesses = businessResult.Items.map(item => ({
                            businessId: item.businessId,
                            businessName: item.businessName || item.name || `Business for ${firstName} ${lastName}`,
                            email: item.email || email,
                            ownerId: item.ownerId || userId,
                            cognitoUserId: item.cognitoUserId || userId,
                            status: item.status || 'pending',
                            businessType: item.businessType || 'restaurant',
                            address: item.address || 'Default Address',
                            phoneNumber: item.phoneNumber || '+1234567890'
                        }));
                    } else {
                        // Create a fallback business entry if none found
                        businesses = [{
                            businessId: `business_${userId}`,
                            businessName: `Business for ${firstName} ${lastName}`,
                            email: email,
                            ownerId: userId,
                            cognitoUserId: userId,
                            status: 'pending',
                            businessType: 'restaurant',
                            address: 'Default Address',
                            phoneNumber: '+1234567890'
                        }];
                    }
                } catch (businessError) {
                    console.error('Error querying businesses:', businessError);
                    // Create a fallback business entry if query fails
                    businesses = [{
                        businessId: `business_${userId}`,
                        businessName: `Business for ${firstName} ${lastName}`,
                        email: email,
                        ownerId: userId,
                        cognitoUserId: userId,
                        status: 'pending',
                        businessType: 'restaurant',
                        address: 'Default Address',
                        phoneNumber: '+1234567890'
                    }];
                }

                console.log(`✅ Found ${businesses.length} businesses for user ${email}`);

                return createResponse(200, businesses);

            } catch (cognitoError) {
                console.error('Error verifying access token:', cognitoError);
                
                if (cognitoError.name === 'NotAuthorizedException') {
                    return createResponse(401, {
                        success: false,
                        message: 'Invalid or expired access token'
                    });
                }
                
                return createResponse(500, {
                    success: false,
                    message: 'Authentication service error',
                    error: cognitoError.message
                });
            }
        }

        // For other endpoints not yet implemented
        return createResponse(501, {
            success: false,
            message: 'Auth endpoint not implemented yet',
            path: path
        });
    } catch (error) {
        console.error('Unhandled error in auth handler:', error);
        return createResponse(500, {
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};