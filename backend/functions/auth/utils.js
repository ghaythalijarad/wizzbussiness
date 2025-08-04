'use strict';
const { jwtDecode } = require('jwt-decode');

function getBusinessIdFromToken(authHeader) {
    console.log('getBusinessIdFromToken called with authHeader:', authHeader ? 'Present' : 'Missing');

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        console.log('No valid authorization header provided. AuthHeader:', authHeader);
        return null;
    }

    const token = authHeader.split(' ')[1];
    console.log('Extracted token (first 50 chars):', token ? token.substring(0, 50) + '...' : 'null');

    try {
        const decodedToken = jwtDecode(token);
        console.log('Decoded token claims:', JSON.stringify(decodedToken, null, 2));

        // The business ID is stored in a custom claim `custom:business_id`
        const businessId = decodedToken['custom:business_id'];
        console.log('Extracted business ID:', businessId);

        if (!businessId) {
            console.error('Business ID not found in token. Available claims:', Object.keys(decodedToken));
            return null;
        }
        return businessId;
    } catch (error) {
        console.error('Error decoding token:', error);
        return null;
    }
}

function createResponse(statusCode, body) {
    return {
        statusCode: statusCode,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        body: JSON.stringify(body)
    };
}

module.exports = { createResponse, getBusinessIdFromToken };
