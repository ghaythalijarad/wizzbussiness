# Amazon Pinpoint Push Notifications Setup Guide

## ✅ Completed Tasks

### 1. Dependencies Added
- ✅ Replaced Firebase dependencies with Amplify Pinpoint
- ✅ Added `amplify_push_notifications_pinpoint: ^2.0.0`
- ✅ Added `amplify_analytics_pinpoint: ^2.0.0`

### 2. Code Changes
- ✅ Updated `main.dart` with Pinpoint configuration
- ✅ Created `PinpointService` for push notification management
- ✅ Added background notification handler
- ✅ Updated `AppConfig` with Pinpoint app ID configuration
- ✅ Updated notification imports and API calls

### 3. WebSocket Real-time Updates
- ✅ WebSocket integration already working
- ✅ Real-time order updates implemented
- ✅ Local notifications working with sound

## 🔄 Next Steps (AWS Console Setup)

### 1. Create Pinpoint Application
```bash
1. Go to AWS Console → Amazon Pinpoint
2. Create a new project/application
3. Note the Application ID (looks like: abc123def456)
4. Update AppConfig.pinpointAppId with your actual App ID
```

### 2. Configure Push Notification Certificates

#### For iOS (APNs):
```bash
1. In Pinpoint console → Settings → Push notifications
2. Click "Edit" for APNs
3. Upload your .p12 certificate or use Token-based authentication
4. Configure sandbox/production settings
```

#### For Android (FCM):
```bash
1. In Pinpoint console → Settings → Push notifications  
2. Click "Edit" for FCM
3. Add your Firebase Server Key
4. Add your Firebase Sender ID
```

### 3. Update Configuration
```dart
// In lib/config/app_config.dart, replace:
static const String _pinpointAppId = String.fromEnvironment(
  'PINPOINT_APP_ID',
  defaultValue: 'YOUR_ACTUAL_PINPOINT_APP_ID_HERE', // Replace this
);
```

### 4. Backend Lambda Functions

Create these Lambda functions to handle push notifications:

#### A. Device Token Registration
```javascript
// Lambda function to register device tokens
exports.handler = async (event) => {
  const pinpoint = new AWS.Pinpoint();
  const { deviceToken, businessId, platform } = JSON.parse(event.body);
  
  const params = {
    ApplicationId: 'YOUR_PINPOINT_APP_ID',
    EndpointId: deviceToken,
    EndpointRequest: {
      Address: deviceToken,
      ChannelType: platform === 'ios' ? 'APNS' : 'GCM',
      OptOut: 'NONE',
      User: {
        Attributes: {
          businessId: [businessId]
        }
      }
    }
  };
  
  await pinpoint.updateEndpoint(params).promise();
  return { statusCode: 200, body: JSON.stringify({ success: true }) };
};
```

#### B. Send Push Notification
```javascript
// Lambda function to send push notifications
exports.handler = async (event) => {
  const pinpoint = new AWS.Pinpoint();
  const { businessId, title, body, orderId } = event;
  
  const params = {
    ApplicationId: 'YOUR_PINPOINT_APP_ID',
    MessageRequest: {
      Addresses: {}, // Will be populated by segment
      MessageConfiguration: {
        APNSMessage: {
          Action: 'OPEN_APP',
          Body: body,
          Title: title,
          Data: { orderId: orderId }
        },
        GCMMessage: {
          Action: 'OPEN_APP',
          Body: body,
          Title: title,
          Data: { orderId: orderId }
        }
      },
      Endpoints: {}, // Use segments instead
      Context: {
        businessId: businessId
      }
    }
  };
  
  await pinpoint.sendMessages(params).promise();
  return { statusCode: 200, body: JSON.stringify({ success: true }) };
};
```

### 5. API Gateway Integration
Add these endpoints to your existing API Gateway:

```bash
POST /device-token/register  # For token registration
POST /notifications/send     # For sending notifications
```

### 6. iOS Configuration (if targeting iOS)

Add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### 7. Android Configuration (if targeting Android)

Update `android/app/build.gradle`:
```gradle
dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.0.0'
}
```

## 🧪 Testing

### 1. Test Device Token Registration
```dart
// In your app, test token registration
final pinpointService = PinpointService();
await pinpointService.initialize();

// Check logs for device token
```

### 2. Test Notifications
```bash
# Use AWS CLI to send test notification
aws pinpoint send-messages \
  --application-id YOUR_PINPOINT_APP_ID \
  --message-request file://test-message.json
```

## ⚠️ Important Notes

1. **Pinpoint Deprecation**: AWS announced Pinpoint deprecation for October 2026. Consider migrating to AWS End User Messaging for long-term projects.

2. **Current Status**: 
   - WebSocket real-time updates are working ✅
   - Local notifications with sound are working ✅
   - Push notifications need AWS Pinpoint app creation and certificate setup

3. **Alternative**: Consider using Firebase Cloud Messaging (FCM) directly if simpler setup is preferred.

## 🔍 Troubleshooting

### Common Issues:
1. **Device token not received**: Check iOS entitlements and Android permissions
2. **Notifications not appearing**: Verify certificate configuration in Pinpoint
3. **Background notifications not working**: Ensure background handler is properly registered

### Debug Commands:
```bash
# Check Flutter dependencies
flutter pub deps

# Check iOS entitlements
open ios/Runner.xcworkspace

# Check Android permissions
cat android/app/src/main/AndroidManifest.xml
```

## 📱 Current Working Features

✅ **Real-time Order Updates**: WebSocket connection provides instant order notifications
✅ **Local Notifications**: Sound alerts when new orders arrive  
✅ **Order Management**: Full order lifecycle management
✅ **Authentication**: AWS Cognito integration working
✅ **Business Dashboard**: Complete merchant interface

The app is fully functional for real-time order management. Push notifications are an enhancement for when the app is backgrounded/closed.
