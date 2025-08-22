const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const {
  DynamoDBDocumentClient,
  ScanCommand,
  GetCommand,
  PutCommand,
  DeleteCommand,
  UpdateCommand,
  QueryCommand,
} = require('@aws-sdk/lib-dynamodb');
const { CognitoIdentityProviderClient, GetUserCommand } = require('@aws-sdk/client-cognito-identity-provider');
const { v4: uuidv4 } = require('uuid');

// CORS + expose both Authorization and Access-Token for debugging/future usage
const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization,Access-Token,X-Amz-Date,X-Api-Key,X-Amz-Security-Token',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
    'Access-Control-Expose-Headers': 'Authorization,Access-Token',
};

// --- Contextual logging helpers ---
function buildRequestContext(event) {
    const requestId = event?.requestContext?.requestId || event?.headers?.['x-request-id'] || `req-${Date.now()}`;
    const correlationId = event?.headers?.['x-correlation-id'] || event?.headers?.['x-correlationid'] || requestId;
    const businessId = event?.pathParameters?.businessId || event?.queryStringParameters?.businessId || undefined;
    const productId = event?.pathParameters?.productId || undefined;
    return { requestId, correlationId, businessId, productId, routeKey: event?.routeKey, rawPath: event?.rawPath || event?.path };
}

function logCTX(context, message, extra = {}) {
    console.log(JSON.stringify({
        timestamp: new Date().toISOString(),
        level: 'CTX',
        message,
        context,
        ...extra
    }));
}

function logBizResolution(context, stage, details = {}) {
    console.log(JSON.stringify({
        timestamp: new Date().toISOString(),
        level: 'BUSINESS_RESOLUTION',
        stage,
        context,
        ...details
    }));
}

const PRODUCTS_TABLE = process.env.PRODUCTS_TABLE;
const CATEGORIES_TABLE = process.env.CATEGORIES_TABLE;
const BUSINESS_SUBCATEGORIES_TABLE = process.env.BUSINESS_SUBCATEGORIES_TABLE;
const BUSINESSES_TABLE = process.env.BUSINESSES_TABLE;
const DYNAMODB_REGION = process.env.DYNAMODB_REGION || 'us-east-1';
const COGNITO_REGION = process.env.COGNITO_REGION || 'us-east-1';

const client = new DynamoDBClient({ region: DYNAMODB_REGION });
const docClient = DynamoDBDocumentClient.from(client);

const MISSING_EMAIL_INDEX_SENTINEL = '__MISSING_EMAIL_INDEX__';

function extractAccessToken(event) {
    const hdrs = event.headers || {};
    const candidates = [
        hdrs.Authorization,
        hdrs.authorization,
        hdrs['Access-Token'],
        hdrs['access-token'],
    ].filter(Boolean);

    console.log('[AuthDebug] Incoming header keys:', Object.keys(hdrs));
    console.log('[AuthDebug] Candidate auth header count:', candidates.length);

    for (const raw of candidates) {
        if (!raw) continue;
        let token = raw.trim();
        if (token.toLowerCase().startsWith('bearer')) {
            token = token.substring(6).trim();
        }
        if (token && !token.includes(' ')) {
            console.log('[AuthDebug] Selected token length:', token.length);
            console.log('[AuthDebug] Token prefix preview:', token.substring(0, 15) + '...');
            return token;
        } else {
            console.log('[AuthDebug] Skipping malformed auth value:', raw.substring(0, 25));
        }
    }
    return null;
}

async function getBusinessId(event) {
    const context = buildRequestContext(event);
    try {
        let email = null;

        // Method 1: Try to get user info from API Gateway Cognito authorizer claims (ID Token)
        const claims = event.requestContext?.authorizer?.claims;
        if (claims) {
            email = claims.email || claims.Email;
            const tokenUse = claims.token_use;
            logCTX(context, `[AuthDebug] Found authorizer claims with token_use: ${tokenUse}`, {
                hasEmail: !!email,
                claimKeys: Object.keys(claims)
            });

            if (email) {
                logCTX(context, `[AuthDebug] Using email from ID token claims: ${email}`);
            }
        } else {
            logCTX(context, '[AuthDebug] No authorizer claims found, trying access token method');
        }

        // Method 2: Fallback to extracting access token and calling Cognito (Access Token)
        if (!email) {
            const accessToken = extractAccessToken(event);
            if (!accessToken) {
                logCTX(context, '[AuthDebug] No usable access token extracted');
                return null;
            }

            // Verify the access token with Cognito to get user email
            const cognitoClient = new CognitoIdentityProviderClient({ region: COGNITO_REGION });
            const userResponse = await cognitoClient.send(new GetUserCommand({ AccessToken: accessToken }));
            email = userResponse.UserAttributes.find(attr => attr.Name === 'email')?.Value;

            if (!email) {
                logCTX(context, '[AuthDebug] Email attribute missing in Cognito user');
                return null;
            }

            logCTX(context, `[AuthDebug] Using email from access token: ${email}`);
        }

        logCTX(context, `[AuthDebug] Resolving business for email: ${email}`);

        const queryParams = {
            TableName: BUSINESSES_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': email.toLowerCase().trim() },
        };

        const result = await docClient.send(new QueryCommand(queryParams));
        const businesses = result.Items || [];

        if (businesses.length === 0) {
            logCTX(context, `[AuthDebug] No businesses found for email: ${email}`);
            return null;
        }

        const businessId = businesses[0].businessId;
        logCTX(context, `[AuthDebug] Using businessId: ${businessId}`);
        return businessId;
    } catch (error) {
        logCTX(context, '[AuthDebug] Error getting business ID', { error });
        if (error.name === 'ValidationException' && (error.message || '').includes('specified index')) {
            logCTX(context, '[AuthDebug] Missing email-index on businesses table');
            return MISSING_EMAIL_INDEX_SENTINEL;
        }
        return null;
    }
}

// --- Product Handlers ---

async function handleGetProducts(event) {
    const context = buildRequestContext(event);
    const businessId = await getBusinessId(event);
    if (businessId === MISSING_EMAIL_INDEX_SENTINEL) {
        return { statusCode: 500, body: JSON.stringify({ message: 'Configuration error: email-index missing on businesses table', code: 'MISSING_EMAIL_INDEX' }), headers };
    }
    if (!businessId) {
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }), headers };
    }

    try {
        const params = {
            TableName: PRODUCTS_TABLE,
            IndexName: 'BusinessIdIndex',
            KeyConditionExpression: 'businessId = :businessId',
            ExpressionAttributeValues: { ':businessId': businessId },
        };
        const { Items } = await docClient.send(new QueryCommand(params));
        logCTX(context, 'Fetched products successfully', { productCount: Items.length });
        return { statusCode: 200, body: JSON.stringify({ products: Items || [] }), headers };
    } catch (error) {
        logCTX(context, 'Error getting products', { error });
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to get products', error: error.message }), headers };
    }
}

async function handleSearchProducts(event) {
    const context = buildRequestContext(event);
    const businessId = await getBusinessId(event);
    if (businessId === MISSING_EMAIL_INDEX_SENTINEL) {
        return { statusCode: 500, body: JSON.stringify({ message: 'Configuration error: email-index missing on businesses table', code: 'MISSING_EMAIL_INDEX' }), headers };
    }
    if (!businessId) {
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }), headers };
    }

    const searchQuery = (event.queryStringParameters?.q || '').toLowerCase();
    
    try {
        const params = {
            TableName: PRODUCTS_TABLE,
            FilterExpression: 'businessId = :businessId and contains(searchableName, :searchQuery)',
            ExpressionAttributeValues: {
                ':businessId': businessId,
                ':searchQuery': searchQuery,
            },
        };
        const { Items } = await docClient.send(new ScanCommand(params));
        logCTX(context, 'Searched products successfully', { searchQuery, productCount: Items.length });
        return { statusCode: 200, body: JSON.stringify({ products: Items || [] }), headers };
    } catch (error) {
        logCTX(context, 'Error searching products', { error });
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to search products', error: error.message }), headers };
    }
}

async function handleCreateProduct(event) {
    const context = buildRequestContext(event);
    const businessId = await getBusinessId(event);
    if (businessId === MISSING_EMAIL_INDEX_SENTINEL) {
        return { statusCode: 500, body: JSON.stringify({ message: 'Configuration error: email-index missing on businesses table', code: 'MISSING_EMAIL_INDEX' }), headers };
    }
    if (!businessId) {
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }), headers };
    }

    // Fail fast if table env var missing
    if (!PRODUCTS_TABLE) {
        logCTX(context, 'Configuration error: PRODUCTS_TABLE env var missing');
        return { statusCode: 500, body: JSON.stringify({ message: 'Server configuration error', code: 'MISSING_PRODUCTS_TABLE' }), headers };
    }

    // Handle Base64 encoded request body from API Gateway
    let requestBody = event.body;
    if (event.isBase64Encoded && requestBody) {
        try {
            requestBody = Buffer.from(requestBody, 'base64').toString('utf-8');
            logCTX(context, 'Decoded Base64 request body for product creation');
        } catch (decodeError) {
            logCTX(context, 'Failed to decode Base64 body', { error: decodeError.message });
            return { statusCode: 400, body: JSON.stringify({ message: 'Invalid Base64 request body' }), headers };
        }
    }

    // Parse & validate body separately so we can distinguish 400 vs 500
    let payload;
    try {
        payload = requestBody ? JSON.parse(requestBody) : {};
    } catch (e) {
        logCTX(context, 'Invalid JSON payload for create product', { rawBody: requestBody?.substring(0, 500), error: e.message });
        return { statusCode: 400, body: JSON.stringify({ message: 'Invalid JSON body' }), headers };
    }

    try {
        logCTX(context, 'Attempting to create product with body', { body: payload });
        const { name, description, price, categoryId, imageUrl, isAvailable } = payload;

        // Basic required field validation
        const missing = [];
        if (!name) missing.push('name');
        if (!description) missing.push('description');
        if (price === undefined || price === null) missing.push('price');
        if (!categoryId) missing.push('categoryId');
        if (missing.length) {
            logCTX(context, 'Create product validation failed (missing fields)', { missing });
            return { statusCode: 400, body: JSON.stringify({ message: 'Missing required fields', missing }), headers };
        }

        // Coerce & validate price
        const numericPrice = Number(price);
        if (Number.isNaN(numericPrice) || numericPrice < 0) {
            logCTX(context, 'Create product validation failed (invalid price)', { price });
            return { statusCode: 400, body: JSON.stringify({ message: 'Invalid price' }), headers };
        }

        const productId = uuidv4();
        const searchableName = typeof name === 'string' ? name.toLowerCase() : '';

        const newItem = {
            productId,
            businessId,
            name,
            description,
            price: numericPrice,
            categoryId,
            imageUrl: imageUrl || null,
            isAvailable: isAvailable !== false,
            searchableName,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
        };

        await docClient.send(new PutCommand({ TableName: PRODUCTS_TABLE, Item: newItem }));
        logCTX(context, 'Created product successfully', { productId });
        return { statusCode: 201, body: JSON.stringify({ product: newItem }), headers };
    } catch (error) {
        // Capture full error info & echo limited context
        logCTX(context, 'Error creating product', { error: error.message, stack: error.stack?.split('\n').slice(0, 5).join('\n'), body: payload });
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to create product', error: error.message }), headers };
    }
}

async function handleGetProduct(event) {
    const context = buildRequestContext(event);
    const businessId = await getBusinessId(event);
    if (businessId === MISSING_EMAIL_INDEX_SENTINEL) {
        return { statusCode: 500, body: JSON.stringify({ message: 'Configuration error: email-index missing on businesses table', code: 'MISSING_EMAIL_INDEX' }), headers };
    }
    if (!businessId) {
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }), headers };
    }
    
    const { productId } = event.pathParameters;

    try {
        const { Item } = await docClient.send(new GetCommand({ TableName: PRODUCTS_TABLE, Key: { productId } }));
        if (!Item || Item.businessId !== businessId) {
            logCTX(context, 'Product not found or unauthorized access', { productId });
            return { statusCode: 404, body: JSON.stringify({ message: 'Product not found' }), headers };
        }
        logCTX(context, 'Fetched product successfully', { productId });
        return { statusCode: 200, body: JSON.stringify({ product: Item }), headers };
    } catch (error) {
        logCTX(context, 'Error getting product', { error });
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to get product', error: error.message }), headers };
    }
}

async function handleUpdateProduct(event) {
    const context = buildRequestContext(event);
    const businessId = await getBusinessId(event);
    if (businessId === MISSING_EMAIL_INDEX_SENTINEL) {
        return { statusCode: 500, body: JSON.stringify({ message: 'Configuration error: email-index missing on businesses table', code: 'MISSING_EMAIL_INDEX' }), headers };
    }
    if (!businessId) {
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }), headers };
    }

    const { productId } = event.pathParameters;

    // Handle Base64 encoded request body from API Gateway
    let requestBody = event.body;
    if (event.isBase64Encoded && requestBody) {
        try {
            requestBody = Buffer.from(requestBody, 'base64').toString('utf-8');
            logCTX(context, 'Decoded Base64 request body for product update');
        } catch (decodeError) {
            logCTX(context, 'Failed to decode Base64 body', { error: decodeError.message });
            return { statusCode: 400, body: JSON.stringify({ message: 'Invalid Base64 request body' }), headers };
        }
    }

    let updates;
    try {
        updates = requestBody ? JSON.parse(requestBody) : {};
    } catch (e) {
        logCTX(context, 'Invalid JSON payload for update product', { rawBody: requestBody?.substring(0, 500), error: e.message });
        return { statusCode: 400, body: JSON.stringify({ message: 'Invalid JSON body' }), headers };
    }

    // Ensure businessId is not being changed
    delete updates.businessId;
    delete updates.productId;
    
    if (updates.name) {
        updates.searchableName = updates.name.toLowerCase();
    }
    updates.updatedAt = new Date().toISOString();

    const updateExpression = 'set ' + Object.keys(updates).map(key => `#${key} = :${key}`).join(', ');
    const expressionAttributeNames = Object.keys(updates).reduce((acc, key) => ({...acc, [`#${key}`]: key}), {});
    const expressionAttributeValues = Object.keys(updates).reduce((acc, key) => ({...acc, [`:${key}`]: updates[key]}), {});

    try {
        const { Item } = await docClient.send(new GetCommand({ TableName: PRODUCTS_TABLE, Key: { productId } }));
        if (!Item || Item.businessId !== businessId) {
            logCTX(context, 'Product not found or unauthorized access for update', { productId });
            return { statusCode: 404, body: JSON.stringify({ message: 'Product not found or you do not have permission to update it.' }), headers };
        }

        const params = {
            TableName: PRODUCTS_TABLE,
            Key: { productId },
            UpdateExpression: updateExpression,
            ExpressionAttributeNames: expressionAttributeNames,
            ExpressionAttributeValues: expressionAttributeValues,
            ReturnValues: 'ALL_NEW',
        };

        const { Attributes } = await docClient.send(new UpdateCommand(params));
        logCTX(context, 'Updated product successfully', { productId });
        return { statusCode: 200, body: JSON.stringify({ product: Attributes }), headers };
    } catch (error) {
        logCTX(context, 'Error updating product', { error });
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to update product', error: error.message }), headers };
    }
}

async function handleDeleteProduct(event) {
    const context = buildRequestContext(event);
    const businessId = await getBusinessId(event);
    if (businessId === MISSING_EMAIL_INDEX_SENTINEL) {
        return { statusCode: 500, body: JSON.stringify({ message: 'Configuration error: email-index missing on businesses table', code: 'MISSING_EMAIL_INDEX' }), headers };
    }
    if (!businessId) {
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }), headers };
    }

    const { productId } = event.pathParameters;

    try {
        const { Item } = await docClient.send(new GetCommand({ TableName: PRODUCTS_TABLE, Key: { productId } }));
        if (!Item || Item.businessId !== businessId) {
            logCTX(context, 'Product not found or unauthorized access for deletion', { productId });
            return { statusCode: 404, body: JSON.stringify({ message: 'Product not found or you do not have permission to delete it.' }), headers };
        }

        await docClient.send(new DeleteCommand({ TableName: PRODUCTS_TABLE, Key: { productId } }));
        logCTX(context, 'Deleted product successfully', { productId });
        return { statusCode: 200, body: JSON.stringify({ message: 'Product deleted successfully' }), headers };
    } catch (error) {
        logCTX(context, 'Error deleting product', { error });
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to delete product', error: error.message }), headers };
    }
}

// --- Category Handlers ---

async function handleGetCategories(event) {
    const context = buildRequestContext(event);
    try {
        const { Items } = await docClient.send(new ScanCommand({ TableName: CATEGORIES_TABLE }));
        logCTX(context, 'Fetched categories successfully', { categoryCount: Items.length });
        return { statusCode: 200, body: JSON.stringify({ categories: Items || [] }), headers };
    } catch (error) {
        logCTX(context, 'Error getting categories', { error });
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to get categories', error: error.message }), headers };
    }
}

async function handleGetCategoriesByBusinessType(event) {
    const context = buildRequestContext(event);
    const { businessType } = event.pathParameters;
    try {
        const params = {
            TableName: CATEGORIES_TABLE,
            IndexName: 'BusinessTypeIndex',
            KeyConditionExpression: 'businessType = :businessType',
            ExpressionAttributeValues: { ':businessType': businessType },
        };
        const { Items } = await docClient.send(new QueryCommand(params));
        logCTX(context, 'Fetched categories by business type successfully', { businessType, categoryCount: Items.length });
        return { statusCode: 200, body: JSON.stringify({ categories: Items || [] }), headers };
    } catch (error) {
        logCTX(context, 'Error getting categories by business type', { error });
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to get categories', error: error.message }), headers };
    }
}

// --- Business Subcategories Handlers ---

async function handleGetBusinessSubcategories(event) {
    const context = buildRequestContext(event);
    try {
        const { Items } = await docClient.send(new ScanCommand({ TableName: BUSINESS_SUBCATEGORIES_TABLE }));
        logCTX(context, 'Fetched business subcategories successfully', { subcategoryCount: Items.length });
        return { statusCode: 200, body: JSON.stringify({ subcategories: Items || [] }), headers };
    } catch (error) {
        logCTX(context, 'Error getting business subcategories', { error });
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to get business subcategories', error: error.message }), headers };
    }
}

async function handleGetBusinessSubcategoriesByBusinessType(event) {
    const context = buildRequestContext(event);
    const { businessType } = event.pathParameters;
    try {
        const params = {
            TableName: BUSINESS_SUBCATEGORIES_TABLE,
            IndexName: 'BusinessTypeIndex',
            KeyConditionExpression: 'businessType = :businessType',
            ExpressionAttributeValues: { ':businessType': businessType },
        };
        const { Items } = await docClient.send(new QueryCommand(params));

        // Always include "none" as an option
        const subcategoriesWithNone = [
            {
                subcategoryId: 'none',
                businessType: businessType,
                name_en: 'None',
                name_ar: 'لا شيء',
                description_en: 'No specific subcategory',
                description_ar: 'لا توجد فئة فرعية محددة'
            },
            ...(Items || [])
        ];

        logCTX(context, 'Fetched business subcategories by business type successfully', { businessType, subcategoryCount: subcategoriesWithNone.length });
        return { statusCode: 200, body: JSON.stringify({ subcategories: subcategoriesWithNone }), headers };
    } catch (error) {
        logCTX(context, 'Error getting business subcategories by business type', { error });
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to get business subcategories', error: error.message }), headers };
    }
}


module.exports.handler = async (event) => {
    const context = buildRequestContext(event);
    logCTX(context, 'Received event in Product Management Handler', { event });

  const { httpMethod, path } = event;

  if (httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers };
  }

  if (path.startsWith('/products/search')) {
      return handleSearchProducts(event);
  }
  if (path.startsWith('/products/')) {
    if (httpMethod === 'GET') return handleGetProduct(event);
    if (httpMethod === 'PUT') return handleUpdateProduct(event);
    if (httpMethod === 'DELETE') return handleDeleteProduct(event);
  }
  if (path === '/products') {
    if (httpMethod === 'GET') return handleGetProducts(event);
    if (httpMethod === 'POST') return handleCreateProduct(event);
  }

  if (path.startsWith('/categories/business-type/')) {
      return handleGetCategoriesByBusinessType(event);
  }
  if (path === '/categories') {
      return handleGetCategories(event);
  }

    if (path.startsWith('/business-subcategories/business-type/')) {
        return handleGetBusinessSubcategoriesByBusinessType(event);
    }
    if (path === '/business-subcategories') {
        return handleGetBusinessSubcategories(event);
    }

  return {
    statusCode: 404,
    body: JSON.stringify({ message: 'Route Not Found in Product Handler' }),
    headers,
  };
};
