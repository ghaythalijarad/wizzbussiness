const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({
  region: 'us-east-1'
});

const dynamodb = new AWS.DynamoDB();

async function createPosLogsTable() {
  const params = {
    TableName: 'order-receiver-pos-logs-dev',
    AttributeDefinitions: [
      {
        AttributeName: 'log_id',
        AttributeType: 'S'
      },
      {
        AttributeName: 'business_id',
        AttributeType: 'S'
      },
      {
        AttributeName: 'timestamp',
        AttributeType: 'S'
      }
    ],
    KeySchema: [
      {
        AttributeName: 'log_id',
        KeyType: 'HASH'
      }
    ],
    GlobalSecondaryIndexes: [
      {
        IndexName: 'business-id-timestamp-index',
        KeySchema: [
          {
            AttributeName: 'business_id',
            KeyType: 'HASH'
          },
          {
            AttributeName: 'timestamp',
            KeyType: 'RANGE'
          }
        ],
        Projection: {
          ProjectionType: 'ALL'
        }
      }
    ],
    BillingMode: 'PAY_PER_REQUEST',
    Tags: [
      {
        Key: 'Environment',
        Value: 'dev'
      },
      {
        Key: 'Service',
        Value: 'order-receiver'
      },
      {
        Key: 'Purpose',
        Value: 'pos-logs'
      }
    ]
  };

  try {
    console.log('🔧 Creating POS logs table...');
    const result = await dynamodb.createTable(params).promise();
    console.log('✅ POS logs table created successfully!');
    console.log('Table ARN:', result.TableDescription.TableArn);
    return result;
  } catch (error) {
    if (error.code === 'ResourceInUseException') {
      console.log('✅ POS logs table already exists');
      return null;
    }
    throw error;
  }
}

// Run the function
createPosLogsTable()
  .then(() => {
    console.log('✅ Setup complete!');
  })
  .catch((error) => {
    console.error('❌ Error:', error.message);
    process.exit(1);
  });
