const AWS = require('aws-sdk');

const sns = new AWS.SNS();
const dynamodb = new AWS.DynamoDB.DocumentClient();

/**
 * Push Notification Service
 * Handles FCM (Android) and APNS (iOS) push notifications for merchants
 */

/**
 * Send push notification to merchant's mobile app
 */
async function sendPushNotification(endpoint, notification) {
    try {
        const { deviceToken, platform } = endpoint;
        const { type, title, message, data } = notification;
        
        let payload;
        let targetArn;
        
        if (platform === 'ios') {
            // APNS payload format
            payload = {
                aps: {
                    alert: {
                        title: title,
                        body: message
                    },
                    sound: 'default',
                    badge: 1
                },
                data: data || {}
            };
            targetArn = process.env.SNS_APNS_ARN;
        } else if (platform === 'android') {
            // FCM payload format
            payload = {
                notification: {
                    title: title,
                    body: message,
                    sound: 'default',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK'
                },
                data: {
                    type: type,
                    ...(data || {})
                }
            };
            targetArn = process.env.SNS_FCM_ARN;
        }
        
        if (!targetArn) {
            console.log('📱 Push notification simulation (no SNS ARN configured):', {
                platform,
                deviceToken: deviceToken.substring(0, 20) + '...',
                payload
            });
            return;
        }
        
        // Create SNS platform endpoint if needed
        const endpointArn = await createOrGetPlatformEndpoint(deviceToken, platform, targetArn);
        
        // Send notification
        const snsParams = {
            TargetArn: endpointArn,
            Message: JSON.stringify(payload),
            MessageStructure: 'json'
        };
        
        if (platform === 'ios') {
            snsParams.MessageAttributes = {
                'AWS.SNS.MOBILE.APNS.TOPIC': {
                    DataType: 'String',
                    StringValue: process.env.APNS_BUNDLE_ID || 'com.hadhir.business'
                }
            };
        }
        
        const result = await sns.publish(snsParams).promise();
        console.log('📱 Push notification sent successfully:', result.MessageId);
        
    } catch (error) {
        console.error('Error sending push notification:', error);
        
        // If endpoint is disabled, remove it from our database
        if (error.code === 'EndpointDisabled') {
            await disableEndpoint(endpoint);
        }
    }
}

/**
 * Create or get SNS platform endpoint
 */
async function createOrGetPlatformEndpoint(deviceToken, platform, platformArn) {
    try {
        const params = {
            PlatformApplicationArn: platformArn,
            Token: deviceToken
        };
        
        const result = await sns.createPlatformEndpoint(params).promise();
        return result.EndpointArn;
        
    } catch (error) {
        if (error.code === 'InvalidParameter' && error.message.includes('already exists')) {
            // Extract endpoint ARN from error message or use existing one
            console.log('Platform endpoint already exists, retrieving...');
            // In production, you'd want to store endpoint ARNs in DynamoDB
            throw error; // For now, let caller handle
        }
        throw error;
    }
}

/**
 * Disable endpoint in database when push notification fails
 */
async function disableEndpoint(endpoint) {
    try {
        const params = {
            TableName: process.env.MERCHANT_ENDPOINTS_TABLE,
            Key: {
                merchantId: endpoint.merchantId,
                endpointType: endpoint.endpointType
            },
            UpdateExpression: 'SET isActive = :inactive, disabledAt = :timestamp',
            ExpressionAttributeValues: {
                ':inactive': false,
                ':timestamp': new Date().toISOString()
            }
        };
        
        await dynamodb.update(params).promise();
        console.log('📱 Disabled inactive endpoint:', endpoint.deviceToken.substring(0, 20));
        
    } catch (error) {
        console.error('Error disabling endpoint:', error);
    }
}

/**
 * Send bulk push notifications to multiple merchants
 */
async function sendBulkPushNotifications(merchantIds, notification) {
    try {
        const promises = merchantIds.map(async (merchantId) => {
            // Get active endpoints for merchant
            const params = {
                TableName: process.env.MERCHANT_ENDPOINTS_TABLE,
                KeyConditionExpression: 'merchantId = :merchantId',
                FilterExpression: 'endpointType = :type AND isActive = :active',
                ExpressionAttributeValues: {
                    ':merchantId': merchantId,
                    ':type': 'mobile_push',
                    ':active': true
                }
            };
            
            const result = await dynamodb.query(params).promise();
            const endpoints = result.Items;
            
            // Send notification to all endpoints
            return Promise.all(
                endpoints.map(endpoint => sendPushNotification(endpoint, notification))
            );
        });
        
        await Promise.all(promises);
        console.log(`📱 Bulk notifications sent to ${merchantIds.length} merchants`);
        
    } catch (error) {
        console.error('Error sending bulk push notifications:', error);
    }
}

module.exports = {
    sendPushNotification,
    sendBulkPushNotifications,
    createOrGetPlatformEndpoint,
    disableEndpoint
};
