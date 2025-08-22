const AWS = require('aws-sdk');

const sns = new AWS.SNS();
const dynamodb = new AWS.DynamoDB.DocumentClient();
const WEBSOCKET_CONNECTIONS_TABLE = process.env.WEBSOCKET_CONNECTIONS_TABLE; // unified table

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
        if (!endpoint.deviceToken) return;
        await dynamodb.update({
            TableName: WEBSOCKET_CONNECTIONS_TABLE,
            Key: { PK: `DEVICE#${endpoint.deviceToken}`, SK: `DEVICE#${endpoint.deviceToken}` },
            UpdateExpression: 'SET isActive = :inactive, disabledAt = :ts',
            ExpressionAttributeValues: { ':inactive': false, ':ts': new Date().toISOString() }
        }).promise();
        console.log('📱 Disabled unified endpoint token prefix:', endpoint.deviceToken.substring(0, 12));
    } catch (error) {
        console.error('Error disabling unified endpoint:', error);
    }
}

/**
 * Send bulk push notifications to multiple merchants
 */
async function sendBulkPushNotifications(merchantIds, notification) {
    try {
        const promises = merchantIds.map(async (merchantId) => {
            // Query unified table GSI1 for mobile_push items
            const params = {
                TableName: WEBSOCKET_CONNECTIONS_TABLE,
                IndexName: 'GSI1',
                KeyConditionExpression: 'GSI1PK = :pk',
                ExpressionAttributeValues: { ':pk': `BUSINESS#${merchantId}` }
            };
            const result = await dynamodb.query(params).promise();
            const endpoints = (result.Items || []).filter(i => i.entityType === 'mobile_push' && i.isActive !== false);
            await Promise.all(endpoints.map(ep => sendPushNotification(ep, notification)));
            return endpoints.length;
        });
        const counts = await Promise.all(promises);
        const total = counts.reduce((a, b) => a + b, 0);
        console.log(`📱 Bulk notifications sent to ${merchantIds.length} merchants (total endpoints ${total})`);
    } catch (error) {
        console.error('Error sending bulk push notifications (unified):', error);
    }
}

module.exports = {
    sendPushNotification,
    sendBulkPushNotifications,
    createOrGetPlatformEndpoint,
    disableEndpoint
};
