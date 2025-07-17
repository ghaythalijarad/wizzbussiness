const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

const dynamodb = new AWS.DynamoDB.DocumentClient({ region: 'us-east-1' });
const CATEGORIES_TABLE = 'order-receiver-categories-dev';

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
    caffe: [
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

async function populateAllCategories() {
    console.log('Populating categories for all business types...');
    
    for (const [businessType, categories] of Object.entries(BUSINESS_TYPE_CATEGORIES)) {
        console.log(`\nProcessing business type: ${businessType}`);
        
        for (const category of categories) {
            const categoryId = uuidv4();
            const timestamp = new Date().toISOString();
            
            const categoryItem = {
                categoryId,
                businessType: businessType.toLowerCase(),
                name: category.name,
                name_ar: category.name_ar,
                description: category.description,
                created_at: timestamp,
                updated_at: timestamp
            };
            
            try {
                await dynamodb.put({
                    TableName: CATEGORIES_TABLE,
                    Item: categoryItem
                }).promise();
                
                console.log(`  ✅ Created category: ${category.name} (${category.name_ar})`);
            } catch (error) {
                console.error(`  ❌ Error creating category ${category.name}:`, error);
            }
        }
    }
    
    console.log('\n🎉 Finished populating all categories!');
}

populateAllCategories().catch(console.error);
