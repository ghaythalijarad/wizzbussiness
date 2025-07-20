const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();
const sts = new AWS.STS();

const TABLE_NAME = 'order-receiver-products-dev';

// Business ID from the DynamoDB scan result you provided
const BUSINESS_ID = '723a276a-ad62-482c-898c-076d1f8d5c0e';

// Sample products for a restaurant (زيت و زعتر)
const sampleProducts = [
    {
        productId: '1a2b3c4d-5e6f-7890-abcd-ef1234567890',
        businessId: BUSINESS_ID,
        name: 'زعتر وزيت',
        nameAr: 'زعتر وزيت',
        description: 'Traditional za\'atar with olive oil',
        descriptionAr: 'زعتر تقليدي مع زيت الزيتون',
        price: 12.50,
        categoryId: 'c0f0cff6-f046-4c5b-a058-bf73f082b2c6',
        isAvailable: true,
        imageUrl: '',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    },
    {
        productId: '2b3c4d5e-6f78-9012-bcde-f23456789012',
        businessId: BUSINESS_ID,
        name: 'فتة حمص',
        nameAr: 'فتة حمص',
        description: 'Traditional hummus with bread and meat',
        descriptionAr: 'حمص تقليدي مع الخبز واللحم',
        price: 18.00,
        categoryId: '285fee8f-9f99-48bf-8559-1d0235686f9f', // Main Courses category
        isAvailable: true,
        imageUrl: '',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    },
    {
        productId: '3c4d5e6f-7890-1234-cdef-345678901234',
        businessId: BUSINESS_ID,
        name: 'لبنة وزيت',
        nameAr: 'لبنة وزيت',
        description: 'Fresh labneh with olive oil',
        descriptionAr: 'لبنة طازجة مع زيت الزيتون',
        price: 8.00,
        categoryId: 'c0f0cff6-f046-4c5b-a058-bf73f082b2c6', // Appetizers category
        isAvailable: true,
        imageUrl: '',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    },
    {
        productId: '4d5e6f78-9012-3456-def0-456789012345',
        businessId: BUSINESS_ID,
        name: 'شاي عراقي',
        nameAr: 'شاي عراقي',
        description: 'Traditional Iraqi tea',
        descriptionAr: 'شاي عراقي تقليدي',
        price: 3.00,
        categoryId: 'e6a8bb9b-57e4-4ff4-8876-bbf6e37de315', // Beverages category
        isAvailable: true,
        imageUrl: '',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    },
    {
        productId: '5e6f7890-1234-5678-ef01-567890123456',
        businessId: BUSINESS_ID,
        name: 'بقلاوة',
        nameAr: 'بقلاوة',
        description: 'Traditional baklava dessert',
        descriptionAr: 'حلوى البقلاوة التقليدية',
        price: 15.00,
        categoryId: '20c86694-514a-4683-a8b5-def9726889d1', // Desserts category
        isAvailable: true,
        imageUrl: '',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
    }
];

async function populateProductsTable() {
    try {
        console.log('🍽️  Populating products table...');
        console.log(`Table: ${TABLE_NAME}`);
        console.log(`Business ID: ${BUSINESS_ID}`);
        
        // Test AWS credentials
        console.log('🔑 Testing AWS credentials...');
        const sts = new AWS.STS();
        const identity = await sts.getCallerIdentity().promise();
        console.log('✅ AWS credentials are valid:', identity.Account);
        
        for (const product of sampleProducts) {
            console.log(`\n➕ Adding product: ${product.name}`);
            
            const params = {
                TableName: TABLE_NAME,
                Item: product
            };
            
            await dynamodb.put(params).promise();
            console.log(`✅ Successfully added: ${product.name}`);
        }
        
        console.log('\n🎉 All products added successfully!');
        console.log(`Total products added: ${sampleProducts.length}`);
        
    } catch (error) {
        console.error('❌ Error populating products table:', error);
        if (error.code) {
            console.error(`Error Code: ${error.code}`);
        }
    }
}

// Run the function
populateProductsTable();
