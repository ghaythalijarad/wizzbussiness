const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand, QueryCommand, ScanCommand } = require('@aws-sdk/lib-dynamodb');
const jwt = require('jsonwebtoken');

// Initialize DynamoDB
const dynamoDbClient = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

// Table names from environment variables
const BUSINESSES_TABLE = process.env.BUSINESSES_TABLE || 'WhizzMerchants_Businesses';
if (!process.env.BUSINESSES_TABLE) console.log('⚠️ BUSINESSES_TABLE env not set, defaulting to WhizzMerchants_Businesses');
const BUSINESS_SETTINGS_TABLE = process.env.BUSINESS_SETTINGS_TABLE || 'WhizzMerchants_BusinessSettings';
if (!process.env.BUSINESS_SETTINGS_TABLE) console.log('⚠️ BUSINESS_SETTINGS_TABLE env not set, defaulting to WhizzMerchants_BusinessSettings');
const BUSINESS_WORKING_HOURS_TABLE = process.env.BUSINESS_WORKING_HOURS_TABLE || 'WhizzMerchants_BusinessWorkingHours';
if (!process.env.BUSINESS_WORKING_HOURS_TABLE) console.log('⚠️ BUSINESS_WORKING_HOURS_TABLE env not set, defaulting to WhizzMerchants_BusinessWorkingHours');

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

    const result = await dynamodb.send(new GetCommand(params));
    
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
    // Try new schema first
    let params = {
      TableName: BUSINESS_SETTINGS_TABLE,
      Key: { 
        businessId: businessId,
        setting_type: 'location_settings'
      }
    };

    let result = await dynamodb.send(new GetCommand(params));

    // Fallback: legacy key pattern (business_id)
    if (!result.Item) {
      const legacyParams = {
        TableName: BUSINESS_SETTINGS_TABLE,
        Key: {
          business_id: businessId,
          setting_type: 'location_settings'
        }
      };
      try {
        const legacyResult = await dynamodb.send(new GetCommand(legacyParams));
        if (legacyResult.Item) {
          console.log('⚠️ Using legacy location_settings record with business_id key');
          result = legacyResult;
        }
      } catch (legacyErr) { /* ignore */ }
    }

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
    const data = typeof requestBody === 'string' ? JSON.parse(requestBody || '{}') : (requestBody || {});
    const updatedAt = new Date().toISOString();

    const item = {
      businessId: businessId,
      setting_type: 'location_settings',
      settings: {
        latitude: data.latitude ?? null,
        longitude: data.longitude ?? null,
        address: data.address ?? null,
        updated_at: updatedAt
      }
    };

    await dynamodb.send(new PutCommand({ TableName: BUSINESS_SETTINGS_TABLE, Item: item }));

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({ message: 'Location settings updated', settings: item.settings })
    };
  } catch (error) {
    console.error('❌ Error updating location settings:', error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({ message: 'Failed to update location settings', error: error.message })
    };
  }
}

/**
 * Get working hours for a business
 */
async function handleGetWorkingHours(businessId) {
  try {
    let params = {
      TableName: BUSINESS_WORKING_HOURS_TABLE,
      Key: { businessId: businessId, record_type: 'working_hours' }
    };
    let result = await dynamodb.send(new GetCommand(params));
    if (!result.Item) {
      const legacyParams = { TableName: BUSINESS_WORKING_HOURS_TABLE, Key: { business_id: businessId, record_type: 'working_hours' } };
      try {
        const legacyResult = await dynamodb.send(new GetCommand(legacyParams));
        if (legacyResult.Item) { console.log('⚠️ Using legacy working_hours record with business_id key'); result = legacyResult; }
      } catch (e) { /* ignore */ }
    }

    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const workingHours = {};
    weekdays.forEach((day) => {
      workingHours[day] = result.Item?.hours?.[day] || { opening: null, closing: null };
    });

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({ success: true, workingHours })
    };
  } catch (error) {
    console.error(`❌ Error getting working hours for business ${businessId}:`, error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({ success: false, message: 'Failed to retrieve working hours', error: error.message })
    };
  }
}

/**
 * Update working hours for a business
 */
async function handleUpdateWorkingHours(businessId, requestBody) {
  try {
    const data = typeof requestBody === 'string' ? JSON.parse(requestBody || '{}') : (requestBody || {});
    const updatedAt = new Date().toISOString();

    const item = {
      businessId: businessId,
      record_type: 'working_hours',
      hours: data.hours ?? [],
      updated_at: updatedAt
    };

    await dynamodb.send(new PutCommand({ TableName: BUSINESS_WORKING_HOURS_TABLE, Item: item }));

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({ message: 'Working hours updated', hours: item.hours })
    };
  } catch (error) {
    console.error('❌ Error updating working hours:', error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({ message: 'Failed to update working hours', error: error.message })
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
    
    const currentBusiness = await dynamodb.send(new GetCommand(getCurrentParams));
    
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

    await dynamodb.send(new UpdateCommand(params));
    console.log('✅ Business location updated in main table');
  } catch (error) {
    console.error('⚠️ Error updating business location in main table:', error);
    // Don't throw error - location settings update should still succeed
  }
}
