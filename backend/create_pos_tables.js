const AWS = require('aws-sdk');

// Initialize DynamoDB
const dynamodb = new AWS.DynamoDB();

async function createPOSTables() {
  console.log('🚀 Creating POS DynamoDB tables...');

  try {
    // 1. Create BusinessSettings table
    console.log('📋 Creating BusinessSettings table...');
    const businessSettingsParams = {
      TableName: 'order-receiver-business-settings-dev',
      KeySchema: [
        {
          AttributeName: 'business_id',
          KeyType: 'HASH'
        },
        {
          AttributeName: 'setting_type',
          KeyType: 'RANGE'
        }
      ],
      AttributeDefinitions: [
        {
          AttributeName: 'business_id',
          AttributeType: 'S'
        },
        {
          AttributeName: 'setting_type',
          AttributeType: 'S'
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
          Value: 'business-settings'
        }
      ]
    };

    try {
      await dynamodb.createTable(businessSettingsParams).promise();
      console.log('✅ BusinessSettings table created successfully');
    } catch (error) {
      if (error.code === 'ResourceInUseException') {
        console.log('ℹ️ BusinessSettings table already exists');
      } else {
        throw error;
      }
    }

    // 2. Create PosLogs table
    console.log('📋 Creating PosLogs table...');
    const posLogsParams = {
      TableName: 'order-receiver-pos-logs-dev',
      KeySchema: [
        {
          AttributeName: 'id',
          KeyType: 'HASH'
        }
      ],
      AttributeDefinitions: [
        {
          AttributeName: 'id',
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
      await dynamodb.createTable(posLogsParams).promise();
      console.log('✅ PosLogs table created successfully');
    } catch (error) {
      if (error.code === 'ResourceInUseException') {
        console.log('ℹ️ PosLogs table already exists');
      } else {
        throw error;
      }
    }

    // Wait for tables to be active
    console.log('⏳ Waiting for tables to become active...');
    
    await dynamodb.waitFor('tableExists', {
      TableName: 'order-receiver-business-settings-dev'
    }).promise();
    
    await dynamodb.waitFor('tableExists', {
      TableName: 'order-receiver-pos-logs-dev'
    }).promise();

    console.log('🎉 All POS tables created and are active!');
    
    // List all tables to verify
    const tables = await dynamodb.listTables().promise();
    console.log('📋 Current DynamoDB tables:');
    tables.TableNames.forEach(tableName => {
      console.log(`  - ${tableName}`);
    });

  } catch (error) {
    console.error('❌ Error creating POS tables:', error);
    process.exit(1);
  }
}

// Run the table creation
if (require.main === module) {
  createPOSTables()
    .then(() => {
      console.log('✅ POS tables setup completed successfully');
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ POS tables setup failed:', error);
      process.exit(1);
    });
}

module.exports = { createPOSTables };
