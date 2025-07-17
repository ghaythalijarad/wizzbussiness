const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const CATEGORIES_TABLE = 'order-receiver-categories-dev';

// Updated business type categories (removed caffe, added bakery)
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

async function clearExistingCategories() {
    try {
        console.log('🗑️  Clearing existing categories...');
        
        // Scan all existing categories
        const scanResult = await dynamodb.scan({
            TableName: CATEGORIES_TABLE
        }).promise();
        
        if (scanResult.Items.length === 0) {
            console.log('✅ No existing categories to clear.');
            return;
        }
        
        // Delete each category
        for (const item of scanResult.Items) {
            await dynamodb.delete({
                TableName: CATEGORIES_TABLE,
                Key: { categoryId: item.categoryId }
            }).promise();
            console.log(`   Deleted: ${item.name} (${item.businessType})`);
        }
        
        console.log(`✅ Cleared ${scanResult.Items.length} existing categories.`);
    } catch (error) {
        console.error('❌ Error clearing categories:', error);
        throw error;
    }
}

async function populateCategories() {
    try {
        console.log('🏗️  Populating categories for all business types...');
        
        let totalCreated = 0;
        
        for (const [businessType, categories] of Object.entries(BUSINESS_TYPE_CATEGORIES)) {
            console.log(`\n📝 Creating categories for: ${businessType.toUpperCase()}`);
            
            for (const category of categories) {
                const categoryId = uuidv4();
                const timestamp = new Date().toISOString();
                
                const categoryItem = {
                    categoryId,
                    businessType: businessType.toLowerCase(),
                    name: category.name,
                    name_ar: category.name_ar,
                    description: category.description,
                    isActive: true,
                    created_at: timestamp,
                    updated_at: timestamp
                };
                
                await dynamodb.put({
                    TableName: CATEGORIES_TABLE,
                    Item: categoryItem
                }).promise();
                
                console.log(`   ✅ ${category.name} (${category.name_ar})`);
                totalCreated++;
            }
        }
        
        console.log(`\n🎉 Successfully created ${totalCreated} categories for ${Object.keys(BUSINESS_TYPE_CATEGORIES).length} business types!`);
        
        // List the business types created
        console.log('\n📋 Business types with categories:');
        Object.keys(BUSINESS_TYPE_CATEGORIES).forEach(type => {
            console.log(`   • ${type} (${BUSINESS_TYPE_CATEGORIES[type].length} categories)`);
        });
        
    } catch (error) {
        console.error('❌ Error populating categories:', error);
        throw error;
    }
}

async function main() {
    try {
        console.log('🚀 Starting category population process...');
        
        // Clear existing categories first
        await clearExistingCategories();
        
        // Wait a moment
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Populate new categories
        await populateCategories();
        
        console.log('\n✅ Category population completed successfully!');
        
    } catch (error) {
        console.error('\n❌ Failed to populate categories:', error);
        process.exit(1);
    }
}

main();
