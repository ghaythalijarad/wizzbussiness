const AWS = require('aws-sdk');

AWS.config.update({
  region: 'eu-north-1'
});

const dynamodb = new AWS.DynamoDB();

async function testConnection() {
  try {
    console.log('Testing AWS DynamoDB connection...');
    const result = await dynamodb.listTables().promise();
    console.log('✅ Connection successful!');
    console.log('Existing tables:', result.TableNames);
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
  }
}

testConnection();
