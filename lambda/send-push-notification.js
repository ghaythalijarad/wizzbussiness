/**
 * AWS Lambda Function: Send Push Notification via SNS to Firebase
 * 
 * This function sends push notifications to merchants when new orders arrive
 * Uses Amazon SNS to send notifications to Firebase Cloud Messaging (FCM)
 */

const AWS = require('aws-sdk');
const sns = new AWS.SNS({ region: 'us-east-1' });

exports.handler = async (event) => {
    console.log('Push notification event:', JSON.stringify(event, null, 2));

    try {
        // Extract order data from event (could be from DynamoDB Stream, API Gateway, etc.)
        const { 
            businessId, 
            orderId, 
            customerName, 
            orderTotal,
            deviceTokens = [] // Array of FCM device tokens
        } = event;

        // Validate required fields
        if (!businessId || !orderId) {
            throw new Error('Missing required fields: businessId and orderId');
        }

        if (!deviceTokens || deviceTokens.length === 0) {
            console.log('No device tokens found for businessId:', businessId);
            return {
                statusCode: 200,
                body: JSON.stringify({
                    success: true,
                    message: 'No device tokens to send to',
                    businessId: businessId
                })
            };
        }

        // Configure notification content
        const title = 'New Order Received! 🎉';
        const body = `Order from ${customerName || 'Customer'} - $${orderTotal || '0.00'}`;
        
        // Create FCM payload
        const fcmPayload = {
            notification: {
                title: title,
                body: body,
                sound: 'new_order.wav',
                badge: '1'
            },
            data: {
                orderId: orderId,
                businessId: businessId,
                action: 'new_order',
                timestamp: new Date().toISOString()
            },
            android: {
                notification: {
                    sound: 'new_order.wav',
                    channel_id: 'new_orders'
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'new_order.wav',
                        badge: 1
                    }
                }
            }
        };

        const results = [];

        // Send notification to each device token
        for (const token of deviceTokens) {
            try {
                const messagePayload = {
                    ...fcmPayload,
                    token: token
                };

                const snsParams = {
                    Message: JSON.stringify({
                        GCM: JSON.stringify(messagePayload)
                    }),
                    MessageStructure: 'json',
                    TargetArn: `arn:aws:sns:us-east-1:${process.env.AWS_ACCOUNT_ID}:app/GCM/${process.env.FCM_PLATFORM_APPLICATION_ARN}`
                };

                // If you have device-specific endpoints, use them
                // Otherwise, send directly to FCM via HTTP
                const result = await sendDirectToFCM(messagePayload);
                results.push({
                    token: token,
                    success: true,
                    messageId: result.messageId
                });

            } catch (error) {
                console.error(`Error sending to token ${token}:`, error);
                results.push({
                    token: token,
                    success: false,
                    error: error.message
                });
            }
        }

        const successCount = results.filter(r => r.success).length;
        
        console.log(`Push notifications sent: ${successCount}/${deviceTokens.length} successful`);
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: true,
                businessId: businessId,
                orderId: orderId,
                totalSent: deviceTokens.length,
                successCount: successCount,
                results: results
            })
        };

    } catch (error) {
        console.error('Error sending push notification:', error);
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: false,
                error: error.message,
                timestamp: new Date().toISOString()
            })
        };
    }
};

/**
 * Send notification directly to FCM (recommended approach)
 * This bypasses SNS and sends directly to Firebase
 */
async function sendDirectToFCM(payload) {
    const https = require('https');
    
    const data = JSON.stringify(payload);
    
    const options = {
        hostname: 'fcm.googleapis.com',
        port: 443,
        path: '/fcm/send',
        method: 'POST',
        headers: {
            'Authorization': `key=${process.env.FCM_SERVER_KEY}`,
            'Content-Type': 'application/json',
            'Content-Length': data.length
        }
    };

    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let body = '';
            
            res.on('data', (chunk) => {
                body += chunk;
            });
            
            res.on('end', () => {
                try {
                    const response = JSON.parse(body);
                    if (response.success >= 1) {
                        resolve({ messageId: response.results[0].message_id });
                    } else {
                        reject(new Error(response.results[0].error || 'FCM send failed'));
                    }
                } catch (error) {
                    reject(error);
                }
            });
        });

        req.on('error', (error) => {
            reject(error);
        });

        req.write(data);
        req.end();
    });
}

/**
 * Environment Variables Required:
 * - FCM_SERVER_KEY: Your Firebase Cloud Messaging Server Key
 * - AWS_ACCOUNT_ID: Your AWS Account ID (for SNS ARN construction)
 * - FCM_PLATFORM_APPLICATION_ARN: SNS Platform Application ARN (if using SNS)
 * 
 * IAM Permissions Required:
 * - sns:Publish (if using SNS)
 * - logs:CreateLogGroup
 * - logs:CreateLogStream
 * - logs:PutLogEvents
 */
