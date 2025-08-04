const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand, QueryCommand, ScanCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');
const { CognitoIdentityServiceProvider } = require('@aws-sdk/client-cognito-identity-provider');
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
    const cognito = new CognitoIdentityServiceProvider({ region: process.env.COGNITO_REGION || 'us-east-1' });
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
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return createResponse(401, { success: false, message: 'Missing or invalid authorization header' });
        }

        const accessToken = authHeader.replace('Bearer ', '');

        // Verify the access token and get user info
        const userInfo = await getUserInfoFromToken(cognito, accessToken);
        if (!userInfo) {
            return createResponse(401, { success: false, message: 'Invalid access token' });
        }

        // Route the request based on HTTP method and path
        if (httpMethod === 'POST' && path === '/orders') {
            return await handleCreateOrder(dynamodb, userInfo, JSON.parse(requestBody || '{}'));
        } else if (httpMethod === 'GET' && path === '/products') {
            return await handleGetProducts(dynamodb, userInfo);
        } else if (httpMethod === 'GET' && path === '/products/search') {
            const query = event.queryStringParameters?.q || '';
            return await handleSearchProducts(dynamodb, userInfo, query);
        } else if (httpMethod === 'POST' && path === '/products') {
            return await handleCreateProduct(dynamodb, userInfo, JSON.parse(requestBody || '{}'));
        } else if (httpMethod === 'GET' && pathParameters?.productId) {
            return await handleGetProduct(dynamodb, userInfo, pathParameters.productId);
        } else if (httpMethod === 'PUT' && pathParameters?.productId) {
            return await handleUpdateProduct(dynamodb, userInfo, pathParameters.productId, JSON.parse(requestBody || '{}'));
        } else if (httpMethod === 'DELETE' && pathParameters?.productId) {
            return await handleDeleteProduct(dynamodb, userInfo, pathParameters.productId);
        } else if (httpMethod === 'GET' && path === '/categories') {
            return await handleGetCategories(dynamodb, userInfo);
        } else {
            return createResponse(404, { success: false, message: 'Endpoint not found' });
        }
    } catch (error) {
        console.error('Error in order management handler:', error);
        return createResponse(500, { success: false, message: 'Internal server error' });
    }
};

// Helper function to get user info from access token
async function getUserInfoFromToken(cognito, accessToken) {
    try {
        const userResponse = await cognito.getUser({ AccessToken: accessToken });
        const email = userResponse.UserAttributes.find(attr => attr.Name === 'email')?.Value;
        const userId = userResponse.UserAttributes.find(attr => attr.Name === 'sub')?.Value;
        
        return {
            userId,
            email,
            cognitoUserId: userId
        };
    } catch (error) {
        console.error('Error getting user info from token:', error);
        return null;
    }
}

// Helper function to get business info for user
async function getBusinessInfoForUser(dynamodb, email) {
    console.log(`Attempting to get business info for email: ${email}`); // Enhanced logging
    try {
        // First, try to query using the GSI for efficiency
        const queryParams = {
            TableName: process.env.BUSINESSES_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: { ':email': email }
        };
        const result = await dynamodb.send(new QueryCommand(queryParams));
        
        if (result.Items && result.Items.length > 0) {
            console.log(`Successfully found business info for email ${email} via GSI.`); // Enhanced logging
            return result.Items[0];
        }
        
        // If no items found via query, it means no business for that email.
        console.warn(`Business information not found for email via GSI: ${email}. This may not be an error if a scan fallback is expected.`); // Enhanced logging
        throw new Error(`Business information not found for email: ${email}`);

    } catch (error) {
        // If the query failed because the index doesn't exist, fall back to scan.
        if (error.code === 'ValidationException' || error.code === 'ResourceNotFoundException') {
            console.log('Falling back to scan because GSI query failed. Error:', error.message);
            const scanParams = {
                TableName: process.env.BUSINESSES_TABLE,
                FilterExpression: 'email = :email',
                ExpressionAttributeValues: { ':email': email }
            };
            const scanResult = await dynamodb.send(new ScanCommand(scanParams));
            const businessInfo = scanResult.Items?.[0] || null;

            if (!businessInfo) {
                console.error(`Business information not found for email (after scan fallback): ${email}`); // Enhanced logging
                throw new Error(`Business information not found for email (after scan fallback): ${email}`);
            }
            console.log(`Successfully found business info for email ${email} via scan fallback.`); // Enhanced logging
            return businessInfo;
        }
        
        console.error('Error getting business info:', error);
        throw error; // Re-throw other errors
    }
}

// Initialize categories for a business type if they don't exist
async function initializeCategoriesForBusinessType(dynamodb, businessType) {
    if (!BUSINESS_TYPE_CATEGORIES[businessType]) {
        throw new Error(`Unsupported business type: ${businessType}`);
    }

    const categories = BUSINESS_TYPE_CATEGORIES[businessType];
    const categoryItems = [];

    for (const category of categories) {
        const categoryId = uuidv4();
        const categoryItem = {
            categoryId: categoryId,
            businessType: businessType,
            name: category.name,
            name_ar: category.name_ar,
            description: category.description,
            is_active: true,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        };

        try {
            await dynamodb.send(new PutCommand({
                TableName: CATEGORIES_TABLE,
                Item: categoryItem,
                ConditionExpression: 'attribute_not_exists(categoryId)'
            }));
            categoryItems.push(categoryItem);
        } catch (error) {
            if (error.code !== 'ConditionalCheckFailedException') {
                console.error('Error creating category:', error);
            }
        }
    }

    return categoryItems;
}

// Get categories by business type
async function handleGetCategoriesByBusinessType(dynamodb, businessType) {
    try {
        if (!businessType) {
            return createResponse(400, { success: false, message: 'Business type is required' });
        }

        // Retrieve existing categories filtered by businessType
        const params = {
            TableName: CATEGORIES_TABLE,
            FilterExpression: 'businessType = :businessType',
            ExpressionAttributeValues: {
                ':businessType': businessType.toLowerCase()
            }
        };

        // Scan the table since BusinessTypeIndex may not exist
        const result = await dynamodb.send(new ScanCommand(params));

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
async function handleGetCategories(dynamodb, userInfo) {
    try {
        const businessInfo = await getBusinessInfoForUser(dynamodb, userInfo.email);
        if (!businessInfo) {
            return createResponse(404, { success: false, message: 'Business not found for user' });
        }

        return await handleGetCategoriesByBusinessType(dynamodb, businessInfo.businessType);
    } catch (error) {
        console.error('Error getting categories:', error);
        return createResponse(500, { success: false, message: 'Failed to get categories' });
    }
}

// Get all products for the authenticated user's business
async function handleGetProducts(dynamodb, userInfo) {
    console.log('handleGetProducts - UserInfo:', JSON.stringify(userInfo, null, 2)); // Enhanced logging
    try {
        const businessInfo = await getBusinessInfoForUser(dynamodb, userInfo.email);
        console.log('handleGetProducts - BusinessInfo:', JSON.stringify(businessInfo, null, 2)); // Enhanced logging

        if (!businessInfo || !businessInfo.businessId) {
            console.error('Failed to retrieve valid business info or businessId.');
            return createResponse(404, { success: false, message: 'Business not found for the user' });
        }

        const params = {
            TableName: PRODUCTS_TABLE,
            IndexName: 'BusinessIdIndex',
            KeyConditionExpression: 'businessId = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessInfo.businessId
            }
        };

        console.log('Querying products with params:', JSON.stringify(params, null, 2)); // Enhanced logging
        const result = await dynamodb.send(new QueryCommand(params));
        console.log('Product query result:', JSON.stringify(result, null, 2)); // Enhanced logging

        // Transform products to ensure consistent field naming for frontend
        const transformedProducts = result.Items.map(product => ({
            ...product,
            // Ensure imageUrl field exists for frontend compatibility
            imageUrl: product.image_url || product.imageUrl,
            isAvailable: product.is_available !== undefined ? product.is_available : product.isAvailable
        }));

        return createResponse(200, { success: true, products: transformedProducts });
    } catch (error) {
        console.error('Error in handleGetProducts:', error);
        // Return a more specific error message if business info is the issue
        if (error.message.includes('Business information not found')) {
            return createResponse(404, { success: false, message: 'Business not found for the user.' });
        }
        return createResponse(500, { success: false, message: 'Failed to get products' });
    }
}

// Get a specific product
async function handleGetProduct(dynamodb, userInfo, productId) {
    try {
        const params = {
            TableName: PRODUCTS_TABLE,
            Key: { productId: productId }
        };

        const result = await dynamodb.send(new GetCommand(params));

        if (!result.Item) {
            return createResponse(404, { success: false, message: 'Product not found' });
        }

        // Verify the product belongs to the user's business
        const businessInfo = await getBusinessInfoForUser(dynamodb, userInfo.email);
        if (result.Item.businessId !== businessInfo?.businessId) {
            return createResponse(403, { success: false, message: 'Access denied to this product' });
        }

        return createResponse(200, {
            success: true,
            product: result.Item
        });
    } catch (error) {
        console.error('Error getting product:', error);
        return createResponse(500, { success: false, message: 'Failed to get product' });
    }
}

// Create a new product
async function handleCreateProduct(dynamodb, userInfo, productData) {
    try {
        const businessInfo = await getBusinessInfoForUser(dynamodb, userInfo.email);
        if (!businessInfo) {
            return createResponse(404, { success: false, message: 'Business not found for user' });
        }

        const {
            name,
            name_ar,
            description,
            description_ar,
            price,
            categoryId,
            imageUrl,
            isAvailable = true,
            preparationTime,
            ingredients,
            allergens
        } = productData;

        // Validate required fields
        if (!name || !price || !categoryId) {
            return createResponse(400, { 
                success: false, 
                message: 'Name, price, and category are required' 
            });
        }

        // Verify the category exists and belongs to the correct business type
        const categoryParams = {
            TableName: CATEGORIES_TABLE,
            Key: { categoryId }
        };
        const categoryResult = await dynamodb.send(new GetCommand(categoryParams));
        
        if (!categoryResult.Item) {
            return createResponse(400, { success: false, message: 'Category not found' });
        }

        if (categoryResult.Item.businessType !== businessInfo.businessType) {
            return createResponse(400, { 
                success: false, 
                message: 'Category does not match business type' 
            });
        }

        const productId = uuidv4();
        const timestamp = new Date().toISOString();

        const product = {
            productId,
            businessId: businessInfo.businessId,
            categoryId,
            name,
            name_ar: name_ar || '',
            description: description || '',
            description_ar: description_ar || '',
            price: parseFloat(price),
            image_url: imageUrl || '',
            is_available: isAvailable,
            preparation_time: preparationTime || 0,
            ingredients: ingredients || [],
            allergens: allergens || [],
            created_at: timestamp,
            updated_at: timestamp,
            created_by: userInfo.userId
        };

        await dynamodb.send(new PutCommand({
            TableName: PRODUCTS_TABLE,
            Item: product
        }));

        return createResponse(201, {
            success: true,
            message: 'Product created successfully',
            product
        });
    } catch (error) {
        console.error('Error creating product:', error);
        return createResponse(500, { success: false, message: 'Failed to create product' });
    }
}

// Update an existing product
async function handleUpdateProduct(dynamodb, userInfo, productId, productData) {
    try {
        // First, verify the product exists and belongs to the user's business
        const existingProduct = await handleGetProduct(dynamodb, userInfo, productId);
        if (existingProduct.statusCode !== 200) {
            return existingProduct;
        }

        const {
            name,
            name_ar,
            description,
            description_ar,
            price,
            categoryId,
            imageUrl,
            isAvailable,
            preparationTime,
            ingredients,
            allergens
        } = productData;

        // Build update expression
        let updateExpression = 'SET updated_at = :timestamp';
        const expressionAttributeValues = {
            ':timestamp': new Date().toISOString()
        };

        if (name !== undefined) {
            updateExpression += ', #name = :name';
            expressionAttributeValues[':name'] = name;
        }
        if (name_ar !== undefined) {
            updateExpression += ', name_ar = :name_ar';
            expressionAttributeValues[':name_ar'] = name_ar;
        }
        if (description !== undefined) {
            updateExpression += ', description = :description';
            expressionAttributeValues[':description'] = description;
        }
        if (description_ar !== undefined) {
            updateExpression += ', description_ar = :description_ar';
            expressionAttributeValues[':description_ar'] = description_ar;
        }
        if (price !== undefined) {
            updateExpression += ', price = :price';
            expressionAttributeValues[':price'] = parseFloat(price);
        }
        if (categoryId !== undefined) {
            updateExpression += ', category_id = :category_id';
            expressionAttributeValues[':category_id'] = categoryId;
        }
        if (imageUrl !== undefined) {
            updateExpression += ', image_url = :image_url';
            expressionAttributeValues[':image_url'] = imageUrl;
        }
        if (isAvailable !== undefined) {
            updateExpression += ', is_available = :is_available';
            expressionAttributeValues[':is_available'] = isAvailable;
        }
        if (preparationTime !== undefined) {
            updateExpression += ', preparation_time = :preparation_time';
            expressionAttributeValues[':preparation_time'] = preparationTime;
        }
        if (ingredients !== undefined) {
            updateExpression += ', ingredients = :ingredients';
            expressionAttributeValues[':ingredients'] = ingredients;
        }
        if (allergens !== undefined) {
            updateExpression += ', allergens = :allergens';
            expressionAttributeValues[':allergens'] = allergens;
        }

        const updateParams = {
            TableName: PRODUCTS_TABLE,
            Key: { productId: productId },
            UpdateExpression: updateExpression,
            ExpressionAttributeValues: expressionAttributeValues,
            ReturnValues: 'ALL_NEW'
        };

        // Handle reserved keyword 'name'
        if (name !== undefined) {
            updateParams.ExpressionAttributeNames = { '#name': 'name' };
        }

        const result = await dynamodb.send(new UpdateCommand(updateParams));

        return createResponse(200, {
            success: true,
            message: 'Product updated successfully',
            product: result.Attributes
        });
    } catch (error) {
        console.error('Error updating product:', error);
        return createResponse(500, { success: false, message: 'Failed to update product' });
    }
}

// Search products by name, description, or ingredients
async function handleSearchProducts(dynamodb, userInfo, query) {
    try {
        const businessInfo = await getBusinessInfoForUser(dynamodb, userInfo.email);
        if (!businessInfo) {
            return createResponse(404, { success: false, message: 'Business not found for user' });
        }

        const searchTerm = query.trim().toLowerCase();
        // Use scan since BusinessIdIndex does not exist
        const params = {
            TableName: PRODUCTS_TABLE,
            FilterExpression: 'business_id = :business_id',
            ExpressionAttributeValues: {
                ':business_id': businessInfo.business_id
            }
        };
        const result = await dynamodb.send(new ScanCommand(params));

        // Filter items in code
        const filteredProducts = result.Items.filter(product => {
            const nameMatch = product.name?.toLowerCase().includes(searchTerm);
            const descriptionMatch = product.description?.toLowerCase().includes(searchTerm);
            let ingredientsMatch = false;
            if (product.ingredients) {
                ingredientsMatch = product.ingredients.some(i => i.toLowerCase().includes(searchTerm));
            }
            return nameMatch || descriptionMatch || ingredientsMatch;
        });

        return createResponse(200, {
            success: true,
            products: filteredProducts,
            count: filteredProducts.length
        });
    } catch (error) {
        console.error('Error searching products:', error);
        return createResponse(500, { success: false, message: 'Failed to search products' });
    }
}

// Delete a product
async function handleDeleteProduct(dynamodb, userInfo, productId) {
    try {
        // First, verify the product exists and belongs to the user's business
        const existingProduct = await handleGetProduct(dynamodb, userInfo, productId);
        if (existingProduct.statusCode !== 200) {
            return existingProduct;
        }

        await dynamodb.send(new DeleteCommand({
            TableName: PRODUCTS_TABLE,
            Key: { productId: productId }
        }));

        return createResponse(200, {
            success: true,
            message: 'Product deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting product:', error);
        return createResponse(500, { success: false, message: 'Failed to delete product' });
    }
}

// Create a new order
async function handleCreateOrder(dynamodb, userInfo, orderData) {
    try {
        const businessInfo = await getBusinessInfoForUser(dynamodb, userInfo.email);
        if (!businessInfo) {
            return createResponse(404, { success: false, message: 'Business not found for user' });
        }

        const { items, totalAmount, customerName, customerPhone, deliveryAddress, notes } = orderData;

        if (!items || !totalAmount || !customerName) {
            return createResponse(400, { success: false, message: 'Missing required order fields' });
        }

        const orderId = uuidv4();
        const timestamp = new Date().toISOString();

        const order = {
            orderId,
            businessId: businessInfo.businessId,
            customerId: userInfo.userId, // Assuming the user placing the order is the customer
            customerName,
            customerPhone,
            deliveryAddress,
            items,
            totalAmount: parseFloat(totalAmount),
            status: 'pending',
            notes: notes || '',
            createdAt: timestamp,
            updatedAt: timestamp,
        };

        await dynamodb.send(new PutCommand({
            TableName: ORDERS_TABLE,
            Item: order
        }));

        return createResponse(201, {
            success: true,
            message: 'Order created successfully',
            order
        });
    } catch (error) {
        console.error('Error creating order:', error);
        return createResponse(500, { success: false, message: 'Failed to create order' });
    }
}
