# Merchant App Backend AWS Deployment - Implementation Summary

## Overview
This document summarizes the completed AWS serverless deployment for the merchant app backend, providing real-time order management, WebSocket notifications, and push notification infrastructure.

## Architecture Components

### 1. **API Gateway Endpoints**
**Base URL:** `https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev`

#### Merchant Order Management
- `GET /merchant/orders/{businessId}` - Get orders for a business
  - Query params: `?status=pending|accepted|rejected|preparing|ready`
- `PUT /merchant/order/{orderId}/accept` - Accept an order
- `PUT /merchant/order/{orderId}/reject` - Reject an order  
- `PUT /merchant/order/{orderId}/status` - Update order status
- `POST /merchants/{merchantId}/device-token` - Register device for push notifications
- `POST /webhooks/orders` - Receive orders from Central Platform

### 2. **Lambda Functions**
- **merchantOrderManagement** - Handles all merchant order operations
- **websocketHandler** - Manages WebSocket connections for real-time notifications
- **orderManagement** - Handles customer order operations
- **discountManagement** - Manages discount operations
- **unifiedAuth** - Handles authentication
- **health** - Health check endpoint

### 3. **DynamoDB Tables**

#### Orders Table
```yaml
Table: order-receiver-orders-dev
Primary Key: orderId (String)
GSI: BusinessIdIndex (businessId)
```
**Schema:**
```javascript
{
  orderId: String,           // Primary key
  businessId: String,        // GSI key for merchant queries
  customerId: String,
  customerName: String,
  customerPhone: String,
  deliveryAddress: Object,
  items: Array,
  totalAmount: Number,
  status: String,            // pending|accepted|rejected|preparing|ready|completed
  notes: String,
  platformOrderId: String,   // Reference to Central Platform
  estimatedPreparationTime: Number,
  rejectionReason: String,
  createdAt: String,
  updatedAt: String
}
```

#### Merchant Endpoints Table
```yaml
Table: order-receiver-merchant-endpoints-dev
Primary Key: merchantId (Hash) + endpointType (Range)
GSI: ConnectionIdIndex (connectionId)
```  
**Schema:**
```javascript
{
  merchantId: String,        // Hash key
  endpointType: String,      // Range key: 'mobile_push' | 'websocket'
  deviceToken: String,       // For mobile_push
  platform: String,          // 'ios' | 'android'
  connectionId: String,      // For websocket connections
  isActive: Boolean,
  registeredAt: String,
  updatedAt: String
}
```

### 4. **WebSocket API**
**Endpoint:** `wss://{api-id}.execute-api.us-east-1.amazonaws.com/dev`

#### Connection Flow
1. Connect: `wss://endpoint?merchantId={businessId}`
2. Server stores connection in MerchantEndpointsTable
3. Client receives real-time order notifications

#### Message Types
```javascript
{
  type: 'NEW_ORDER' | 'ORDER_STATUS_UPDATE' | 'CONNECTION_ESTABLISHED',
  orderId: String,
  message: String,
  data: Object,
  timestamp: String
}
```

### 5. **Push Notifications (SNS)**

#### Platform Applications
- **FCM (Android):** `order-receiver-api-fcm-dev`
- **APNS (iOS):** `order-receiver-api-apns-dev`

#### SNS Topic
- **Order Events:** `order-receiver-api-order-events-dev`

#### Notification Payload
```javascript
// iOS (APNS)
{
  aps: {
    alert: { title: String, body: String },
    sound: 'default',
    badge: Number
  },
  data: Object
}

// Android (FCM)  
{
  notification: {
    title: String,
    body: String,
    sound: 'default',
    click_action: 'FLUTTER_NOTIFICATION_CLICK'
  },
  data: Object
}
```

## Integration Flow

### 1. **New Order Flow**
```
Central Platform → POST /webhooks/orders → Lambda → DynamoDB → Notify Merchant
                                                            ↓
                                                    WebSocket + Push Notification
```

### 2. **Order Status Update Flow**
```
Merchant App → PUT /merchant/order/{id}/accept → Lambda → DynamoDB → Notify Customer/Driver
                                                                  ↓
                                                          Central Platform Callback
```

### 3. **Real-time Notifications**
```
Event → SNS Topic → WebSocket Broadcast → Active Connections
     → Push Notifications → Mobile Apps
```

## Environment Variables

```yaml
ORDERS_TABLE: order-receiver-orders-dev
MERCHANT_ENDPOINTS_TABLE: order-receiver-merchant-endpoints-dev
WEBSOCKET_ENDPOINT: wss://{api-id}.execute-api.us-east-1.amazonaws.com/dev
ORDER_EVENTS_TOPIC_ARN: arn:aws:sns:us-east-1:{account}:order-receiver-api-order-events-dev
SNS_FCM_ARN: arn:aws:sns:us-east-1:{account}:app/GCM/order-receiver-api-fcm-dev
SNS_APNS_ARN: arn:aws:sns:us-east-1:{account}:app/APNS_SANDBOX/order-receiver-api-apns-dev
```

## Deployment Status

### ✅ Completed
- [x] Serverless configuration with all resources
- [x] Lambda functions deployed (10 total)
- [x] DynamoDB tables with proper schema and indexes
- [x] API Gateway REST API with merchant endpoints
- [x] WebSocket API Gateway for real-time notifications
- [x] SNS topics and platform applications for push notifications
- [x] IAM permissions and roles
- [x] Environment variables configuration
- [x] CloudFormation outputs for service discovery

### ⚠️ Pending Configuration
- [ ] **FCM Server Key** - Add your Firebase Cloud Messaging server key
- [ ] **APNS Certificates** - Add your Apple Push Notification certificates/keys
- [ ] **Merchant Handler Fix** - Resolve the handler export issue
- [ ] **Central Platform Webhook URL** - Configure callback URL for status updates

### 🧪 Testing Required
- [ ] End-to-end order flow testing
- [ ] WebSocket connection and messaging
- [ ] Push notification delivery
- [ ] Error handling and edge cases

## Next Steps

### 1. **Configure Push Notification Credentials**
```bash
# Update SNS Platform Applications with real credentials
aws sns set-platform-application-attributes \
  --platform-application-arn {FCM_ARN} \
  --attributes PlatformCredential={YOUR_FCM_SERVER_KEY}

aws sns set-platform-application-attributes \
  --platform-application-arn {APNS_ARN} \
  --attributes PlatformCredential={YOUR_APNS_CERTIFICATE}
```

### 2. **Fix Merchant Handler**
- Debug the exports.handler issue in merchant_order_handler.js
- Ensure proper webpack bundling
- Test all merchant endpoints

### 3. **Integration Testing**
- Test complete order lifecycle
- Verify real-time notifications
- Test push notification delivery
- Load test WebSocket connections

### 4. **Central Platform Integration**
- Implement HTTP callbacks for order status updates
- Add authentication for webhook endpoints
- Configure retry logic for failed notifications

## Monitoring and Logging

### CloudWatch Logs
- `/aws/lambda/order-receiver-dev-merchant-orders-v1-sls`
- `/aws/lambda/order-receiver-dev-websocket-handler-v1-sls`
- API Gateway execution logs

### CloudWatch Metrics
- Lambda invocation counts and errors
- DynamoDB read/write capacity
- WebSocket connection counts
- SNS message delivery rates

## Security Considerations

### IAM Permissions
- Least privilege access for Lambda functions
- Separate roles for different function types
- Resource-specific DynamoDB permissions

### API Security
- AWS IAM authorization for sensitive endpoints
- Rate limiting via API Gateway
- Input validation in Lambda functions

### WebSocket Security
- Connection authentication via query parameters
- Connection lifecycle management
- Automatic cleanup of stale connections

---

**Status:** Infrastructure deployed and ready for configuration
**Last Updated:** August 1, 2025
**Version:** 1.0
