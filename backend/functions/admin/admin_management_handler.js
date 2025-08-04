'use strict';

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { createResponse } = require('../auth/utils');

const dynamoDbClient = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);
const BUSINESSES_TABLE = process.env.BUSINESSES_TABLE;

module.exports.handler = async (event) => {
    const { httpMethod, path, pathParameters, body } = event;
    const requestBody = JSON.parse(body || '{}');

    // For now, we'll secure this with a simple API key or IAM role in a real scenario.
    // For this task, I'll assume authorization is handled by API Gateway.

    if (httpMethod === 'POST' && path.includes('/approve')) {
        const { businessId } = pathParameters;
        return await approveMerchant(businessId);
    }

    if (httpMethod === 'POST' && path.includes('/reject')) {
        const { businessId } = pathParameters;
        return await rejectMerchant(businessId);
    }

    if (httpMethod === 'GET' && path.includes('/admin/businesses')) {
        return await getPendingBusinesses();
    }

    return createResponse(404, { message: 'Not Found' });
};

async function getPendingBusinesses() {
    const params = {
        TableName: BUSINESSES_TABLE,
        FilterExpression: '#status = :status',
        ExpressionAttributeNames: { '#status': 'status' },
        ExpressionAttributeValues: { ':status': 'pending' }
    };

    try {
        const result = await dynamodb.send(new ScanCommand(params));
        return createResponse(200, result.Items);
    } catch (error) {
        console.error('Error fetching pending businesses:', error);
        return createResponse(500, { success: false, message: 'Failed to fetch pending businesses.' });
    }
}

async function approveMerchant(businessId) {
    if (!businessId) {
        return createResponse(400, { message: 'businessId is required' });
    }

    const params = {
        TableName: BUSINESSES_TABLE,
        Key: { businessId },
        UpdateExpression: 'set #status = :status',
        ExpressionAttributeNames: { '#status': 'status' },
        ExpressionAttributeValues: { ':status': 'approved' },
        ReturnValues: 'UPDATED_NEW',
    };

    try {
        await dynamodb.send(new UpdateCommand(params));
        return createResponse(200, { success: true, message: `Business ${businessId} approved.` });
    } catch (error) {
        console.error('Error approving merchant:', error);
        return createResponse(500, { success: false, message: 'Failed to approve merchant.' });
    }
}

async function rejectMerchant(businessId) {
    if (!businessId) {
        return createResponse(400, { message: 'businessId is required' });
    }

    const params = {
        TableName: BUSINESSES_TABLE,
        Key: { businessId },
        UpdateExpression: 'set #status = :status',
        ExpressionAttributeNames: { '#status': 'status' },
        ExpressionAttributeValues: { ':status': 'rejected' },
        ReturnValues: 'UPDATED_NEW',
    };

    try {
        await dynamodb.send(new UpdateCommand(params));
        return createResponse(200, { success: true, message: `Business ${businessId} rejected.` });
    } catch (error) {
        console.error('Error rejecting merchant:', error);
        return createResponse(500, { success: false, message: 'Failed to reject merchant.' });
    }
}
