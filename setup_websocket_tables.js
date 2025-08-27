#!/usr/bin/env node

/**
 * WebSocket Tables Setup Script
 * Creates the new WebSocket tables with proper schema if they don't exist
 */

const { 
    DynamoDBClient, 
    CreateTableCommand, 
    DescribeTableCommand, 
    waitUntilTableExists 
} = require('@aws-sdk/client-dynamodb');

const AWS_PROFILE = 'wizz-merchants-dev';
const AWS_REGION = 'us-east-1';

// Configure DynamoDB client
const dynamodb = new DynamoDBClient({
    region: AWS_REGION,
    credentials: {
        profile: AWS_PROFILE
    }
});

// Table configurations
const CONNECTIONS_TABLE = 'WizzUser_websocket_connections_dev';
const SUBSCRIPTIONS_TABLE = 'WizzUser_websocket_subscriptions_dev';

async function tableExists(tableName) {
    try {
        const result = await dynamodb.send(new DescribeTableCommand({
            TableName: tableName
        }));
        return result.Table.TableStatus === 'ACTIVE';
    } catch (error) {
        if (error.name === 'ResourceNotFoundException') {
            return false;
        }
        throw error;
    }
}

async function createConnectionsTable() {
    console.log(`🔧 Creating table: ${CONNECTIONS_TABLE}`);
    
    const params = {
        TableName: CONNECTIONS_TABLE,
        KeySchema: [
            {
                AttributeName: 'PK',
                KeyType: 'HASH'
            },
            {
                AttributeName: 'SK', 
                KeyType: 'RANGE'
            }
        ],
        AttributeDefinitions: [
            {
                AttributeName: 'PK',
                AttributeType: 'S'
            },
            {
                AttributeName: 'SK',
                AttributeType: 'S'
            },
            {
                AttributeName: 'GSI1PK',
                AttributeType: 'S'
            },
            {
                AttributeName: 'GSI1SK',
                AttributeType: 'S'
            }
        ],
        GlobalSecondaryIndexes: [
            {
                IndexName: 'GSI1',
                KeySchema: [
                    {
                        AttributeName: 'GSI1PK',
                        KeyType: 'HASH'
                    },
                    {
                        AttributeName: 'GSI1SK',
                        KeyType: 'RANGE'
                    }
                ],
                Projection: {
                    ProjectionType: 'ALL'
                },
                ProvisionedThroughput: {
                    ReadCapacityUnits: 5,
                    WriteCapacityUnits: 5
                }
            }
        ],
        ProvisionedThroughput: {
            ReadCapacityUnits: 5,
            WriteCapacityUnits: 5
        },
        TimeToLiveSpecification: {
            AttributeName: 'ttl',
            Enabled: true
        }
    };

    try {
        await dynamodb.send(new CreateTableCommand(params));
        console.log(`⏳ Waiting for table ${CONNECTIONS_TABLE} to become active...`);
        await waitUntilTableExists({ client: dynamodb, maxWaitTime: 300 }, { TableName: CONNECTIONS_TABLE });
        console.log(`✅ Table ${CONNECTIONS_TABLE} created successfully`);
    } catch (error) {
        console.error(`❌ Failed to create table ${CONNECTIONS_TABLE}:`, error.message);
        throw error;
    }
}

async function createSubscriptionsTable() {
    console.log(`🔧 Creating table: ${SUBSCRIPTIONS_TABLE}`);
    
    const params = {
        TableName: SUBSCRIPTIONS_TABLE,
        KeySchema: [
            {
                AttributeName: 'PK',
                KeyType: 'HASH'
            },
            {
                AttributeName: 'SK',
                KeyType: 'RANGE'
            }
        ],
        AttributeDefinitions: [
            {
                AttributeName: 'PK',
                AttributeType: 'S'
            },
            {
                AttributeName: 'SK',
                AttributeType: 'S'
            },
            {
                AttributeName: 'GSI1PK',
                AttributeType: 'S'
            },
            {
                AttributeName: 'GSI1SK',
                AttributeType: 'S'
            }
        ],
        GlobalSecondaryIndexes: [
            {
                IndexName: 'GSI1',
                KeySchema: [
                    {
                        AttributeName: 'GSI1PK',
                        KeyType: 'HASH'
                    },
                    {
                        AttributeName: 'GSI1SK',
                        KeyType: 'RANGE'
                    }
                ],
                Projection: {
                    ProjectionType: 'ALL'
                },
                ProvisionedThroughput: {
                    ReadCapacityUnits: 5,
                    WriteCapacityUnits: 5
                }
            }
        ],
        ProvisionedThroughput: {
            ReadCapacityUnits: 5,
            WriteCapacityUnits: 5
        },
        TimeToLiveSpecification: {
            AttributeName: 'ttl',
            Enabled: true
        }
    };

    try {
        await dynamodb.send(new CreateTableCommand(params));
        console.log(`⏳ Waiting for table ${SUBSCRIPTIONS_TABLE} to become active...`);
        await waitUntilTableExists({ client: dynamodb, maxWaitTime: 300 }, { TableName: SUBSCRIPTIONS_TABLE });
        console.log(`✅ Table ${SUBSCRIPTIONS_TABLE} created successfully`);
    } catch (error) {
        console.error(`❌ Failed to create table ${SUBSCRIPTIONS_TABLE}:`, error.message);
        throw error;
    }
}

async function main() {
    console.log('🚀 WebSocket Tables Setup');
    console.log('========================');
    console.log('');
    console.log('📋 Configuration:');
    console.log(`   AWS Profile: ${AWS_PROFILE}`);
    console.log(`   AWS Region: ${AWS_REGION}`);
    console.log(`   Connections Table: ${CONNECTIONS_TABLE}`);
    console.log(`   Subscriptions Table: ${SUBSCRIPTIONS_TABLE}`);
    console.log('');

    try {
        // Check connections table
        console.log('🔍 Checking WebSocket connections table...');
        if (await tableExists(CONNECTIONS_TABLE)) {
            console.log(`✅ Table ${CONNECTIONS_TABLE} already exists and is active`);
        } else {
            await createConnectionsTable();
        }

        console.log('');

        // Check subscriptions table
        console.log('🔍 Checking WebSocket subscriptions table...');
        if (await tableExists(SUBSCRIPTIONS_TABLE)) {
            console.log(`✅ Table ${SUBSCRIPTIONS_TABLE} already exists and is active`);
        } else {
            await createSubscriptionsTable();
        }

        console.log('');
        console.log('🏁 Summary');
        console.log('=========');
        console.log(`✅ ${CONNECTIONS_TABLE} - Ready`);
        console.log(`✅ ${SUBSCRIPTIONS_TABLE} - Ready`);
        console.log('');
        console.log('✨ WebSocket tables setup complete!');
        console.log('');
        console.log('📊 Table Schema:');
        console.log('   PK (Hash Key): Primary key for items');
        console.log('   SK (Range Key): Sort key for items');
        console.log('   GSI1PK/GSI1SK: Global Secondary Index for queries');
        console.log('   TTL: Time-to-live for automatic cleanup');
        console.log('');
        console.log('🚀 Ready for deployment!');

    } catch (error) {
        console.error('❌ Setup failed:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { tableExists, createConnectionsTable, createSubscriptionsTable };
