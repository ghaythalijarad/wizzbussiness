const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

const dynamoClient = new DynamoDBClient({ region: 'us-east-1' });
const docClient = DynamoDBDocumentClient.from(dynamoClient);

const WEBSOCKET_CONNECTIONS_TABLE = 'order-receiver-websocket-connections-dev';

async function cleanupVirtualConnections() {
    console.log('🧹 Cleaning up virtual WebSocket connections...');
    console.log(`Table: ${WEBSOCKET_CONNECTIONS_TABLE}`);

    try {
        // Scan for virtual connections
        const scanResponse = await docClient.send(new ScanCommand({
            TableName: WEBSOCKET_CONNECTIONS_TABLE,
            FilterExpression: 'isVirtualConnection = :isVirtual OR begins_with(connectionId, :virtualPrefix)',
            ExpressionAttributeValues: {
                ':isVirtual': true,
                ':virtualPrefix': 'VIRTUAL#'
            }
        }));

        if (!scanResponse.Items || scanResponse.Items.length === 0) {
            console.log('✅ No virtual connections found to clean up.');
            return;
        }

        console.log(`Found ${scanResponse.Items.length} virtual connection(s) to clean up:\n`);

        // Delete each virtual connection
        for (const item of scanResponse.Items) {
            console.log(`🗑️  Deleting virtual connection: ${item.PK}`);
            console.log(`   Connection ID: ${item.connectionId}`);
            console.log(`   Business ID: ${item.businessId}`);
            console.log(`   User ID: ${item.userId}`);

            await docClient.send(new DeleteCommand({
                TableName: WEBSOCKET_CONNECTIONS_TABLE,
                Key: {
                    PK: item.PK,
                    SK: item.SK
                }
            }));

            console.log(`✅ Deleted virtual connection: ${item.PK}`);
        }

        console.log(`\n🎉 Successfully cleaned up ${scanResponse.Items.length} virtual connection(s)!`);
        console.log(`\n📋 SUMMARY:`);
        console.log(`- Virtual connections removed: ${scanResponse.Items.length}`);
        console.log(`- Real WebSocket connections remain untouched`);
        console.log(`- Business status now relies solely on acceptingOrders field`);

    } catch (error) {
        console.error('❌ Error cleaning up virtual connections:', error);
    }
}

// Run the cleanup
cleanupVirtualConnections();
