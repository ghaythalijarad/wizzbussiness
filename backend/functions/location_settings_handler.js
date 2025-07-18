const AWS = require('aws-sdk');
const jwt = require('jsonwebtoken');

// Initialize DynamoDB
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Table names from environment variables
const BUSINESSES_TABLE = process.env.BUSINESSES_TABLE || 'order-receiver-businesses-dev';
const BUSINESS_SETTINGS_TABLE = process.env.BUSINESS_SETTINGS_TABLE || 'order-receiver-business-settings-dev';

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
};

/**
 * Location Settings Handler
 * Manages business location settings including GPS coordinates and address information
 */
exports.handler = async (event) => {
  console.log('📍 Location Settings Handler - Event:', JSON.stringify(event, null, 2));

  // Handle preflight CORS requests
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({ message: 'CORS preflight successful' })
    };
  }

  try {
    // Extract user information from JWT token
    const authHeader = event.headers.Authorization || event.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return {
        statusCode: 401,
        headers: corsHeaders,
        body: JSON.stringify({ message: 'Authorization token required' })
      };
    }

    const token = authHeader.substring(7);
    let decodedToken;
    
    try {
      decodedToken = jwt.decode(token);
      console.log('🔐 Decoded token:', decodedToken);
    } catch (error) {
      console.error('❌ Token decode error:', error);
      return {
        statusCode: 401,
        headers: corsHeaders,
        body: JSON.stringify({ message: 'Invalid authorization token' })
      };
    }

    const userId = decodedToken.sub || decodedToken['cognito:username'];
    if (!userId) {
      return {
        statusCode: 401,
        headers: corsHeaders,
        body: JSON.stringify({ message: 'User ID not found in token' })
      };
    }

    // Get business ID from path parameters or query parameters
    const businessId = event.pathParameters?.businessId || event.queryStringParameters?.businessId;
    if (!businessId) {
      return {
        statusCode: 400,
        headers: corsHeaders,
        body: JSON.stringify({ message: 'Business ID is required' })
      };
    }

    console.log(`👤 User ID: ${userId}, 🏢 Business ID: ${businessId}`);

    // Verify user has access to this business
    const hasAccess = await verifyBusinessAccess(userId, businessId);
    if (!hasAccess) {
      return {
        statusCode: 403,
        headers: corsHeaders,
        body: JSON.stringify({ message: 'Access denied to this business' })
      };
    }

    const method = event.httpMethod;
    const path = event.resource || event.path;

    // Route to appropriate handler based on method and path
    if (method === 'GET' && path.includes('/location-settings')) {
      return await handleGetLocationSettings(businessId);
    } else if (method === 'PUT' && path.includes('/location-settings')) {
      return await handleUpdateLocationSettings(businessId, event.body);
    } else {
      return {
        statusCode: 404,
        headers: corsHeaders,
        body: JSON.stringify({ message: 'Endpoint not found' })
      };
    }

  } catch (error) {
    console.error('❌ Location Settings Handler Error:', error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({ 
        message: 'Internal server error',
        error: error.message 
      })
    };
  }
};

/**
 * Verify user has access to the specified business
 */
async function verifyBusinessAccess(userId, businessId) {
  try {
    const params = {
      TableName: BUSINESSES_TABLE,
      Key: { businessId: businessId }
    };

    const result = await dynamodb.get(params).promise();
    
    if (!result.Item) {
      console.log(`❌ Business ${businessId} not found`);
      return false;
    }

    // Check if user is the owner or has access
    const business = result.Item;
    const hasAccess = business.owner_id === userId || 
                     business.cognito_user_id === userId ||
                     business.admin_users?.includes(userId) ||
                     business.staff_users?.includes(userId);

    console.log(`🔐 Business access check for ${userId}: ${hasAccess}`);
    console.log(`🏢 Business owner_id: ${business.owner_id}`);
    console.log(`🏢 Business cognito_user_id: ${business.cognito_user_id}`);
    return hasAccess;
  } catch (error) {
    console.error('❌ Error verifying business access:', error);
    return false;
  }
}

/**
 * Get location settings for a business
 */
async function handleGetLocationSettings(businessId) {
  try {
    const params = {
      TableName: BUSINESS_SETTINGS_TABLE,
      Key: { 
        business_id: businessId,
        setting_type: 'location_settings'
      }
    };

    const result = await dynamodb.get(params).promise();
    
    // Return default settings if none exist
    const defaultSettings = {
      latitude: null,
      longitude: null,
      address: null,
      updated_at: null
    };

    const settings = result.Item ? 
      { ...defaultSettings, ...result.Item.settings } : 
      defaultSettings;

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({
        success: true,
        settings: settings
      })
    };

  } catch (error) {
    console.error('❌ Error getting location settings:', error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        success: false,
        message: 'Failed to retrieve location settings',
        error: error.message
      })
    };
  }
}

/**
 * Update location settings for a business
 */
async function handleUpdateLocationSettings(businessId, requestBody) {
  try {
    if (!requestBody) {
      return {
        statusCode: 400,
        headers: corsHeaders,
        body: JSON.stringify({
          success: false,
          message: 'Request body is required'
        })
      };
    }

    const settings = JSON.parse(requestBody);
    console.log('📍 Updating location settings:', settings);

    // Validate location data
    if (settings.latitude !== null && settings.latitude !== undefined) {
      const lat = parseFloat(settings.latitude);
      if (isNaN(lat) || lat < -90 || lat > 90) {
        return {
          statusCode: 400,
          headers: corsHeaders,
          body: JSON.stringify({
            success: false,
            message: 'Invalid latitude. Must be between -90 and 90 degrees.'
          })
        };
      }
      settings.latitude = lat;
    }

    if (settings.longitude !== null && settings.longitude !== undefined) {
      const lng = parseFloat(settings.longitude);
      if (isNaN(lng) || lng < -180 || lng > 180) {
        return {
          statusCode: 400,
          headers: corsHeaders,
          body: JSON.stringify({
            success: false,
            message: 'Invalid longitude. Must be between -180 and 180 degrees.'
          })
        };
      }
      settings.longitude = lng;
    }

    const params = {
      TableName: BUSINESS_SETTINGS_TABLE,
      Key: {
        business_id: businessId,
        setting_type: 'location_settings'
      },
      UpdateExpression: 'SET settings = :settings, updated_at = :updated_at',
      ExpressionAttributeValues: {
        ':settings': settings,
        ':updated_at': new Date().toISOString()
      },
      ReturnValues: 'ALL_NEW'
    };

    const result = await dynamodb.update(params).promise();

    // Also update the main business table with the location data for consistency
    if (settings.latitude !== null && settings.longitude !== null) {
      await updateBusinessLocation(businessId, settings.latitude, settings.longitude, settings.address);
    }

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({
        success: true,
        message: 'Location settings updated successfully',
        settings: result.Attributes.settings
      })
    };

  } catch (error) {
    console.error('❌ Error updating location settings:', error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        success: false,
        message: 'Failed to update location settings',
        error: error.message
      })
    };
  }
}

/**
 * Update the main business table with location information
 */
async function updateBusinessLocation(businessId, latitude, longitude, address) {
  try {
    let updateExpression = 'SET latitude = :lat, longitude = :lng, updated_at = :updated_at';
    const expressionAttributeValues = {
      ':lat': latitude,
      ':lng': longitude,
      ':updated_at': new Date().toISOString()
    };

    if (address) {
      updateExpression += ', address = :addr';
      expressionAttributeValues[':addr'] = address;
    }

    const params = {
      TableName: BUSINESSES_TABLE,
      Key: { businessId: businessId },
      UpdateExpression: updateExpression,
      ExpressionAttributeValues: expressionAttributeValues
    };

    await dynamodb.update(params).promise();
    console.log('✅ Business location updated in main table');
  } catch (error) {
    console.error('⚠️ Error updating business location in main table:', error);
    // Don't throw error - location settings update should still succeed
  }
}
