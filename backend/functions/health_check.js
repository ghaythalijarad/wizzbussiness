'use strict';

console.log('Loading function');

exports.handler = async (event, context) => {
    console.log('Health check requested');

    try {
        const response = {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,OPTIONS'
            },
            body: JSON.stringify({
                status: 'healthy',
                message: 'Order Receiver App is running',
                timestamp: context.awsRequestId,
                version: '2.0.0'
            }),
        };
        return response;
    } catch (e) {
        console.error(`Health check failed: ${e}`);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                status: 'unhealthy',
                error: e.toString(),
            }),
        };
    }
};
