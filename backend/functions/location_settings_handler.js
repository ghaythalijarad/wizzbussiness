const AWS = require('aws-sdk');
const jwt = require('jsonwebtoken');

// Initialize DynamoDB
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Table names from environment variables
const BUSINESSES_TABLE = process.env.BUSINESSES_TABLE || 'order-receiver-businesses-dev';
const BUSINESS_SETTINGS_TABLE = process.env.BUSINESS_SETTINGS_TABLE || 'order-receiver-business-settings-dev';
const BUSINESS_WORKING_HOURS_TABLE = process.env.BUSINESS_WORKING_HOURS_TABLE || 'order-receiver-business-working-hours-dev';

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
    // Handle Base64 encoded request body from API Gateway
    let requestBody = event.body;
    if (event.isBase64Encoded && requestBody) {
      try {
        requestBody = Buffer.from(requestBody, 'base64').toString('utf-8');
        console.log('📝 Decoded Base64 request body');
      } catch (decodeError) {
        console.error('❌ Failed to decode Base64 body:', decodeError);
      }
    }
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
      return await handleUpdateLocationSettings(businessId, requestBody);
    } else if (method === 'GET' && path.includes('/working-hours')) {
      return await handleGetWorkingHours(businessId);
    } else if (method === 'PUT' && path.includes('/working-hours')) {
      return await handleUpdateWorkingHours(businessId, requestBody);
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
    const hasAccess = business.ownerId === userId ||
                      business.cognitoUserId === userId ||
                      business.adminUsers?.includes(userId) ||
                      business.staffUsers?.includes(userId);

    console.log(`🔐 Business access check for ${userId}: ${hasAccess}`);
    console.log(`🏢 Business ownerId: ${business.ownerId}`);
    console.log(`🏢 Business cognitoUserId: ${business.cognitoUserId}`);
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
 * Get working hours for a business
 */
async function handleGetWorkingHours(businessId) {
  console.log(`🕒 Getting working hours for business: ${businessId}`);
  
  try {
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    
    console.log(`📅 Querying working hours for weekdays: ${weekdays.join(', ')}`);
    
    const results = await Promise.all(
      weekdays.map(async (day) => {
        try {
          const result = await dynamodb.get({
            TableName: BUSINESS_WORKING_HOURS_TABLE,
            Key: { business_id: businessId, weekday: day }
          }).promise();
          
          console.log(`📋 ${day}: ${result.Item ? 'Found data' : 'No data'}`);
          return result;
        } catch (error) {
          console.error(`❌ Error querying ${day}:`, error);
          return { Item: null }; // Return empty result on error
        }
      })
    );
    
    const workingHours = {};
    weekdays.forEach((day, idx) => {
      workingHours[day] = results[idx].Item ? {
        opening: results[idx].Item.opening,
        closing: results[idx].Item.closing
      } : { opening: null, closing: null };
    });
    
    console.log(`✅ Successfully retrieved working hours for business ${businessId}`);
    console.log(`📊 Working hours data:`, JSON.stringify(workingHours, null, 2));
    
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({ success: true, workingHours })
    };
  } catch (error) {
    console.error(`❌ Error getting working hours for business ${businessId}:`, error);
    
    // Return default empty working hours instead of error
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const defaultWorkingHours = {};
    weekdays.forEach(day => {
      defaultWorkingHours[day] = { opening: null, closing: null };
    });
    
    console.log(`🔄 Returning default empty working hours for business ${businessId}`);
    
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({ 
        success: true, 
        workingHours: defaultWorkingHours,
        message: 'No working hours found, returning defaults'
      })
    };
  }
}

/**
 * Update working hours for a business
 */
async function handleUpdateWorkingHours(businessId, requestBody) {
  console.log(`🕒 Updating working hours for business: ${businessId}`);
  
  try {
    if (!requestBody) {
      console.error(`❌ No request body provided for business ${businessId}`);
      return {
        statusCode: 400,
        headers: corsHeaders,
        body: JSON.stringify({ success: false, message: 'Request body is required' })
      };
    }
    
    const workingHours = JSON.parse(requestBody);
    console.log(`📊 Working hours data to save:`, JSON.stringify(workingHours, null, 2));
    
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    
    const updatePromises = weekdays.map(async (day) => {
      const hours = workingHours[day] || {};
      
      try {
        const result = await dynamodb.put({
          TableName: BUSINESS_WORKING_HOURS_TABLE,
          Item: {
            business_id: businessId,
            weekday: day,
            opening: hours.opening || null,
            closing: hours.closing || null,
            updated_at: new Date().toISOString()
          }
        }).promise();
        
        console.log(`✅ Updated ${day} for business ${businessId}`);
        return result;
      } catch (error) {
        console.error(`❌ Error updating ${day} for business ${businessId}:`, error);
        throw error;
      }
    });
    
    await Promise.all(updatePromises);
    
    console.log(`✅ Successfully updated all working hours for business ${businessId}`);
    
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({ success: true, message: 'Working hours updated successfully' })
    };
  } catch (error) {
    console.error(`❌ Error updating working hours for business ${businessId}:`, error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({ success: false, message: 'Failed to update working hours', error: error.message })
    };
  }
}

/**
 * Update the main business table with location information
 */
async function updateBusinessLocation(businessId, latitude, longitude, address) {
  try {
    // First, get the current business data to preserve existing address if needed
    const getCurrentParams = {
      TableName: BUSINESSES_TABLE,
      Key: { businessId: businessId },
      ProjectionExpression: 'address'
    };
    
    const currentBusiness = await dynamodb.get(getCurrentParams).promise();
    
    let updateExpression = 'SET latitude = :lat, longitude = :lng, updatedAt = :updatedAt';
    const expressionAttributeValues = {
      ':lat': latitude,
      ':lng': longitude,
      ':updatedAt': new Date().toISOString()
    };

    // Only update address if it's provided and not the stub implementation
    if (address && address !== 'Address not available (stub implementation)' && address !== 'Address not available') {
      updateExpression += ', address = :addr';
      expressionAttributeValues[':addr'] = address;
      console.log('✅ Updating address with new value:', address);
    } else if (currentBusiness.Item && currentBusiness.Item.address) {
      // Preserve existing address if new address is stub or null
      updateExpression += ', address = :addr';
      expressionAttributeValues[':addr'] = currentBusiness.Item.address;
      console.log('✅ Preserving existing address:', currentBusiness.Item.address);
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
