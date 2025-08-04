const AWS = require('aws-sdk');
const https = require('https');
const { v4: uuidv4 } = require('uuid');

const dynamodb = new AWS.DynamoDB.DocumentClient();
const DEVICE_TOKENS_TABLE = process.env.DEVICE_TOKENS_TABLE;
const PUSH_LOGS_TABLE = process.env.PUSH_LOGS_TABLE;
const FCM_SERVER_KEY = process.env.FCM_SERVER_KEY;

// FCM endpoint
const FCM_ENDPOINT = 'https://fcm.googleapis.com/fcm/send';

exports.handler = async (event) => {
  console.log('SendPushNotification event:', JSON.stringify(event, null, 2));

  try {
    const body = JSON.parse(event.body);
    const { merchantId, title, message, data = {} } = body;

    if (!merchantId || !title || !message) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        },
        body: JSON.stringify({
          success: false,
          message: 'merchantId, title, and message are required'
        })
      };
    }

    // Get all device tokens for the merchant
    const deviceTokens = await getDeviceTokensForMerchant(merchantId);
    
    if (deviceTokens.length === 0) {
      return {
        statusCode: 404,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        },
        body: JSON.stringify({
          success: false,
          message: 'No device tokens found for merchant'
        })
      };
    }

    // Send push notifications to all devices
    const results = await Promise.allSettled(
      deviceTokens.map(tokenData => sendFCMNotification(tokenData.deviceToken, title, message, data))
    );

    // Log results
    const logId = uuidv4();
    await logPushResults(logId, merchantId, title, message, results);

    const successCount = results.filter(r => r.status === 'fulfilled').length;
    const failureCount = results.filter(r => r.status === 'rejected').length;

    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
      },
      body: JSON.stringify({
        success: true,
        message: 'Push notifications sent',
        data: {
          totalDevices: deviceTokens.length,
          successCount,
          failureCount,
          logId
        }
      })
    };

  } catch (error) {
    console.error('Error sending push notification:', error);

    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
      },
      body: JSON.stringify({
        success: false,
        message: 'Failed to send push notification',
        error: error.message
      })
    };
  }
};

async function getDeviceTokensForMerchant(merchantId) {
  const params = {
    TableName: DEVICE_TOKENS_TABLE,
    KeyConditionExpression: 'merchantId = :merchantId',
    FilterExpression: 'active = :active',
    ExpressionAttributeValues: {
      ':merchantId': merchantId,
      ':active': true
    }
  };

  const result = await dynamodb.query(params).promise();
  return result.Items || [];
}

function sendFCMNotification(deviceToken, title, body, data = {}) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify({
      to: deviceToken,
      notification: {
        title,
        body,
        sound: 'default',
        badge: 1
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      priority: 'high'
    });

    const options = {
      hostname: 'fcm.googleapis.com',
      port: 443,
      path: '/fcm/send',
      method: 'POST',
      headers: {
        'Authorization': `key=${FCM_SERVER_KEY}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          const response = JSON.parse(responseData);
          console.log('FCM Response:', response);

          if (res.statusCode === 200 && response.success >= 1) {
            resolve({
              success: true,
              deviceToken,
              response
            });
          } else {
            reject(new Error(`FCM failed: ${responseData}`));
          }
        } catch (parseError) {
          reject(new Error(`Failed to parse FCM response: ${responseData}`));
        }
      });
    });

    req.on('error', (error) => {
      console.error('FCM request error:', error);
      reject(error);
    });

    req.write(payload);
    req.end();
  });
}

async function logPushResults(logId, merchantId, title, message, results) {
  const timestamp = Date.now();
  const ttl = Math.floor(timestamp / 1000) + (30 * 24 * 60 * 60); // 30 days TTL

  const logEntry = {
    logId,
    merchantId,
    title,
    message,
    timestamp,
    results: results.map(r => ({
      status: r.status,
      value: r.status === 'fulfilled' ? r.value : null,
      reason: r.status === 'rejected' ? r.reason.message : null
    })),
    ttl
  };

  await dynamodb.put({
    TableName: PUSH_LOGS_TABLE,
    Item: logEntry
  }).promise();
}
