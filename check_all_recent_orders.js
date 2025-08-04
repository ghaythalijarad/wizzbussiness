const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

const ORDERS_TABLE = 'order-receiver-orders-dev';

async function checkAllRecentOrders() {
    console.log('🔍 Checking ALL Recent Orders in DynamoDB');
    console.log('='.repeat(60));

    try {
        // Scan for all orders in the last 7 days
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        const cutoffTime = sevenDaysAgo.toISOString();

        console.log(`📅 Looking for orders since: ${cutoffTime}`);
        console.log();

        // First, let's scan the entire table with a limit to see structure
        const scanParams = {
            TableName: ORDERS_TABLE,
            Limit: 10
        };

        const result = await dynamodb.scan(scanParams).promise();

        if (!result.Items || result.Items.length === 0) {
            console.log('📭 No orders found in the table at all');
            return;
        }

        console.log(`📦 Found ${result.Items.length} orders (showing first 10):`);
        console.log('='.repeat(60));

        result.Items.forEach((order, index) => {
            console.log(`\n📋 Order ${index + 1}:`);
            console.log(`   Order ID: ${order.orderId || order.id || 'N/A'}`);
            console.log(`   Business ID: ${order.businessId || order.merchant_id || order.merchantId || 'N/A'}`);
            console.log(`   Customer: ${order.customerName || order.customer_name || order.customerEmail || 'N/A'}`);
            console.log(`   Status: ${order.status || 'N/A'}`);
            console.log(`   Total: $${order.totalAmount || order.total_amount || order.total || 'N/A'}`);
            console.log(`   Created: ${order.createdAt || order.created_at || order.timestamp || 'N/A'}`);
            console.log(`   Updated: ${order.updatedAt || order.updated_at || 'N/A'}`);

            // Show delivery info if present
            if (order.deliveryAddress || order.delivery_address) {
                const address = order.deliveryAddress || order.delivery_address;
                console.log(`   Address: ${typeof address === 'string' ? address : JSON.stringify(address)}`);
            }

            // Show items if present
            if (order.items && Array.isArray(order.items)) {
                console.log(`   Items (${order.items.length}):`);
                order.items.slice(0, 2).forEach(item => {
                    const name = item.name || item.dishName || item.productName || 'Unknown';
                    const qty = item.quantity || 1;
                    const price = item.price || 0;
                    console.log(`     • ${name} x${qty} ($${price})`);
                });
                if (order.items.length > 2) {
                    console.log(`     ... and ${order.items.length - 2} more items`);
                }
            }

            // Check if this is a recent order
            const createdAt = order.createdAt || order.created_at || order.timestamp;
            if (createdAt) {
                const orderDate = new Date(createdAt);
                const now = new Date();
                const hoursDiff = (now - orderDate) / (1000 * 60 * 60);

                if (hoursDiff < 24) {
                    console.log(`   🆕 NEW! (${hoursDiff.toFixed(1)} hours ago)`);
                } else if (hoursDiff < 168) { // 7 days
                    console.log(`   📅 Recent (${Math.floor(hoursDiff / 24)} days ago)`);
                }
            }

            // Highlight pending orders
            if (order.status === 'pending' || order.status === 'new') {
                console.log(`   ⏰ ${order.status.toUpperCase()} - Needs attention!`);
            }
        });

        // Get total count
        console.log('\n📊 Getting total order count...');
        const countParams = {
            TableName: ORDERS_TABLE,
            Select: 'COUNT'
        };

        const countResult = await dynamodb.scan(countParams).promise();
        console.log(`📈 Total orders in table: ${countResult.Count}`);

        // Show business breakdown
        console.log('\n🏢 Orders by Business ID:');
        const businessCounts = {};
        result.Items.forEach(order => {
            const businessId = order.businessId || order.merchant_id || order.merchantId || 'unknown';
            businessCounts[businessId] = (businessCounts[businessId] || 0) + 1;
        });

        Object.entries(businessCounts).forEach(([businessId, count]) => {
            console.log(`   ${businessId}: ${count} orders`);
        });

    } catch (error) {
        console.error('❌ Error checking orders:', error.message);
        if (error.code === 'ResourceNotFoundException') {
            console.error('📋 The orders table does not exist or you don\'t have access to it');
        }
    }
}

// Run the check
checkAllRecentOrders();
