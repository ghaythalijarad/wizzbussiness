const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB();

const tableName = 'order-receiver-business-working-hours-dev';

const tableParams = {
  TableName: tableName,
  KeySchema: [
    { AttributeName: 'business_id', KeyType: 'HASH' },
    { AttributeName: 'weekday', KeyType: 'RANGE' }
  ],
  AttributeDefinitions: [
    { AttributeName: 'business_id', AttributeType: 'S' },
    { AttributeName: 'weekday', AttributeType: 'S' }
  ],
  BillingMode: 'PAY_PER_REQUEST'
};

async function createTable() {
  try {
    console.log(`Creating table: ${tableName}`);
    const result = await dynamodb.createTable(tableParams).promise();
    console.log('✅ Table created successfully:', result.TableDescription.TableName);
    console.log('Table status:', result.TableDescription.TableStatus);
  } catch (error) {
    if (error.code === 'ResourceInUseException') {
      console.log('⚠️ Table already exists');
    } else {
      console.error('❌ Error creating table:', error);
    }
  }
}

createTable();
