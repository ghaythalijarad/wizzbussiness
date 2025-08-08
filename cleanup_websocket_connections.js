const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

const dynamoClient = new DynamoDBClient({ region: 'us-east-1' });
const docClient = DynamoDBDocumentClient.from(dynamoClient);

const WEBSOCKET_CONNECTIONS_TABLE = 'order-receiver-websocket-connections-dev';

async function cleanupStaleConnections() {
    console.log('🧹 Cleaning up stale WebSocket connections...');
    console.log(`Table: ${WEBSOCKET_CONNECTIONS_TABLE}`);

    try {
        // First, scan all connections
        const scanResponse = await docClient.send(new ScanCommand({
            TableName: WEBSOCKET_CONNECTIONS_TABLE
        }));

        if (!scanResponse.Items || scanResponse.Items.length === 0) {
            console.log('✅ No connections found to clean up.');
            return;
        }

        console.log(`Found ${scanResponse.Items.length} connection(s) to clean up:\n`);

        // Delete each connection
        for (const item of scanResponse.Items) {
            console.log(`🗑️  Deleting connection: ${item.PK}`);

            await docClient.send(new DeleteCommand({
                TableName: WEBSOCKET_CONNECTIONS_TABLE,
                Key: {
                    PK: item.PK,
                    SK: item.SK
                }
            }));

            console.log(`✅ Deleted: ${item.PK}`);
        }

        console.log(`\n🎉 Successfully cleaned up ${scanResponse.Items.length} connection(s)!`);

    } catch (error) {
        console.error('❌ Error cleaning up connections:', error);
    }
}

// Run cleanup
cleanupStaleConnections();
