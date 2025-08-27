const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB();

console.log('🔧 Creating WhizzMerchants_BusinessWorkingHours table...');

const tableName = 'WhizzMerchants_BusinessWorkingHours';

async function run() {
  try {
    // List tables to see what exists
    const listResult = await dynamodb.listTables().promise();
    console.log('📋 Existing tables:', listResult.TableNames);
    
    if (listResult.TableNames.includes(tableName)) {
      console.log(`✅ Table ${tableName} already exists!`);
      return;
    }
    
    // Create the table
    const params = {
      TableName: tableName,
      KeySchema: [
        { AttributeName: 'businessId', KeyType: 'HASH' },
        { AttributeName: 'weekday', KeyType: 'RANGE' }
      ],
      AttributeDefinitions: [
        { AttributeName: 'businessId', AttributeType: 'S' },
        { AttributeName: 'weekday', AttributeType: 'S' }
      ],
      BillingMode: 'PAY_PER_REQUEST'
    };
    
    console.log(`🚀 Creating table ${tableName}...`);
    const result = await dynamodb.createTable(params).promise();
    console.log('✅ Table created successfully!');
    console.log('📊 Status:', result.TableDescription.TableStatus);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

run();
