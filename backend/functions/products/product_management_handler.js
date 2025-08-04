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
const { getBusinessIdFromToken } = require('../auth/utils');
const { v4: uuidv4 } = require('uuid');

const PRODUCTS_TABLE = process.env.PRODUCTS_TABLE;
const CATEGORIES_TABLE = process.env.CATEGORIES_TABLE;
const DYNAMODB_REGION = process.env.DYNAMODB_REGION || 'us-east-1';

const client = new DynamoDBClient({ region: DYNAMODB_REGION });
const docClient = DynamoDBDocumentClient.from(client);

const headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
};

function getBusinessId(event) {
    try {
        const token = event.headers.Authorization || event.headers.authorization;
        if (!token) {
            console.log("Authorization token is missing");
            return null;
        }
        return getBusinessIdFromToken(token);
    } catch (error) {
        console.error("Error decoding token in getBusinessId:", error);
        return null;
    }
}


// --- Product Handlers ---

async function handleGetProducts(event) {
  const businessId = getBusinessId(event);
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
    return { statusCode: 200, body: JSON.stringify({ products: Items || [] }), headers };
  } catch (error) {
    console.error('Error getting products:', error);
    return { statusCode: 500, body: JSON.stringify({ message: 'Failed to get products', error: error.message }), headers };
  }
}

async function handleSearchProducts(event) {
    const businessId = getBusinessId(event);
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
        return { statusCode: 200, body: JSON.stringify({ products: Items || [] }), headers };
    } catch (error) {
        console.error('Error searching products:', error);
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to search products', error: error.message }), headers };
    }
}

async function handleCreateProduct(event) {
    const businessId = getBusinessId(event);
    if (!businessId) {
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }), headers };
    }

    try {
        const { name, description, price, categoryId, imageUrl, isAvailable } = JSON.parse(event.body);
        const productId = uuidv4();
        const searchableName = name.toLowerCase();

        const newItem = {
            productId,
            businessId,
            name,
            description,
            price,
            categoryId,
            imageUrl: imageUrl || null,
            isAvailable: isAvailable !== false,
            searchableName,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
        };

        await docClient.send(new PutCommand({ TableName: PRODUCTS_TABLE, Item: newItem }));
        return { statusCode: 201, body: JSON.stringify({ product: newItem }), headers };
    } catch (error) {
        console.error('Error creating product:', error);
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to create product', error: error.message }), headers };
    }
}

async function handleGetProduct(event) {
    const businessId = getBusinessId(event);
    if (!businessId) {
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }), headers };
    }
    
    const { productId } = event.pathParameters;

    try {
        const { Item } = await docClient.send(new GetCommand({ TableName: PRODUCTS_TABLE, Key: { productId } }));
        if (!Item || Item.businessId !== businessId) {
            return { statusCode: 404, body: JSON.stringify({ message: 'Product not found' }), headers };
        }
        return { statusCode: 200, body: JSON.stringify({ product: Item }), headers };
    } catch (error) {
        console.error('Error getting product:', error);
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to get product', error: error.message }), headers };
    }
}

async function handleUpdateProduct(event) {
    const businessId = getBusinessId(event);
    if (!businessId) {
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }), headers };
    }

    const { productId } = event.pathParameters;
    const updates = JSON.parse(event.body);

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
        return { statusCode: 200, body: JSON.stringify({ product: Attributes }), headers };
    } catch (error) {
        console.error('Error updating product:', error);
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to update product', error: error.message }), headers };
    }
}

async function handleDeleteProduct(event) {
    const businessId = getBusinessId(event);
    if (!businessId) {
        return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }), headers };
    }

    const { productId } = event.pathParameters;

    try {
        const { Item } = await docClient.send(new GetCommand({ TableName: PRODUCTS_TABLE, Key: { productId } }));
        if (!Item || Item.businessId !== businessId) {
            return { statusCode: 404, body: JSON.stringify({ message: 'Product not found or you do not have permission to delete it.' }), headers };
        }

        await docClient.send(new DeleteCommand({ TableName: PRODUCTS_TABLE, Key: { productId } }));
        return { statusCode: 200, body: JSON.stringify({ message: 'Product deleted successfully' }), headers };
    } catch (error) {
        console.error('Error deleting product:', error);
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to delete product', error: error.message }), headers };
    }
}

// --- Category Handlers ---

async function handleGetCategories(event) {
    try {
        const { Items } = await docClient.send(new ScanCommand({ TableName: CATEGORIES_TABLE }));
        return { statusCode: 200, body: JSON.stringify({ categories: Items || [] }), headers };
    } catch (error) {
        console.error('Error getting categories:', error);
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to get categories', error: error.message }), headers };
    }
}

async function handleGetCategoriesByBusinessType(event) {
    const { businessType } = event.pathParameters;
    try {
        const params = {
            TableName: CATEGORIES_TABLE,
            IndexName: 'BusinessTypeIndex',
            KeyConditionExpression: 'businessType = :businessType',
            ExpressionAttributeValues: { ':businessType': businessType },
        };
        const { Items } = await docClient.send(new QueryCommand(params));
        return { statusCode: 200, body: JSON.stringify({ categories: Items || [] }), headers };
    } catch (error) {
        console.error('Error getting categories by business type:', error);
        return { statusCode: 500, body: JSON.stringify({ message: 'Failed to get categories', error: error.message }), headers };
    }
}


module.exports.handler = async (event) => {
  console.log('Received event in Product Management Handler:', JSON.stringify(event, null, 2));
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

  return {
    statusCode: 404,
    body: JSON.stringify({ message: 'Route Not Found in Product Handler' }),
    headers,
  };
};
