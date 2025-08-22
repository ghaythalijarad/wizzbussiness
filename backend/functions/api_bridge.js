// API Bridge Function - Handles missing endpoints
'use strict';

const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient({ region: 'us-east-1' });

console.log('Loading API Bridge function');

exports.handler = async (event, context) => {
    console.log('API Bridge Event:', JSON.stringify(event, null, 2));

    const { httpMethod, path, pathParameters, queryStringParameters } = event;

    try {
        // Handle categories endpoint
        if (path.includes('/categories/business-type/')) {
            const businessType = pathParameters?.businessType || path.split('/').pop();
            console.log(`Getting categories for business type: ${businessType}`);

            const params = {
                TableName: 'WhizzMerchants_Categories',
                FilterExpression: 'businessType = :bt',
                ExpressionAttributeValues: {
                    ':bt': businessType
                }
            };

            const result = await dynamodb.scan(params).promise();
            console.log(`Found ${result.Items.length} categories`);

            return {
                statusCode: 200,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
                },
                body: JSON.stringify({
                    success: true,
                    categories: result.Items,
                    message: `Found ${result.Items.length} categories for ${businessType}`,
                    requestId: context.awsRequestId
                })
            };
        }

        // Handle merchant orders endpoint
        if (path.includes('/merchant/orders/')) {
            const businessId = pathParameters?.businessId || path.split('/').pop();
            console.log(`Getting orders for business: ${businessId}`);

            // Check if orders table exists, if not return empty array
            try {
                const params = {
                    TableName: 'WhizzMerchants_Orders',
                    FilterExpression: 'businessId = :bid',
                    ExpressionAttributeValues: {
                        ':bid': businessId
                    }
                };

                const result = await dynamodb.scan(params).promise();
                console.log(`Found ${result.Items.length} orders`);

                return {
                    statusCode: 200,
                    headers: {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
                    },
                    body: JSON.stringify({
                        success: true,
                        orders: result.Items,
                        message: `Found ${result.Items.length} orders for business ${businessId}`,
                        requestId: context.awsRequestId
                    })
                };
            } catch (orderError) {
                console.log('Orders table not found, returning empty orders list');
                return {
                    statusCode: 200,
                    headers: {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
                    },
                    body: JSON.stringify({
                        success: true,
                        orders: [],
                        message: `No orders found for business ${businessId}`,
                        requestId: context.awsRequestId
                    })
                };
            }
        }

        // Default response for unhandled paths
        return {
            statusCode: 404,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: false,
                message: `Endpoint not found: ${httpMethod} ${path}`,
                requestId: context.awsRequestId
            })
        };

    } catch (error) {
        console.error(`API Bridge Error:`, error);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: false,
                error: error.message,
                requestId: context.awsRequestId
            })
        };
    }
};
