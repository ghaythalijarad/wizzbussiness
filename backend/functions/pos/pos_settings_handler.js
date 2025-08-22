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
const POS_LOGS_TABLE = process.env.POS_LOGS_TABLE || 'WhizzMerchants_PosLogs';
if (!process.env.POS_LOGS_TABLE) console.log('⚠️ POS_LOGS_TABLE env not set, defaulting to WhizzMerchants_PosLogs');

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
};

/**
 * POS Settings Handler
 * Manages Point of Sale settings including API configurations, receipt settings, and printer settings
 */
exports.handler = async (event) => {
  console.log('🔧 POS Settings Handler - Event:', JSON.stringify(event, null, 2));

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
    if (method === 'GET' && path.includes('/pos-settings')) {
      return await handleGetPosSettings(businessId);
    } else if (method === 'PUT' && path.includes('/pos-settings')) {
      return await handleUpdatePosSettings(businessId, requestBody);
    } else if (method === 'POST' && path.includes('/pos-settings/test-connection')) {
      return await handleTestConnection(businessId, requestBody);
    } else if (method === 'GET' && path.includes('/pos-settings/sync-logs')) {
      return await handleGetSyncLogs(businessId);
    } else {
      return {
        statusCode: 404,
        headers: corsHeaders,
        body: JSON.stringify({ message: 'Endpoint not found' })
      };
    }

  } catch (error) {
    console.error('❌ POS Settings Handler Error:', error);
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
      Key: { businessId }
    };

    const result = await dynamodb.send(new GetCommand(params));
    if (!result.Item) {
      console.log(`❌ Business ${businessId} not found in ${BUSINESSES_TABLE}`);
      return false;
    }

    const business = result.Item;
    const hasAccess = business.ownerId === userId ||
      business.cognitoUserId === userId ||
      business.adminUsers?.includes(userId) ||
      business.staffUsers?.includes(userId);

    console.log(`🔐 Business access check for ${userId}: ${hasAccess} (ownerId=${business.ownerId} cognitoUserId=${business.cognitoUserId})`);
    return hasAccess;
  } catch (error) {
    console.error('❌ Error verifying business access:', error);
    return false;
  }
}

/**
 * Get POS settings for a business
 */
async function handleGetPosSettings(businessId) {
  try {
    const params = {
      TableName: BUSINESS_SETTINGS_TABLE,
      Key: { 
        businessId: businessId,
        setting_type: 'pos_settings'
      }
    };

    const result = await dynamodb.send(new GetCommand(params));
    
    // Return default settings if none exist
    const defaultSettings = {
      // API Settings
      apiEndpoint: '',
      apiKey: '',
      accessToken: null,
      locationId: null,
      systemType: 'genericApi',
      enabled: false,
      testMode: false,
      
      // Order Settings
      autoSendOrders: false,
      autoAcceptOrders: true,
      timeoutSeconds: 30,
      orderNotificationSound: true,
      displayOrderTimer: true,
      maxProcessingTimeMinutes: 30,
      retryAttempts: 3,
      
      // Financial Settings
      currency: 'USD',
      taxRate: 0.0,
      serviceChargeRate: 0.0,
      
      // Receipt Settings
      businessName: '',
      businessAddress: '',
      businessPhone: '',
      showLogo: false,
      showQrCode: true,
      footerMessage: 'Thank you for your business!',
      paperSize: 'A4',
      
      // Printer Settings
      printerEnabled: false,
      printerName: '',
      printerIp: '',
      autoPrintReceipts: false,
      printKitchenOrders: true
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
    console.error('❌ Error getting POS settings:', error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        success: false,
        message: 'Failed to retrieve POS settings',
        error: error.message
      })
    };
  }
}

/**
 * Update POS settings for a business
 */
async function handleUpdatePosSettings(businessId, requestBody) {
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
    console.log('📝 Updating POS settings:', settings);

    // Validate required fields
    const validSystemTypes = ['genericApi', 'square', 'toast', 'clover', 'shopify', 'woocommerce'];
    if (settings.systemType && !validSystemTypes.includes(settings.systemType)) {
      return {
        statusCode: 400,
        headers: corsHeaders,
        body: JSON.stringify({
          success: false,
          message: 'Invalid system type'
        })
      };
    }

    const params = {
      TableName: BUSINESS_SETTINGS_TABLE,
      Key: {
        businessId: businessId,
        setting_type: 'pos_settings'
      },
      UpdateExpression: 'SET settings = :settings, updated_at = :updated_at',
      ExpressionAttributeValues: {
        ':settings': settings,
        ':updated_at': new Date().toISOString()
      },
      ReturnValues: 'ALL_NEW'
    };

    const result = await dynamodb.send(new UpdateCommand(params));

    // Log the update for audit purposes
    await logPosSettingsChange(businessId, 'settings_updated', settings);

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({
        success: true,
        message: 'POS settings updated successfully',
        settings: result.Attributes.settings
      })
    };

  } catch (error) {
    console.error('❌ Error updating POS settings:', error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        success: false,
        message: 'Failed to update POS settings',
        error: error.message
      })
    };
  }
}

/**
 * Test POS system connection
 */
async function handleTestConnection(businessId, requestBody) {
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

    const config = JSON.parse(requestBody);
    console.log('🔗 Testing POS connection:', { ...config, api_key: '***' });

    const startTime = Date.now();
    let testResult = {
      success: false,
      message: '',
      response_time_ms: 0,
      error_details: null
    };

    try {
      // Test connection based on system type
      switch (config.system_type) {
        case 'square':
          testResult = await testSquareConnection(config);
          break;
        case 'toast':
          testResult = await testToastConnection(config);
          break;
        case 'clover':
          testResult = await testCloverConnection(config);
          break;
        case 'shopify':
          testResult = await testShopifyConnection(config);
          break;
        case 'woocommerce':
          testResult = await testWooCommerceConnection(config);
          break;
        default:
          testResult = await testGenericApiConnection(config);
      }
    } catch (testError) {
      testResult = {
        success: false,
        message: 'Connection test failed',
        response_time_ms: Date.now() - startTime,
        error_details: testError.message
      };
    }

    testResult.response_time_ms = Date.now() - startTime;

    // Log the connection test
    await logPosSettingsChange(businessId, 'connection_test', {
      system_type: config.system_type,
      result: testResult
    });

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({
        success: true,
        ...testResult
      })
    };

  } catch (error) {
    console.error('❌ Error testing POS connection:', error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        success: false,
        message: 'Failed to test connection',
        error: error.message
      })
    };
  }
}

/**
 * Get sync logs for POS operations
 */
async function handleGetSyncLogs(businessId) {
  try {
    const params = {
      TableName: POS_LOGS_TABLE,
      IndexName: 'business-id-timestamp-index',
      KeyConditionExpression: 'businessId = :businessId',
      ExpressionAttributeValues: {
        ':businessId': businessId
      },
      ScanIndexForward: false, // Most recent first
      Limit: 50
    };

    const result = await dynamodb.send(new QueryCommand(params));

    return {
      statusCode: 200,
      headers: corsHeaders,
      body: JSON.stringify({
        success: true,
        logs: result.Items || []
      })
    };

  } catch (error) {
    console.error('❌ Error getting sync logs:', error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({
        success: false,
        message: 'Failed to retrieve sync logs',
        error: error.message
      })
    };
  }
}

/**
 * Test generic API connection
 */
async function testGenericApiConnection(config) {
  const axios = require('axios');
  
  try {
    const headers = {
      'Content-Type': 'application/json'
    };

    if (config.api_key) {
      headers['Authorization'] = `Bearer ${config.api_key}`;
    }

    const response = await axios.get(config.api_endpoint, {
      headers,
      timeout: 10000
    });

    return {
      success: response.status >= 200 && response.status < 300,
      message: response.status >= 200 && response.status < 300 ? 
        'Connection successful' : 
        `Connection failed with status ${response.status}`
    };
  } catch (error) {
    return {
      success: false,
      message: 'Connection failed',
      error_details: error.message
    };
  }
}

/**
 * Test Square POS connection
 */
async function testSquareConnection(config) {
  const axios = require('axios');
  
  try {
    const headers = {
      'Authorization': `Bearer ${config.access_token}`,
      'Content-Type': 'application/json',
      'Square-Version': '2023-10-18'
    };

    const response = await axios.get(
      `${config.api_endpoint || 'https://connect.squareup.com'}/v2/locations`,
      { headers, timeout: 10000 }
    );

    return {
      success: true,
      message: `Square connection successful. Found ${response.data.locations?.length || 0} locations.`
    };
  } catch (error) {
    return {
      success: false,
      message: 'Square connection failed',
      error_details: error.response?.data?.message || error.message
    };
  }
}

/**
 * Test Toast POS connection
 */
async function testToastConnection(config) {
  const axios = require('axios');
  
  try {
    const headers = {
      'Authorization': `Bearer ${config.access_token}`,
      'Content-Type': 'application/json',
      'Toast-Restaurant-External-ID': config.location_id
    };

    const response = await axios.get(
      `${config.api_endpoint || 'https://ws-api.toasttab.com'}/restaurants/v1/restaurants`,
      { headers, timeout: 10000 }
    );

    return {
      success: true,
      message: 'Toast POS connection successful'
    };
  } catch (error) {
    return {
      success: false,
      message: 'Toast POS connection failed',
      error_details: error.response?.data?.message || error.message
    };
  }
}

/**
 * Test Clover POS connection
 */
async function testCloverConnection(config) {
  const axios = require('axios');
  
  try {
    const headers = {
      'Authorization': `Bearer ${config.access_token}`,
      'Content-Type': 'application/json'
    };

    const response = await axios.get(
      `${config.api_endpoint || 'https://api.clover.com'}/v3/merchants/${config.location_id}`,
      { headers, timeout: 10000 }
    );

    return {
      success: true,
      message: 'Clover POS connection successful'
    };
  } catch (error) {
    return {
      success: false,
      message: 'Clover POS connection failed',
      error_details: error.response?.data?.message || error.message
    };
  }
}

/**
 * Test Shopify connection
 */
async function testShopifyConnection(config) {
  const axios = require('axios');
  
  try {
    const headers = {
      'X-Shopify-Access-Token': config.access_token,
      'Content-Type': 'application/json'
    };

    const response = await axios.get(
      `${config.api_endpoint}/admin/api/2023-10/shop.json`,
      { headers, timeout: 10000 }
    );

    return {
      success: true,
      message: 'Shopify connection successful'
    };
  } catch (error) {
    return {
      success: false,
      message: 'Shopify connection failed',
      error_details: error.response?.data?.message || error.message
    };
  }
}

/**
 * Test WooCommerce connection
 */
async function testWooCommerceConnection(config) {
  const axios = require('axios');
  
  try {
    const auth = Buffer.from(`${config.api_key}:${config.access_token}`).toString('base64');
    const headers = {
      'Authorization': `Basic ${auth}`,
      'Content-Type': 'application/json'
    };

    const response = await axios.get(
      `${config.api_endpoint}/wp-json/wc/v3/system_status`,
      { headers, timeout: 10000 }
    );

    return {
      success: true,
      message: 'WooCommerce connection successful'
    };
  } catch (error) {
    return {
      success: false,
      message: 'WooCommerce connection failed',
      error_details: error.response?.data?.message || error.message
    };
  }
}

/**
 * Log POS settings changes and operations
 */
async function logPosSettingsChange(businessId, action, details) {
  try {
    const logEntry = {
      id: `${businessId}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      businessId: businessId,
      timestamp: new Date().toISOString(),
      action: action,
      details: details,
      ttl: Math.floor(Date.now() / 1000) + (90 * 24 * 60 * 60) // 90 days retention
    };

    const params = {
      TableName: POS_LOGS_TABLE,
      Item: logEntry
    };

    await dynamodb.send(new PutCommand(params));
    console.log('📝 POS log entry created:', action);
  } catch (error) {
    console.error('❌ Error logging POS change:', error);
    // Don't throw error for logging failures
  }
}
