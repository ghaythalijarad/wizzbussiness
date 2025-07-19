const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

// Configure AWS
AWS.config.update({ 
    region: 'us-east-1',
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
});

const dynamodb = new AWS.DynamoDB.DocumentClient();
const DISCOUNTS_TABLE = 'order-receiver-discounts-dev';

async function debugDiscountTable() {
    console.log('🔍 Debugging Discount Table Structure...\n');
    
    try {
        // 1. First, let's try to describe the table structure
        const dynamodbService = new AWS.DynamoDB();
        const tableInfo = await dynamodbService.describeTable({
            TableName: DISCOUNTS_TABLE
        }).promise();
        
        console.log('📊 Table Schema:');
        console.log('- Table Name:', tableInfo.Table.TableName);
        console.log('- Table Status:', tableInfo.Table.TableStatus);
        
        console.log('\n🔑 Key Schema:');
        tableInfo.Table.KeySchema.forEach(key => {
            console.log(`- ${key.AttributeName} (${key.KeyType})`);
        });
        
        console.log('\n📋 Attribute Definitions:');
        tableInfo.Table.AttributeDefinitions.forEach(attr => {
            console.log(`- ${attr.AttributeName}: ${attr.AttributeType}`);
        });
        
        if (tableInfo.Table.GlobalSecondaryIndexes) {
            console.log('\n🗂️ Global Secondary Indexes:');
            tableInfo.Table.GlobalSecondaryIndexes.forEach(gsi => {
                console.log(`- ${gsi.IndexName}:`);
                gsi.KeySchema.forEach(key => {
                    console.log(`  - ${key.AttributeName} (${key.KeyType})`);
                });
            });
        }
        
        // 2. Try to scan existing discount items to see the structure
        console.log('\n📋 Existing Discounts (sample):');
        const scanResult = await dynamodb.scan({
            TableName: DISCOUNTS_TABLE,
            Limit: 3
        }).promise();
        
        if (scanResult.Items && scanResult.Items.length > 0) {
            console.log('Found', scanResult.Items.length, 'existing discount(s):');
            scanResult.Items.forEach((item, index) => {
                console.log(`\n🎯 Discount ${index + 1}:`);
                console.log('Keys and structure:');
                Object.keys(item).forEach(key => {
                    console.log(`  - ${key}: ${typeof item[key]} ${Array.isArray(item[key]) ? '(array)' : ''}`);
                });
            });
        } else {
            console.log('No existing discounts found');
        }
        
        // 3. Test creating a discount with the current structure
        console.log('\n🧪 Testing Discount Creation...');
        
        const testBusinessId = 'test-business-123';
        const testDiscountId = uuidv4();
        
        const testDiscount = {
            businessId: testBusinessId,
            discountId: testDiscountId,
            id: testDiscountId,
            title: 'Test Discount',
            description: 'Test Description',
            type: 'percentage',
            value: 10.0,
            applicability: 'allItems',
            applicable_item_ids: [],
            applicable_category_ids: [],
            minimum_order_amount: 0,
            valid_from: new Date().toISOString(),
            valid_to: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
            usage_limit: null,
            usage_count: 0,
            status: 'active',
            conditional_rule: null,
            conditional_parameters: {},
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        };
        
        console.log('📝 Creating test discount...');
        await dynamodb.put({
            TableName: DISCOUNTS_TABLE,
            Item: testDiscount
        }).promise();
        console.log('✅ Discount created successfully!');
        
        // 4. Try to retrieve the discount
        console.log('📖 Retrieving the discount...');
        const getResult = await dynamodb.get({
            TableName: DISCOUNTS_TABLE,
            Key: {
                discountId: testDiscountId
            }
        }).promise();
        
        if (getResult.Item) {
            console.log('✅ Discount retrieved successfully!');
            console.log('Retrieved discount ID:', getResult.Item.id);
        } else {
            console.log('❌ Could not retrieve discount with key structure:');
            console.log('  business_id:', testBusinessId);
            console.log('  discountId:', testDiscountId);
            
            // Try alternative key structures
            console.log('\n🔄 Trying alternative key structure (discount_id)...');
            const altGetResult = await dynamodb.get({
                TableName: DISCOUNTS_TABLE,
                Key: {
                    business_id: testBusinessId,
                    discount_id: testDiscountId
                }
            }).promise();
            
            if (altGetResult.Item) {
                console.log('✅ Found with discount_id key!');
            } else {
                console.log('❌ Still not found with discount_id key');
            }
        }
        
        // 5. Clean up test discount
        console.log('\n🧹 Cleaning up test discount...');
        await dynamodb.delete({
            TableName: DISCOUNTS_TABLE,
            Key: {
                discountId: testDiscountId
            }
        }).promise();
        console.log('✅ Test discount cleaned up');
        
    } catch (error) {
        console.error('❌ Error debugging discount table:', error);
        
        if (error.code === 'ResourceNotFoundException') {
            console.log('\n📝 The table does not exist. It might need to be created.');
        } else if (error.code === 'ValidationException') {
            console.log('\n⚠️ Validation error - likely key structure mismatch');
            console.log('Error message:', error.message);
        }
    }
}

debugDiscountTable();
