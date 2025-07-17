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
