const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB();

const tableName = 'WhizzMerchants_BusinessWorkingHours';

const tableParams = {
  TableName: tableName,
  KeySchema: [
    { AttributeName: 'businessId', KeyType: 'HASH' },
    { AttributeName: 'weekday', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'businessId', AttributeType: 'S' },
    { AttributeName: 'weekday', AttributeType: 'S' }
  ],
  BillingMode: 'PAY_PER_REQUEST',
  Tags: [
    {
      Key: 'Environment',
      Value: 'development'
    },
    {
      Key: 'Service',
      Value: 'WhizzMerchants'
    },
    {
      Key: 'Purpose',
      Value: 'business-working-hours'
    }
  ]
};

async function createTable() {
  try {
    // First check if table exists
    console.log(`🔍 Checking if table ${tableName} exists...`);
    
    try {
      const tableDescription = await dynamodb.describeTable({ TableName: tableName }).promise();
      console.log(`✅ Table ${tableName} already exists!`);
      console.log(`📊 Table status: ${tableDescription.Table.TableStatus}`);
      console.log(`🔑 Key schema:`, tableDescription.Table.KeySchema);
      return;
    } catch (error) {
      if (error.code !== 'ResourceNotFoundException') {
        throw error;
      }
      console.log(`📝 Table ${tableName} does not exist, creating...`);
    }
    
    // Create the table
    console.log(`🚀 Creating table: ${tableName}`);
    const result = await dynamodb.createTable(tableParams).promise();
    console.log('✅ Table created successfully:', result.TableDescription.TableName);
    console.log('📊 Table status:', result.TableDescription.TableStatus);
    console.log('🔑 Key schema:', result.TableDescription.KeySchema);
    
    // Wait for table to become active
    console.log('⏳ Waiting for table to become active...');
    await dynamodb.waitFor('tableExists', { TableName: tableName }).promise();
    console.log('🎉 Table is now active and ready to use!');
    
  } catch (error) {
    console.error('❌ Error creating table:', error);
    throw error;
  }
}

async function listAllTables() {
  try {
    console.log('\n📋 Listing all DynamoDB tables:');
    const result = await dynamodb.listTables().promise();
    result.TableNames.forEach(tableName => {
      console.log(`  - ${tableName}`);
    });
    console.log(`\n📊 Total tables: ${result.TableNames.length}`);
  } catch (error) {
    console.error('❌ Error listing tables:', error);
  }
}

async function main() {
  console.log('🔧 WhizzMerchants Working Hours Table Setup');
  console.log('==========================================\n');
  
  try {
    await listAllTables();
    await createTable();
    
    console.log('\n✅ Setup completed successfully!');
    console.log(`\nTable created: ${tableName}`);
    console.log('Schema:');
    console.log('  - businessId (Hash Key): String');
    console.log('  - weekday (Range Key): String');
    console.log('  - opening: String (HH:MM format)');
    console.log('  - closing: String (HH:MM format)');
    console.log('  - updatedAt: String (ISO timestamp)');
    
  } catch (error) {
    console.error('\n❌ Setup failed:', error.message);
    process.exit(1);
  }
}

// Run setup if called directly
if (require.main === module) {
  main();
}

module.exports = { createTable, listAllTables };
