const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamoDB = new AWS.DynamoDB();

const PRODUCTS_TABLE_NAME = 'order-receiver-products-dev';
const BUSINESSES_TABLE_NAME = 'order-receiver-businesses-dev';

async function checkTableStructure(tableName) {
    console.log(`\n🔍 Checking ${tableName} Table Structure`);
    console.log('==================================================');

    try {
        const tableDescription = await dynamoDB.describeTable({ TableName: tableName }).promise();
        const table = tableDescription.Table;

        console.log('📋 Table Information:');
        console.log(`  - Table Name: ${table.TableName}`);
        console.log(`  - Table Status: ${table.TableStatus}`);
        console.log(`  - Item Count: ${table.ItemCount}`);

        console.log('\n🔑 Key Schema:');
        table.KeySchema.forEach(key => {
            console.log(`  - ${key.AttributeName} (${key.KeyType})`);
        });

        console.log('\n📊 Attribute Definitions:');
        table.AttributeDefinitions.forEach(attr => {
            console.log(`  - ${attr.AttributeName}: ${attr.AttributeType}`);
        });

        console.log('\n🔗 Global Secondary Indexes:');
        if (table.GlobalSecondaryIndexes && table.GlobalSecondaryIndexes.length > 0) {
            table.GlobalSecondaryIndexes.forEach(gsi => {
                console.log(`  - Index Name: ${gsi.IndexName}`);
                console.log(`    Status: ${gsi.IndexStatus}`);
                console.log('    Key Schema:');
                gsi.KeySchema.forEach(key => {
                    console.log(`      - ${key.AttributeName} (${key.KeyType})`);
                });
            });
        } else {
            console.log('  No Global Secondary Indexes found');
        }

        console.log('\n🔗 Local Secondary Indexes:');
        if (table.LocalSecondaryIndexes && table.LocalSecondaryIndexes.length > 0) {
            table.LocalSecondaryIndexes.forEach(lsi => {
                console.log(`  - Index Name: ${lsi.IndexName}`);
                console.log('    Key Schema:');
                lsi.KeySchema.forEach(key => {
                    console.log(`      - ${key.AttributeName} (${key.KeyType})`);
                });
            });
        } else {
            console.log('  No Local Secondary Indexes found');
        }

    } catch (error) {
        console.error(`❌ Error describing table ${tableName}:`, error);
    }
}

async function runChecks() {
    console.log('Starting table structure check...');
    await checkTableStructure(PRODUCTS_TABLE_NAME);
    await checkTableStructure(BUSINESSES_TABLE_NAME);
}

// Run the check
runChecks();
