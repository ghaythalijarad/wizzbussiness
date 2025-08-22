const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand, QueryCommand, ScanCommand, DeleteCommand, BatchWriteItemCommand } = require('@aws-sdk/lib-dynamodb');
const { CognitoIdentityProviderClient, GetUserCommand } = require('@aws-sdk/client-cognito-identity-provider');
const { v4: uuidv4 } = require('uuid');
const { createResponse } = require('../auth/utils');

// Environment variables
const ORDERS_TABLE = process.env.ORDERS_TABLE;
const PRODUCTS_TABLE = process.env.PRODUCTS_TABLE;
const CATEGORIES_TABLE = process.env.CATEGORIES_TABLE;
const USER_POOL_ID = process.env.COGNITO_USER_POOL_ID;

// Predefined categories for each business type
const BUSINESS_TYPE_CATEGORIES = {
    restaurant: [
        { name: 'Appetizers', name_ar: 'المقبلات', description: 'Starters and appetizers' },
        { name: 'Main Courses', name_ar: 'الأطباق الرئيسية', description: 'Main dishes and entrees' },
        { name: 'Desserts', name_ar: 'الحلويات', description: 'Sweet desserts and treats' },
        { name: 'Beverages', name_ar: 'المشروبات', description: 'Drinks and beverages' },
        { name: 'Sides', name_ar: 'الأطباق الجانبية', description: 'Side dishes' }
    ],
    cloudkitchen: [
        { name: 'Appetizers', name_ar: 'المقبلات', description: 'Starters and appetizers' },
        { name: 'Main Courses', name_ar: 'الأطباق الرئيسية', description: 'Main dishes and entrees' },
        { name: 'Desserts', name_ar: 'الحلويات', description: 'Sweet desserts and treats' },
        { name: 'Beverages', name_ar: 'المشروبات', description: 'Drinks and beverages' },
        { name: 'Sides', name_ar: 'الأطباق الجانبية', description: 'Side dishes' }
    ],
    cafe: [
        { name: 'Coffee', name_ar: 'القهوة', description: 'Coffee drinks and varieties' },
        { name: 'Tea', name_ar: 'الشاي', description: 'Tea varieties and blends' },
        { name: 'Pastries', name_ar: 'المعجنات', description: 'Baked goods and pastries' },
        { name: 'Sandwiches', name_ar: 'الساندويتشات', description: 'Light meals and sandwiches' },
        { name: 'Cold Drinks', name_ar: 'المشروبات الباردة', description: 'Cold beverages and smoothies' }
    ],
    bakery: [
        { name: 'Bread', name_ar: 'الخبز', description: 'Fresh baked bread varieties' },
        { name: 'Cakes', name_ar: 'الكعك', description: 'Cakes and celebration desserts' },
        { name: 'Pastries', name_ar: 'المعجنات', description: 'Sweet and savory pastries' },
        { name: 'Cookies', name_ar: 'البسكويت', description: 'Cookies and biscuits' },
        { name: 'Muffins & Cupcakes', name_ar: 'المافن والكب كيك', description: 'Individual baked treats' }
    ],
    store: [
        { name: 'Meat & Poultry', name_ar: 'اللحوم والدواجن', description: 'Fresh meat and poultry products' },
        { name: 'Vegetables & Fruits', name_ar: 'الخضروات والفواكه', description: 'Fresh vegetables and fruits' },
        { name: 'Dairy & Milk', name_ar: 'الألبان والحليب', description: 'Dairy products and milk' },
        { name: 'Dry Foods & Grains', name_ar: 'الأطعمة الجافة والحبوب', description: 'Dry foods, grains, and pantry staples' },
        { name: 'Beverages', name_ar: 'المشروبات', description: 'Soft drinks, juices, and beverages' },
        { name: 'Snacks & Sweets', name_ar: 'الوجبات الخفيفة والحلويات', description: 'Snacks, candies, and sweet treats' },
        { name: 'Household Items', name_ar: 'المواد المنزلية', description: 'Cleaning supplies and household essentials' }
    ],
    pharmacy: [
        { name: 'Prescription Medicines', name_ar: 'الأدوية بوصفة طبية', description: 'Prescription medications' },
        { name: 'Over-the-Counter', name_ar: 'الأدوية بدون وصفة', description: 'Non-prescription medications' },
        { name: 'Personal Care', name_ar: 'العناية الشخصية', description: 'Personal hygiene and care products' },
        { name: 'Vitamins & Supplements', name_ar: 'الفيتامينات والمكملات', description: 'Health supplements and vitamins' },
        { name: 'Medical Devices', name_ar: 'الأجهزة الطبية', description: 'Medical equipment and devices' }
    ],
    herbalspices: [
        { name: 'Fresh Herbs', name_ar: 'الأعشاب الطازجة', description: 'Fresh culinary and medicinal herbs' },
        { name: 'Dried Spices', name_ar: 'التوابل المجففة', description: 'Ground and whole dried spices' },
        { name: 'Spice Blends', name_ar: 'خلطات التوابل', description: 'Mixed spice blends and seasonings' },
        { name: 'Medicinal Herbs', name_ar: 'الأعشاب الطبية', description: 'Traditional medicinal herbs and remedies' },
        { name: 'Essential Oils', name_ar: 'الزيوت العطرية', description: 'Natural essential oils and aromatherapy products' },
        { name: 'Tea & Infusions', name_ar: 'الشاي والمنقوعات', description: 'Herbal teas and health infusions' }
    ],
    cosmetics: [
        { name: 'Face Makeup', name_ar: 'مكياج الوجه', description: 'Foundation, concealer, powder, and face makeup' },
        { name: 'Eye Makeup', name_ar: 'مكياج العيون', description: 'Eyeshadow, mascara, eyeliner, and eye products' },
        { name: 'Lip Products', name_ar: 'منتجات الشفاه', description: 'Lipstick, lip gloss, and lip care products' },
        { name: 'Skincare', name_ar: 'العناية بالبشرة', description: 'Cleansers, moisturizers, and skincare treatments' },
        { name: 'Nail Products', name_ar: 'منتجات الأظافر', description: 'Nail polish, nail care, and nail art supplies' },
        { name: 'Hair Care', name_ar: 'العناية بالشعر', description: 'Shampoo, conditioner, and hair styling products' },
        { name: 'Fragrance', name_ar: 'العطور', description: 'Perfumes, body sprays, and fragrance products' },
        { name: 'Tools & Accessories', name_ar: 'الأدوات والإكسسوارات', description: 'Makeup brushes, sponges, and beauty tools' }
    ],
    betshop: [
        { name: 'Sports Betting', name_ar: 'الرهان الرياضي', description: 'Football, basketball, and other sports betting' },
        { name: 'Live Betting', name_ar: 'الرهان المباشر', description: 'In-play and live match betting' },
        { name: 'Casino Games', name_ar: 'ألعاب الكازينو', description: 'Slot machines, poker, and casino games' },
        { name: 'Virtual Sports', name_ar: 'الرياضات الافتراضية', description: 'Virtual football, racing, and simulated sports' },
        { name: 'Lottery & Scratch Cards', name_ar: 'اليانصيب وبطاقات الخدش', description: 'Lottery tickets and instant win games' }
    ]
};

exports.handler = async (event) => {
    console.log('Order Management Handler - Event:', JSON.stringify(event, null, 2));

    // Instantiate AWS clients for this invocation
    const cognito = new CognitoIdentityProviderClient({ region: process.env.COGNITO_REGION || 'us-east-1' });
    const dynamoDbClient = new DynamoDBClient({ region: process.env.DYNAMODB_REGION || 'us-east-1' });
    const dynamodb = DynamoDBDocumentClient.from(dynamoDbClient);

    const { httpMethod, path, pathParameters, headers } = event;
    
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

    try {
        // Handle public endpoints that don't require authentication
        if (httpMethod === 'GET' && path.includes('/categories/business-type/')) {
            const businessType = pathParameters?.businessType;
            return await handleGetCategoriesByBusinessType(dynamodb, businessType);
        }

        // Extract access token from Authorization header for authenticated endpoints
        const authHeader = headers?.Authorization || headers?.authorization;
        let accessToken;

        if (authHeader) {
            if (authHeader.startsWith('Bearer ')) {
                accessToken = authHeader.replace('Bearer ', '');
            } else {
                // Direct token without Bearer prefix (for AWS API Gateway Cognito Authorizer)
                accessToken = authHeader.trim();
            }
        }

        if (!accessToken) {
            return createResponse(401, { success: false, message: 'Missing or invalid authorization header' });
        }

        // Verify the access token and get user info
        const userInfoResult = await getUserInfoFromToken(cognito, accessToken);
        if (!userInfoResult) {
            return createResponse(401, { success: false, message: 'Invalid access token' });
        }

        // Extract email and sub from the Cognito response
        const emailAttribute = userInfoResult.UserAttributes.find(attr => attr.Name === 'email');
        if (!emailAttribute || !emailAttribute.Value) {
            return createResponse(403, { success: false, message: 'User email not found in token.' });
        }

        const userInfo = {
            email: emailAttribute.Value,
            sub: userInfoResult.Username // 'sub' is typically the user's unique identifier
        };

        // Route the request based on HTTP method and path
        if (httpMethod === 'POST' && path === '/orders') {
            return await handleCreateOrder(dynamodb, userInfo, JSON.parse(requestBody || '{}'));
        } else if (httpMethod === 'GET' && path === '/orders') {
            return await handleGetOrders(dynamodb, userInfo);
        } else if (httpMethod === 'GET' && pathParameters?.orderId) {
            return await handleGetOrder(dynamodb, userInfo, pathParameters.orderId);
        } else if (httpMethod === 'PUT' && pathParameters?.orderId) {
            return await handleUpdateOrder(dynamodb, userInfo, pathParameters.orderId, JSON.parse(requestBody || '{}'));
        } else if (httpMethod === 'DELETE' && pathParameters?.orderId) {
            return await handleDeleteOrder(dynamodb, userInfo, pathParameters.orderId);
        } else if (httpMethod === 'GET' && path === '/categories') {
            return await handleGetAllCategories(dynamodb, userInfo);
        } else {
            return createResponse(404, { success: false, message: 'Not Found' });
        }
    } catch (error) {
        console.error('❌ Error processing request:', error);
        return createResponse(500, { success: false, message: 'Internal Server Error' });
    }
};

// Get categories by business type
async function handleGetCategoriesByBusinessType(dynamodb, businessType) {
    try {
        if (!businessType) {
            return createResponse(400, { success: false, message: 'Business type is required' });
        }

        // Retrieve existing categories filtered by businessType using the GSI
        const params = {
            TableName: CATEGORIES_TABLE,
            IndexName: 'BusinessTypeIndex',
            KeyConditionExpression: 'businessType = :businessType',
            ExpressionAttributeValues: {
                ':businessType': businessType.toLowerCase()
            }
        };

        // Query the table using the index
        const result = await dynamodb.send(new QueryCommand(params));

        // If no categories exist, initialize them
        if (result.Items.length === 0) {
            const newCategories = await initializeCategoriesForBusinessType(dynamodb, businessType.toLowerCase());
            return createResponse(200, {
                success: true,
                categories: newCategories
            });
        }

        return createResponse(200, {
            success: true,
            categories: result.Items
        });
    } catch (error) {
        console.error('Error getting categories by business type:', error);
        return createResponse(500, { success: false, message: 'Failed to get categories' });
    }
}

// Get all categories (for the authenticated user's business type)
async function handleGetAllCategories(dynamodb, userInfo) {
    try {
        const businessInfo = await getBusinessInfoForUser(dynamodb, userInfo.email);
        if (!businessInfo || !businessInfo.businessId) {
            return createResponse(404, { success: false, message: 'Business not found for the user' });
        }

        // Query categories by business type using the GSI
        const params = {
            TableName: CATEGORIES_TABLE,
            IndexName: 'BusinessTypeIndex',
            KeyConditionExpression: 'businessType = :businessType',
            ExpressionAttributeValues: {
                ':businessType': businessInfo.businessType.toLowerCase()
            }
        };

        const result = await dynamodb.send(new QueryCommand(params));

        return createResponse(200, {
            success: true,
            categories: result.Items
        });
    } catch (error) {
        console.error('Error getting all categories:', error);
        return createResponse(500, { success: false, message: 'Failed to get categories' });
    }
}

// Create a new order
async function handleCreateOrder(dynamodb, userInfo, orderData) {
    try {
        const businessInfo = await getBusinessInfoForUser(dynamodb, userInfo.email);
        if (!businessInfo || !businessInfo.businessId) {
            return createResponse(404, { success: false, message: 'Business not found for the user' });
        }

        // Validate and prepare order data
        const { productId, quantity, specialRequests } = orderData;
        if (!productId || quantity == null) {
            return createResponse(400, { success: false, message: 'Product ID and quantity are required' });
        }

        // Create a new order item
        const newOrder = {
            id: uuidv4(),
            businessId: businessInfo.businessId,
            userId: userInfo.sub,
            productId,
            quantity,
            specialRequests: specialRequests || '',
            status: 'pending',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        // Save the new order to DynamoDB
        const params = {
            TableName: ORDERS_TABLE,
            Item: newOrder
        };
        await dynamodb.send(new PutCommand(params));

        return createResponse(201, { success: true, order: newOrder });
    } catch (error) {
        console.error('Error creating order:', error);
        return createResponse(500, { success: false, message: 'Failed to create order' });
    }
}

// Get all orders for the authenticated user
async function handleGetOrders(dynamodb, userInfo) {
    try {
        // Query orders by user ID
        const params = {
            TableName: ORDERS_TABLE,
            IndexName: 'UserIdIndex',
            KeyConditionExpression: 'userId = :userId',
            ExpressionAttributeValues: {
                ':userId': userInfo.sub
            }
        };
        const result = await dynamodb.send(new QueryCommand(params));

        return createResponse(200, { success: true, orders: result.Items });
    } catch (error) {
        console.error('Error getting orders:', error);
        return createResponse(500, { success: false, message: 'Failed to get orders' });
    }
}

// Get a single order by ID
async function handleGetOrder(dynamodb, userInfo, orderId) {
    try {
        // Retrieve the order by ID
        const params = {
            TableName: ORDERS_TABLE,
            Key: { id: orderId }
        };
        const result = await dynamodb.send(new GetCommand(params));

        if (!result.Item) {
            return createResponse(404, { success: false, message: 'Order not found' });
        }

        return createResponse(200, { success: true, order: result.Item });
    } catch (error) {
        console.error('Error getting order:', error);
        return createResponse(500, { success: false, message: 'Failed to get order' });
    }
}

// Update an order by ID
async function handleUpdateOrder(dynamodb, userInfo, orderId, updateData) {
    try {
        // Prepare update expression and attribute values
        const updateExpression = 'SET ' +
            Object.keys(updateData).map((key, index) => `${key} = :val${index}`).join(', ');
        const expressionAttributeValues = Object.fromEntries(
            Object.values(updateData).map((value, index) => [`:val${index}`, value])
        );

        // Update the order in DynamoDB
        const params = {
            TableName: ORDERS_TABLE,
            Key: { id: orderId },
            UpdateExpression: updateExpression,
            ExpressionAttributeValues: expressionAttributeValues,
            ReturnValues: 'ALL_NEW'
        };
        const result = await dynamodb.send(new UpdateCommand(params));

        return createResponse(200, { success: true, order: result.Attributes });
    } catch (error) {
        console.error('Error updating order:', error);
        return createResponse(500, { success: false, message: 'Failed to update order' });
    }
}

// Delete an order by ID
async function handleDeleteOrder(dynamodb, userInfo, orderId) {
    try {
        // Delete the order from DynamoDB
        const params = {
            TableName: ORDERS_TABLE,
            Key: { id: orderId }
        };
        await dynamodb.send(new DeleteCommand(params));

        return createResponse(204, { success: true, message: 'Order deleted successfully' });
    } catch (error) {
        console.error('Error deleting order:', error);
        return createResponse(500, { success: false, message: 'Failed to delete order' });
    }
}

// Helper function to get user info from access token
async function getUserInfoFromToken(cognito, accessToken) {
    try {
        const params = {
            AccessToken: accessToken
        };
        const result = await cognito.send(new GetUserCommand(params));
        return result;
    } catch (error) {
        console.error('Error getting user info from token:', error);
        return null;
    }
}

// Helper function to get business info for a user
async function getBusinessInfoForUser(dynamodb, email) {
    const params = {
        TableName: process.env.BUSINESSES_TABLE,
        IndexName: 'OwnerEmailIndex',
        KeyConditionExpression: 'ownerEmail = :email',
        ExpressionAttributeValues: {
            ':email': email
        }
    };

    try {
        const result = await dynamodb.send(new QueryCommand(params));
        if (result.Items && result.Items.length > 0) {
            console.log('Business info found for user:', email);
            return result.Items[0];
        }
        console.log('No business info found for user:', email);
        return null;
    } catch (error) {
        console.error('Error getting business info for user:', error);
        throw new Error('Failed to retrieve business information.');
    }
}

// Initialize categories for a new business type
async function initializeCategoriesForBusinessType(dynamodb, businessType) {
    try {
        const categories = BUSINESS_TYPE_CATEGORIES[businessType];
        if (!categories) {
            throw new Error('Invalid business type');
        }

        const writeRequests = categories.map(category => ({
            PutRequest: {
                Item: {
                    id: uuidv4(),
                    businessType: businessType.toLowerCase(),
                    name: category.name,
                    name_ar: category.name_ar,
                    description: category.description,
                    createdAt: new Date().toISOString()
                }
            }
        }));

        const params = {
            RequestItems: {
                [CATEGORIES_TABLE]: writeRequests
            }
        };

        await dynamodb.send(new BatchWriteItemCommand(params));

        // Return the newly created category items
        return writeRequests.map(req => req.PutRequest.Item);
    } catch (error) {
        console.error('Error initializing categories:', error);
        throw new Error('Failed to initialize categories');
    }
}

module.exports = {
    handler,
    createResponse,
    getBusinessInfoForUser,
    handleCreateOrder,
    handleGetOrders,
    handleGetOrder,
    handleUpdateOrder,
    handleDeleteOrder
};
