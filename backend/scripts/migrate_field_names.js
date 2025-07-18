const AWS = require('aws-sdk');
const path = require('path');
// Load environment variables from backend/.env
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

// Configure AWS region
const region = process.env.COGNITO_REGION || 'us-east-1';
AWS.config.update({ region });
const docClient = new AWS.DynamoDB.DocumentClient();

// Mapping of DynamoDB tables to their primary key attribute
const tableKeyMap = {
  [process.env.BUSINESSES_TABLE]: 'businessId',
  [process.env.CATEGORIES_TABLE]: 'categoryId',
  [process.env.PRODUCTS_TABLE]: 'productId',
  [process.env.DISCOUNTS_TABLE]: 'discountId',
  [process.env.BUSINESS_SETTINGS_TABLE]: 'settingId',
  [process.env.BUSINESS_WORKING_HOURS_TABLE]: 'workingHoursId',
  [process.env.POS_LOGS_TABLE]: 'logId',
  [process.env.USERS_TABLE]: 'userId',
};

// Convert camelCase to snake_case
function toSnakeCase(str) {
  return str.replace(/([a-z0-9])([A-Z])/g, '$1_$2').toLowerCase();
}

async function migrateTable(tableName) {
  console.log(`\nMigrating table: ${tableName}`);
  const keyAttr = tableKeyMap[tableName];
  if (!keyAttr) {
    console.warn(`  Skipping table ${tableName}: no primary key mapping defined.`);
    return;
  }

  // Scan all items
  let ExclusiveStartKey;
  do {
    const scanParams = { TableName: tableName, ExclusiveStartKey };
    const result = await docClient.scan(scanParams).promise();
    ExclusiveStartKey = result.LastEvaluatedKey;

    for (const item of result.Items) {
      const key = { [keyAttr]: item[keyAttr] };
      // If this is the businesses table, add a snake_case mirror of the key
      if (tableName === process.env.BUSINESSES_TABLE) {
        if (!item.business_id) {
          await docClient.update({
            TableName: tableName,
            Key: key,
            UpdateExpression: 'SET business_id = :val',
            ExpressionAttributeValues: { ':val': item[keyAttr] }
          }).promise();
          console.log(`  Added business_id for ${JSON.stringify(key)}`);
        }
      }
      for (const attr in item) {
        // Rename any camelCase attribute to snake_case
        if (/[A-Z]/.test(attr)) {
          const snake = toSnakeCase(attr);
          if (snake !== attr) {
            const updateParams = {
              TableName: tableName,
              Key: key,
              UpdateExpression: `SET #newAttr = :val REMOVE #oldAttr`,
              ExpressionAttributeNames: {
                '#newAttr': snake,
                '#oldAttr': attr,
              },
              ExpressionAttributeValues: {
                ':val': item[attr],
              },
            };
            try {
              await docClient.update(updateParams).promise();
              console.log(`  Renamed ${attr} -> ${snake} for ${JSON.stringify(key)}`);
            } catch (err) {
              console.error(`  Error updating ${tableName} ${JSON.stringify(key)}:`, err.message);
            }
          }
        }
      }
    }
  } while (ExclusiveStartKey);
}

async function runMigration() {
  console.log('Starting field name migration...');
  for (const tableName of Object.keys(tableKeyMap)) {
    await migrateTable(tableName);
  }
  console.log('\nMigration complete.');
}

runMigration().catch(err => console.error('Migration failed:', err));
