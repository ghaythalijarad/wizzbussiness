const AWS = require('aws-sdk');
const https = require('https');
const { v4: uuidv4 } = require('uuid');

const dynamodb = new AWS.DynamoDB.DocumentClient();
const DEVICE_TOKENS_TABLE = process.env.DEVICE_TOKENS_TABLE;
const PUSH_LOGS_TABLE = process.env.PUSH_LOGS_TABLE;
const FCM_SERVER_KEY = process.env.FCM_SERVER_KEY;

exports.handler = async (event) => {
  console.log('OnNewOrder event:', JSON.stringify(event, null, 2));

  try {
    // Extract order details from EventBridge event
    const orderData = event.detail;
    const { orderId, businessId, customerName, total, items } = orderData;

    console.log(`New order received: ${orderId} for business: ${businessId}`);

    // Get device tokens for the merchant
    const deviceTokens = await getDeviceTokensForMerchant(businessId);
    
    if (deviceTokens.length === 0) {
      console.log('No device tokens found for merchant:', businessId);
      return { success: true, message: 'No devices to notify' };
    }

    // Prepare notification content
    const title = '🔔 New Order Received!';
    const body = `Order #${orderId} from ${customerName} - $${total.toFixed(2)}`;
    const data = {
      orderId,
      businessId,
      type: 'new_order',
      action: 'view_order'
    };

    // Send push notifications to all merchant devices
    const results = await Promise.allSettled(
      deviceTokens.map(tokenData => sendFCMNotification(tokenData.deviceToken, title, body, data))
    );

    // Log results
    const logId = uuidv4();
    await logPushResults(logId, businessId, title, body, results);

    const successCount = results.filter(r => r.status === 'fulfilled').length;
    const failureCount = results.filter(r => r.status === 'rejected').length;

    console.log(`Push notifications sent: ${successCount} success, ${failureCount} failed`);

    return {
      success: true,
      message: 'Order notifications sent',
      data: {
        orderId,
        totalDevices: deviceTokens.length,
        successCount,
        failureCount
      }
    };

  } catch (error) {
    console.error('Error processing new order notification:', error);
    throw error;
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
        badge: 1,
        icon: 'ic_notification'
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      priority: 'high',
      content_available: true
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
