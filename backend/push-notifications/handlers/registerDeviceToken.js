const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

const dynamodb = new AWS.DynamoDB.DocumentClient();
const DEVICE_TOKENS_TABLE = process.env.DEVICE_TOKENS_TABLE;

exports.handler = async (event) => {
  console.log('RegisterDeviceToken event:', JSON.stringify(event, null, 2));

  try {
    // Parse request body
    const body = JSON.parse(event.body);
    const { deviceToken } = body;

    if (!deviceToken) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        },
        body: JSON.stringify({
          success: false,
          message: 'deviceToken is required'
        })
      };
    }

    // Extract merchant ID from Cognito JWT
    const claims = event.requestContext.authorizer.claims;
    const merchantId = claims.sub; // User ID from Cognito
    const email = claims.email;

    console.log('Registering device token for merchant:', merchantId, email);

    // Determine platform (iOS/Android) from token format
    let platform = 'unknown';
    if (deviceToken.length === 64) {
      platform = 'ios'; // APNs tokens are typically 64 characters
    } else if (deviceToken.includes(':')) {
      platform = 'android'; // FCM tokens contain colons
    }

    // Store device token in DynamoDB
    const timestamp = Date.now();
    const ttl = Math.floor(timestamp / 1000) + (90 * 24 * 60 * 60); // 90 days TTL

    const params = {
      TableName: DEVICE_TOKENS_TABLE,
      Item: {
        merchantId,
        deviceToken,
        platform,
        email,
        createdAt: timestamp,
        updatedAt: timestamp,
        ttl,
        active: true
      },
      // Prevent overwriting newer registrations
      ConditionExpression: 'attribute_not_exists(merchantId) OR updatedAt < :timestamp',
      ExpressionAttributeValues: {
        ':timestamp': timestamp
      }
    };

    try {
      await dynamodb.put(params).promise();
    } catch (conditionalError) {
      if (conditionalError.code === 'ConditionalCheckFailedException') {
        // Token already exists with newer timestamp, just update the timestamp
        const updateParams = {
          TableName: DEVICE_TOKENS_TABLE,
          Key: {
            merchantId,
            deviceToken
          },
          UpdateExpression: 'SET updatedAt = :timestamp, active = :active, #ttl = :ttl',
          ExpressionAttributeNames: {
            '#ttl': 'ttl'
          },
          ExpressionAttributeValues: {
            ':timestamp': timestamp,
            ':active': true,
            ':ttl': ttl
          }
        };
        await dynamodb.update(updateParams).promise();
      } else {
        throw conditionalError;
      }
    }

    console.log('Device token registered successfully');

    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
      },
      body: JSON.stringify({
        success: true,
        message: 'Device token registered successfully',
        data: {
          merchantId,
          platform,
          registeredAt: timestamp
        }
      })
    };

  } catch (error) {
    console.error('Error registering device token:', error);

    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
      },
      body: JSON.stringify({
        success: false,
        message: 'Failed to register device token',
        error: error.message
      })
    };
  }
};
