/**
 * AWS Lambda Function: Register FCM Device Token
 * 
 * This function registers Firebase device tokens from the Flutter app
 * Stores them in DynamoDB for later use when sending push notifications
 * Called from ApiService.registerDeviceToken()
 */

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient({ region: 'us-east-1' });

exports.handler = async (event) => {
    console.log('Device token registration event:', JSON.stringify(event, null, 2));

    try {
        // Parse request body
        const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
        const { 
            deviceToken, 
            businessId, 
            platform, // 'ios' or 'android'
            userId 
        } = body;

        // Validate required fields
        if (!deviceToken || !businessId) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    success: false,
                    error: 'Missing required fields: deviceToken and businessId'
                })
            };
        }

        // Store device token in DynamoDB
        const item = {
            PK: `BUSINESS#${businessId}`,
            SK: `TOKEN#${deviceToken}`,
            deviceToken: deviceToken,
            businessId: businessId,
            platform: platform || 'unknown',
            userId: userId || businessId,
            registrationDate: new Date().toISOString(),
            isActive: true,
            lastUpdated: new Date().toISOString(),
            ttl: Math.floor(Date.now() / 1000) + (90 * 24 * 60 * 60) // 90 days TTL
        };

        const params = {
            TableName: process.env.DEVICE_TOKENS_TABLE || 'DeviceTokens',
            Item: item,
            // Use condition to avoid overwriting with older data
            ConditionExpression: 'attribute_not_exists(PK) OR lastUpdated < :now',
            ExpressionAttributeValues: {
                ':now': item.lastUpdated
            }
        };

        try {
            await dynamodb.put(params).promise();
        } catch (conditionalError) {
            if (conditionalError.code === 'ConditionalCheckFailedException') {
                // Token already exists with newer timestamp, just update the timestamp
                const updateParams = {
                    TableName: process.env.DEVICE_TOKENS_TABLE || 'DeviceTokens',
                    Key: {
                        PK: item.PK,
                        SK: item.SK
                    },
                    UpdateExpression: 'SET lastUpdated = :now, isActive = :active, #ttl = :ttl',
                    ExpressionAttributeNames: {
                        '#ttl': 'ttl'
                    },
                    ExpressionAttributeValues: {
                        ':now': item.lastUpdated,
                        ':active': true,
                        ':ttl': item.ttl
                    }
                };
                await dynamodb.update(updateParams).promise();
            } else {
                throw conditionalError;
            }
        }

        // Also create a reverse lookup for efficient querying
        const reverseLookupItem = {
            PK: `TOKEN#${deviceToken}`,
            SK: `BUSINESS#${businessId}`,
            deviceToken: deviceToken,
            businessId: businessId,
            platform: platform || 'unknown',
            registrationDate: item.registrationDate,
            isActive: true,
            ttl: item.ttl
        };

        const reverseLookupParams = {
            TableName: process.env.DEVICE_TOKENS_TABLE || 'DeviceTokens',
            Item: reverseLookupItem
        };

        await dynamodb.put(reverseLookupParams).promise();
        
        console.log('Device token registered successfully:', {
            deviceToken: deviceToken,
            businessId: businessId,
            platform: platform
        });

        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            body: JSON.stringify({
                success: true,
                deviceToken: deviceToken,
                businessId: businessId,
                platform: platform,
                timestamp: new Date().toISOString()
            })
        };

    } catch (error) {
        console.error('Error registering device token:', error);
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            })
        };
    }
};

// Handle CORS preflight requests - this should be in a separate handler or middleware

/**
 * Environment Variables Required:
 * - DEVICE_TOKENS_TABLE: DynamoDB table name for storing device tokens
 * 
 * IAM Permissions Required:
 * - dynamodb:PutItem
 * - dynamodb:UpdateItem
 * - dynamodb:GetItem
 * - logs:CreateLogGroup
 * - logs:CreateLogStream
 * - logs:PutLogEvents
 * 
 * DynamoDB Table Structure:
 * Table Name: DeviceTokens
 * Partition Key: PK (String)
 * Sort Key: SK (String)
 * TTL Attribute: ttl (Number)
 * 
 * API Gateway Integration:
 * POST /device-token/register
 * - Enable CORS
 * - Set up proper authorization (Cognito User Pool)
 */
