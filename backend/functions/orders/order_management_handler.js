const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
const { createResponse } = require('../auth/utils');

// Environment variables
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
    store: [
        { name: 'Electronics', name_ar: 'الإلكترونيات', description: 'Electronic devices and gadgets' },
        { name: 'Clothing', name_ar: 'الملابس', description: 'Apparel and clothing items' },
        { name: 'Home & Garden', name_ar: 'المنزل والحديقة', description: 'Home improvement and garden supplies' },
        { name: 'Health & Beauty', name_ar: 'الصحة والجمال', description: 'Personal care and beauty products' },
        { name: 'Sports & Outdoors', name_ar: 'الرياضة والأنشطة الخارجية', description: 'Sports equipment and outdoor gear' }
    ],
    pharmacy: [
        { name: 'Prescription Medicines', name_ar: 'الأدوية بوصفة طبية', description: 'Prescription medications' },
        { name: 'Over-the-Counter', name_ar: 'الأدوية بدون وصفة', description: 'Non-prescription medications' },
        { name: 'Personal Care', name_ar: 'العناية الشخصية', description: 'Personal hygiene and care products' },
        { name: 'Vitamins & Supplements', name_ar: 'الفيتامينات والمكملات', description: 'Health supplements and vitamins' },
        { name: 'Medical Devices', name_ar: 'الأجهزة الطبية', description: 'Medical equipment and devices' }
    ]
};

exports.handler = async (event) => {
    console.log('Order Management Handler - Event:', JSON.stringify(event, null, 2));

    // Instantiate AWS clients for this invocation
    const cognito = new AWS.CognitoIdentityServiceProvider({ region: process.env.AWS_REGION || 'us-east-1' });
    const dynamodb = new AWS.DynamoDB.DocumentClient({ region: process.env.AWS_REGION || 'us-east-1' });

    const { httpMethod, path, pathParameters, body, headers } = event;

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
        if (httpMethod === 'GET' && path === '/products') {
            return await handleGetProducts(dynamodb, userInfo);
        } else if (httpMethod === 'POST' && path === '/products') {
            return await handleCreateProduct(dynamodb, userInfo, JSON.parse(body || '{}'));
        } else if (httpMethod === 'GET' && pathParameters?.productId) {
            return await handleGetProduct(dynamodb, userInfo, pathParameters.productId);
        } else if (httpMethod === 'PUT' && pathParameters?.productId) {
            return await handleUpdateProduct(dynamodb, userInfo, pathParameters.productId, JSON.parse(body || '{}'));
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
        const userResponse = await cognito.getUser({ AccessToken: accessToken }).promise();
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
    try {
        const params = {
            TableName: process.env.BUSINESSES_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: {
                ':email': email
            }
        };

        const result = await dynamodb.query(params).promise();
        return result.Items?.[0] || null;
    } catch (error) {
        console.error('Error getting business info:', error);
        return null;
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
            categoryId,
            businessType,
            name: category.name,
            name_ar: category.name_ar,
            description: category.description,
            isActive: true,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        };

        try {
            await dynamodb.put({
                TableName: CATEGORIES_TABLE,
                Item: categoryItem,
                ConditionExpression: 'attribute_not_exists(categoryId)'
            }).promise();
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

        // First, try to get existing categories
        const params = {
            TableName: CATEGORIES_TABLE,
            IndexName: 'business-type-index',
            KeyConditionExpression: 'businessType = :businessType',
            ExpressionAttributeValues: {
                ':businessType': businessType.toLowerCase()
            }
        };

        const result = await dynamodb.query(params).promise();

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

        return await handleGetCategoriesByBusinessType(dynamodb, businessInfo.business_type);
    } catch (error) {
        console.error('Error getting categories:', error);
        return createResponse(500, { success: false, message: 'Failed to get categories' });
    }
}

// Get all products for the authenticated user's business
async function handleGetProducts(dynamodb, userInfo) {
    try {
        const businessInfo = await getBusinessInfoForUser(dynamodb, userInfo.email);
        if (!businessInfo) {
            return createResponse(404, { success: false, message: 'Business not found for user' });
        }

        const params = {
            TableName: PRODUCTS_TABLE,
            IndexName: 'business-index',
            KeyConditionExpression: 'businessId = :businessId',
            ExpressionAttributeValues: {
                ':businessId': businessInfo.businessId
            }
        };

        const result = await dynamodb.query(params).promise();

        return createResponse(200, {
            success: true,
            products: result.Items,
            count: result.Items.length
        });
    } catch (error) {
        console.error('Error getting products:', error);
        return createResponse(500, { success: false, message: 'Failed to get products' });
    }
}

// Get a specific product
async function handleGetProduct(dynamodb, userInfo, productId) {
    try {
        const params = {
            TableName: PRODUCTS_TABLE,
            Key: { productId }
        };

        const result = await dynamodb.get(params).promise();

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
        const categoryResult = await dynamodb.get(categoryParams).promise();
        
        if (!categoryResult.Item) {
            return createResponse(400, { success: false, message: 'Category not found' });
        }

        if (categoryResult.Item.businessType !== businessInfo.business_type) {
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
            imageUrl: imageUrl || '',
            isAvailable,
            preparationTime: preparationTime || 0,
            ingredients: ingredients || [],
            allergens: allergens || [],
            created_at: timestamp,
            updated_at: timestamp,
            created_by: userInfo.userId
        };

        await dynamodb.put({
            TableName: PRODUCTS_TABLE,
            Item: product
        }).promise();

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
            updateExpression += ', categoryId = :categoryId';
            expressionAttributeValues[':categoryId'] = categoryId;
        }
        if (imageUrl !== undefined) {
            updateExpression += ', imageUrl = :imageUrl';
            expressionAttributeValues[':imageUrl'] = imageUrl;
        }
        if (isAvailable !== undefined) {
            updateExpression += ', isAvailable = :isAvailable';
            expressionAttributeValues[':isAvailable'] = isAvailable;
        }
        if (preparationTime !== undefined) {
            updateExpression += ', preparationTime = :preparationTime';
            expressionAttributeValues[':preparationTime'] = preparationTime;
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
            Key: { productId },
            UpdateExpression: updateExpression,
            ExpressionAttributeValues: expressionAttributeValues,
            ReturnValues: 'ALL_NEW'
        };

        // Handle reserved keyword 'name'
        if (name !== undefined) {
            updateParams.ExpressionAttributeNames = { '#name': 'name' };
        }

        const result = await dynamodb.update(updateParams).promise();

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

// Delete a product
async function handleDeleteProduct(dynamodb, userInfo, productId) {
    try {
        // First, verify the product exists and belongs to the user's business
        const existingProduct = await handleGetProduct(dynamodb, userInfo, productId);
        if (existingProduct.statusCode !== 200) {
            return existingProduct;
        }

        await dynamodb.delete({
            TableName: PRODUCTS_TABLE,
            Key: { productId }
        }).promise();

        return createResponse(200, {
            success: true,
            message: 'Product deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting product:', error);
        return createResponse(500, { success: false, message: 'Failed to delete product' });
    }
}
