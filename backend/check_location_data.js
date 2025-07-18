const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({ region: 'us-east-1' });
const dynamodb = new AWS.DynamoDB.DocumentClient();

async function checkLocationSettings() {
  console.log('🔍 Checking Location Settings in DynamoDB');
  console.log('==========================================');
  
  const businessId = '1c5eeac7-7cad-4c0c-b5c7-a538951f8caa';
  
  try {
    // Check business-settings table for location_settings
    console.log('1️⃣ Checking business-settings table...');
    const settingsParams = {
      TableName: 'order-receiver-business-settings-dev',
      Key: {
        business_id: businessId,
        setting_type: 'location_settings'
      }
    };
    
    const settingsResult = await dynamodb.get(settingsParams).promise();
    
    if (settingsResult.Item) {
      console.log('✅ Location settings found:');
      console.log(JSON.stringify(settingsResult.Item, null, 2));
    } else {
      console.log('❌ No location settings found in business-settings table');
    }
    
    // Check main businesses table
    console.log('\n2️⃣ Checking main businesses table...');
    const businessParams = {
      TableName: 'order-receiver-businesses-dev',
      Key: {
        businessId: businessId
      }
    };
    
    const businessResult = await dynamodb.get(businessParams).promise();
    
    if (businessResult.Item) {
      console.log('✅ Business found:');
      console.log('📍 Latitude:', businessResult.Item.latitude || 'NOT SET');
      console.log('📍 Longitude:', businessResult.Item.longitude || 'NOT SET');
      console.log('🏠 Address:', JSON.stringify(businessResult.Item.address, null, 2));
    } else {
      console.log('❌ Business not found in main table');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

checkLocationSettings();
