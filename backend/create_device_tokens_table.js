/**
 * Create DeviceTokens DynamoDB Table
 * 
 * This table stores Firebase Cloud Messaging (FCM) device tokens
 * for push notification delivery to merchant devices.
 */

const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB();

const tableName = 'DeviceTokens';

const tableParams = {
  TableName: tableName,
  KeySchema: [
    { AttributeName: 'PK', KeyType: 'HASH' },    // Partition Key: BUSINESS#businessId
    { AttributeName: 'SK', KeyType: 'RANGE' }    // Sort Key: TOKEN#deviceToken
  ],
  AttributeDefinitions: [
    { AttributeName: 'PK', AttributeType: 'S' },
    { AttributeName: 'SK', AttributeType: 'S' },
    { AttributeName: 'deviceToken', AttributeType: 'S' }
  ],
  GlobalSecondaryIndexes: [
    {
      IndexName: 'TokenIndex',
      KeySchema: [
        { AttributeName: 'deviceToken', KeyType: 'HASH' }
      ],
      Projection: {
        ProjectionType: 'ALL'
      }
    }
  ],
  BillingMode: 'PAY_PER_REQUEST',
  TimeToLiveSpecification: {
    AttributeName: 'ttl',
    Enabled: true
  },
  Tags: [
    {
      Key: 'Project',
      Value: 'OrderReceiver'
    },
    {
      Key: 'Environment',
      Value: 'dev'
    },
    {
      Key: 'Purpose',
      Value: 'PushNotifications'
    }
  ]
};

async function createDeviceTokensTable() {
  try {
    console.log(`Creating DynamoDB table: ${tableName}...`);
    
    // Check if table already exists
    try {
      const existingTable = await dynamodb.describeTable({ TableName: tableName }).promise();
      console.log(`Table ${tableName} already exists with status: ${existingTable.Table.TableStatus}`);
      return;
    } catch (error) {
      if (error.code !== 'ResourceNotFoundException') {
        throw error;
      }
      // Table doesn't exist, proceed with creation
    }

    const result = await dynamodb.createTable(tableParams).promise();
    console.log(`✅ Table ${tableName} created successfully!`);
    console.log('Table ARN:', result.TableDescription.TableArn);

    // Wait for table to be active
    console.log('Waiting for table to become active...');
    await dynamodb.waitFor('tableExists', { TableName: tableName }).promise();
    console.log(`✅ Table ${tableName} is now active and ready to use!`);

    // Print table structure
    const description = await dynamodb.describeTable({ TableName: tableName }).promise();
    console.log('\n📋 Table Structure:');
    console.log('- Table Name:', description.Table.TableName);
    console.log('- Table Status:', description.Table.TableStatus);
    console.log('- Key Schema:', JSON.stringify(description.Table.KeySchema, null, 2));
    console.log('- Global Secondary Indexes:', JSON.stringify(description.Table.GlobalSecondaryIndexes, null, 2));
    console.log('- TTL Status:', description.Table.TimeToLiveDescription?.TimeToLiveStatus || 'Not configured');

  } catch (error) {
    console.error(`❌ Error creating table ${tableName}:`, error);
    throw error;
  }
}

// Run the table creation
if (require.main === module) {
  createDeviceTokensTable()
    .then(() => {
      console.log('\n🎉 DeviceTokens table setup completed successfully!');
      console.log('\nTable Structure:');
      console.log('- PK: BUSINESS#businessId (Partition Key)');
      console.log('- SK: TOKEN#deviceToken (Sort Key)');
      console.log('- deviceToken: FCM device token (GSI)');
      console.log('- businessId: Business identifier');
      console.log('- platform: ios/android');
      console.log('- userId: User identifier');
      console.log('- registrationDate: ISO timestamp');
      console.log('- lastUpdated: ISO timestamp');
      console.log('- isActive: boolean');
      console.log('- ttl: Unix timestamp (90 days from creation)');
      console.log('\nReverse lookup pattern:');
      console.log('- PK: TOKEN#deviceToken');
      console.log('- SK: BUSINESS#businessId');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n❌ DeviceTokens table setup failed:', error);
      process.exit(1);
    });
}

module.exports = { createDeviceTokensTable };
