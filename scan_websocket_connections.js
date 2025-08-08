const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

// Initialize DynamoDB client
const dynamoClient = new DynamoDBClient({
    region: 'us-east-1'
});
const docClient = DynamoDBDocumentClient.from(dynamoClient);

const WEBSOCKET_CONNECTIONS_TABLE = 'order-receiver-websocket-connections-dev';

async function scanAllConnections() {
    console.log('🔍 Scanning all WebSocket connections...\n');

    try {
        console.log(`Table: ${WEBSOCKET_CONNECTIONS_TABLE}`);

        const scanParams = {
            TableName: WEBSOCKET_CONNECTIONS_TABLE
        };

        console.log('Sending scan command...');
        const response = await docClient.send(new ScanCommand(scanParams));
        console.log('Received response:', JSON.stringify(response, null, 2));

        if (!response.Items || response.Items.length === 0) {
            console.log('✅ No WebSocket connections found in the table.');
            return;
        }

        console.log(`📋 Found ${response.Items.length} connection(s):\n`);

        response.Items.forEach((item, index) => {
            console.log(`--- Connection ${index + 1} ---`);
            console.log(`PK: ${item.PK}`);
            console.log(`SK: ${item.SK}`);
            console.log(`Connection ID: ${item.connectionId}`);
            console.log(`Business ID: ${item.businessId}`);
            console.log(`User ID: ${item.userId}`);
            console.log(`Entity Type: ${item.entityType}`);
            console.log(`Connected At: ${item.connectedAt}`);
            console.log(`Is Virtual: ${item.isVirtualConnection || false}`);
            console.log(`TTL: ${item.ttl} (${new Date(item.ttl * 1000).toISOString()})`);
            console.log('');
        });

        // Check if connections are expired
        const now = Math.floor(Date.now() / 1000);
        const expiredConnections = response.Items.filter(item => item.ttl && item.ttl < now);
        const activeConnections = response.Items.filter(item => !item.ttl || item.ttl >= now);

        console.log(`⏰ Active connections: ${activeConnections.length}`);
        console.log(`💀 Expired connections: ${expiredConnections.length}`);

        if (expiredConnections.length > 0) {
            console.log('\n🚨 Expired connections that should be cleaned up:');
            expiredConnections.forEach((item, index) => {
                console.log(`  ${index + 1}. ${item.PK} (expired ${new Date(item.ttl * 1000).toISOString()})`);
            });
        }

    } catch (error) {
        console.error('❌ Error scanning WebSocket connections:', error);
    }
}

// Run the scan
scanAllConnections();
