const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({
  region: 'eu-north-1'
});

const dynamodb = new AWS.DynamoDB();

async function createBusinessSettingsTable() {
  console.log('📋 Creating BusinessSettings table...');
  
  const params = {
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
    const result = await dynamodb.createTable(params).promise();
    console.log('✅ BusinessSettings table created successfully');
    return result;
  } catch (error) {
    if (error.code === 'ResourceInUseException') {
      console.log('ℹ️ BusinessSettings table already exists');
    } else {
      console.error('❌ Error creating BusinessSettings table:', error);
      throw error;
    }
  }
}

async function createPosLogsTable() {
  console.log('📋 Creating PosLogs table...');
  
  const params = {
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
    const result = await dynamodb.createTable(params).promise();
    console.log('✅ PosLogs table created successfully');
    return result;
  } catch (error) {
    if (error.code === 'ResourceInUseException') {
      console.log('ℹ️ PosLogs table already exists');
    } else {
      console.error('❌ Error creating PosLogs table:', error);
      throw error;
    }
  }
}

async function listTables() {
  console.log('📋 Listing existing tables...');
  
  try {
    const result = await dynamodb.listTables().promise();
    const relevantTables = result.TableNames.filter(name => 
      name.includes('order-receiver') || name.includes('business') || name.includes('pos')
    );
    
    console.log('📋 Relevant tables found:');
    relevantTables.forEach(table => {
      console.log(`   - ${table}`);
    });
    
    return relevantTables;
  } catch (error) {
    console.error('❌ Error listing tables:', error);
    throw error;
  }
}

async function setupPosSettingsTables() {
  console.log('🔧 Setting up POS Settings DynamoDB Tables');
  console.log('==========================================\n');
  
  try {
    // List existing tables first
    await listTables();
    console.log('');
    
    // Create tables
    await createBusinessSettingsTable();
    await createPosLogsTable();
    
    console.log('\n✅ POS Settings tables setup completed successfully!');
    console.log('\nTables created:');
    console.log('   - order-receiver-business-settings-dev (for storing POS settings)');
    console.log('   - order-receiver-pos-logs-dev (for storing sync logs)');
    
  } catch (error) {
    console.error('\n❌ Setup failed:', error.message);
    process.exit(1);
  }
}

// Run setup if called directly
if (require.main === module) {
  setupPosSettingsTables();
}

module.exports = {
  createBusinessSettingsTable,
  createPosLogsTable,
  listTables,
  setupPosSettingsTables
};
