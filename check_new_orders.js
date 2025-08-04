const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Table names
const BUSINESSES_TABLE = 'order-receiver-businesses-dev';
const ORDERS_TABLE = 'order-receiver-orders-dev';

// Known business email (from the context)
const BUSINESS_EMAIL = 'zikbiot@yahoo.com';

async function checkNewOrders() {
    console.log('🔍 Checking for New Orders');
    console.log('='.repeat(50));

    try {
        // Step 1: Get business information
        console.log('1️⃣ Finding business account...');

        const businessParams = {
            TableName: BUSINESSES_TABLE,
            IndexName: 'email-index',
            KeyConditionExpression: 'email = :email',
            ExpressionAttributeValues: {
                ':email': BUSINESS_EMAIL
            }
        };

        const businessResult = await dynamodb.query(businessParams).promise();

        if (!businessResult.Items || businessResult.Items.length === 0) {
            console.log('❌ No business found with email:', BUSINESS_EMAIL);
            console.log('📋 Available businesses:');

            // Scan to show available businesses
            const scanResult = await dynamodb.scan({
                TableName: BUSINESSES_TABLE,
                ProjectionExpression: 'businessId, business_name, email, #status',
                ExpressionAttributeNames: { '#status': 'status' },
                Limit: 10
            }).promise();

            scanResult.Items.forEach((business, index) => {
                console.log(`   ${index + 1}. ${business.business_name || 'N/A'} (${business.email})`);
                console.log(`      ID: ${business.businessId}`);
                console.log(`      Status: ${business.status || 'N/A'}`);
                console.log();
            });
            return;
        }

        const business = businessResult.Items[0];
        console.log('✅ Business found:');
        console.log(`   Name: ${business.business_name}`);
        console.log(`   ID: ${business.businessId}`);
        console.log(`   Email: ${business.email}`);
        console.log(`   Status: ${business.status || 'N/A'}`);
        console.log();

        // Step 2: Check for orders
        console.log('2️⃣ Checking for orders...');

        // Try multiple query approaches since table structure may vary
        let orders = [];

        // Approach 1: Query by businessId using GSI (if it exists)
        try {
            console.log('   Trying to query orders by businessId...');
            const ordersParams = {
                TableName: ORDERS_TABLE,
                IndexName: 'BusinessIdIndex',
                KeyConditionExpression: 'businessId = :businessId',
                ExpressionAttributeValues: {
                    ':businessId': business.businessId
                }
            };

            const ordersResult = await dynamodb.query(ordersParams).promise();
            orders = ordersResult.Items || [];
            console.log(`   ✅ Found ${orders.length} orders via BusinessIdIndex`);

        } catch (error) {
            console.log(`   ❌ BusinessIdIndex query failed: ${error.message}`);

            // Approach 2: Scan with filter (fallback)
            try {
                console.log('   Trying scan with filter...');
                const scanParams = {
                    TableName: ORDERS_TABLE,
                    FilterExpression: 'businessId = :businessId OR merchant_id = :businessId',
                    ExpressionAttributeValues: {
                        ':businessId': business.businessId
                    }
                };

                const scanResult = await dynamodb.scan(scanParams).promise();
                orders = scanResult.Items || [];
                console.log(`   ✅ Found ${orders.length} orders via scan`);

            } catch (scanError) {
                console.log(`   ❌ Scan also failed: ${scanError.message}`);

                // Approach 3: Check table structure
                console.log('   📊 Checking orders table structure...');
                try {
                    const sampleParams = {
                        TableName: ORDERS_TABLE,
                        Limit: 3
                    };

                    const sampleResult = await dynamodb.scan(sampleParams).promise();
                    console.log(`   📦 Sample orders (${sampleResult.Items.length}):`);

                    sampleResult.Items.forEach((order, index) => {
                        console.log(`      Order ${index + 1}:`);
                        console.log(`        ID: ${order.orderId || order.id || 'N/A'}`);
                        console.log(`        Business ID: ${order.businessId || order.merchant_id || 'N/A'}`);
                        console.log(`        Status: ${order.status || 'N/A'}`);
                        console.log(`        Created: ${order.createdAt || order.created_at || 'N/A'}`);
                        console.log();
                    });

                } catch (structureError) {
                    console.log(`   ❌ Unable to check table structure: ${structureError.message}`);
                }
            }
        }

        // Step 3: Display orders
        if (orders.length === 0) {
            console.log('📭 No orders found for this business');
            console.log();
            console.log('💡 This could mean:');
            console.log('   • No orders have been placed yet');
            console.log('   • Orders are stored with different field names');
            console.log('   • Orders table structure is different than expected');
            return;
        }

        console.log(`\n3️⃣ Found ${orders.length} orders:`);
        console.log('='.repeat(50));

        // Sort orders by creation date (newest first)
        orders.sort((a, b) => {
            const dateA = new Date(a.createdAt || a.created_at || 0);
            const dateB = new Date(b.createdAt || b.created_at || 0);
            return dateB - dateA;
        });

        // Show recent orders (last 10)
        const recentOrders = orders.slice(0, 10);

        recentOrders.forEach((order, index) => {
            const orderId = order.orderId || order.id || 'N/A';
            const status = order.status || 'unknown';
            const customerName = order.customerName || order.customer_name || 'N/A';
            const totalAmount = order.totalAmount || order.total_amount || 0;
            const createdAt = order.createdAt || order.created_at || 'N/A';
            const items = order.items || [];

            console.log(`📋 Order ${index + 1}:`);
            console.log(`   ID: ${orderId}`);
            console.log(`   Status: ${status.toUpperCase()}`);
            console.log(`   Customer: ${customerName}`);
            console.log(`   Total: $${totalAmount}`);
            console.log(`   Created: ${createdAt}`);

            if (items.length > 0) {
                console.log(`   Items (${items.length}):`);
                items.slice(0, 3).forEach(item => {
                    const itemName = item.name || item.dishName || item.productName || 'Unknown Item';
                    const quantity = item.quantity || 1;
                    const price = item.price || 0;
                    console.log(`     • ${itemName} x${quantity} ($${price})`);
                });
                if (items.length > 3) {
                    console.log(`     ... and ${items.length - 3} more items`);
                }
            }

            // Highlight new orders (less than 24 hours old)
            if (createdAt !== 'N/A') {
                const orderDate = new Date(createdAt);
                const now = new Date();
                const hoursDiff = (now - orderDate) / (1000 * 60 * 60);

                if (hoursDiff < 24) {
                    console.log(`   🆕 NEW! (${hoursDiff.toFixed(1)} hours ago)`);
                }

                if (status === 'pending') {
                    console.log(`   ⏰ PENDING - Requires attention!`);
                }
            }

            console.log();
        });

        // Summary
        const statusCounts = {};
        orders.forEach(order => {
            const status = order.status || 'unknown';
            statusCounts[status] = (statusCounts[status] || 0) + 1;
        });

        console.log('📊 Order Summary:');
        Object.entries(statusCounts).forEach(([status, count]) => {
            console.log(`   ${status.toUpperCase()}: ${count}`);
        });

        // Check for pending orders that need attention
        const pendingOrders = orders.filter(order => order.status === 'pending');
        if (pendingOrders.length > 0) {
            console.log(`\n⚠️  ${pendingOrders.length} PENDING ORDERS NEED ATTENTION!`);
        }

    } catch (error) {
        console.error('❌ Error checking orders:', error.message);
        console.error('Full error:', error);
    }
}

// Add helper function to list all tables (for debugging)
async function listTables() {
    try {
        const dynamodbService = new AWS.DynamoDB();
        const result = await dynamodbService.listTables().promise();

        console.log('📋 Available DynamoDB tables:');
        const orderTables = result.TableNames.filter(name =>
            name.toLowerCase().includes('order') ||
            name.toLowerCase().includes('business')
        );

        orderTables.forEach(table => {
            console.log(`   - ${table}`);
        });
        console.log();

    } catch (error) {
        console.log('❌ Could not list tables:', error.message);
    }
}

// Run the check
async function main() {
    console.log('🚀 Starting Order Check...\n');

    // First show available tables for reference
    await listTables();

    // Then check for orders
    await checkNewOrders();
}

main();
