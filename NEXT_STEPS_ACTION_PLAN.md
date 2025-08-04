# Next Steps Action Plan

## Immediate Actions (High Priority)

### 1. **Fix Merchant Handler Issue** 🔥
**Problem:** `functions/orders/merchant_order_handler.handler is undefined or not exported`
**Solutions to try:**
- Check webpack configuration
- Verify file integrity and exports
- Test with simplified handler
- Check serverless.yml handler path

### 2. **Configure Push Notification Credentials** 📱
**Required:**
- Firebase Cloud Messaging (FCM) server key for Android
- Apple Push Notification Service (APNS) certificate/key for iOS

**Steps:**
```bash
# Get your FCM server key from Firebase Console
# Update FCM platform application
aws sns set-platform-application-attributes \
  --platform-application-arn $(aws cloudformation describe-stacks \
    --stack-name order-receiver-api-dev \
    --query 'Stacks[0].Outputs[?OutputKey==`FCMPlatformApplicationArn`].OutputValue' \
    --output text) \
  --attributes PlatformCredential=YOUR_ACTUAL_FCM_SERVER_KEY

# Get your APNS certificate from Apple Developer Console  
# Update APNS platform application
aws sns set-platform-application-attributes \
  --platform-application-arn $(aws cloudformation describe-stacks \
    --stack-name order-receiver-api-dev \
    --query 'Stacks[0].Outputs[?OutputKey==`APNSPlatformApplicationArn`].OutputValue' \
    --output text) \
  --attributes PlatformCredential=YOUR_APNS_CERTIFICATE,PlatformPrincipal=YOUR_APNS_PRIVATE_KEY
```

### 3. **Update WebSocket Endpoint** 🔌
**Current:** Placeholder URL in environment variables
**Action:** Get actual WebSocket API ID after deployment and update

## Testing Phase

### 1. **Basic Endpoint Testing**
```bash
# Test health endpoint
curl https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/auth/health

# Test merchant endpoints (after fixing handler)
curl -X GET "https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/merchant/orders/test-business-123"
```

### 2. **WebSocket Testing**
```javascript
// Connect to WebSocket
const ws = new WebSocket('wss://YOUR_WEBSOCKET_API_ID.execute-api.us-east-1.amazonaws.com/dev?merchantId=test-merchant-123');

ws.onopen = () => console.log('Connected');
ws.onmessage = (event) => console.log('Message:', JSON.parse(event.data));
```

### 3. **Push Notification Testing**
```bash
# Register device token
curl -X POST "https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/merchants/test-merchant-123/device-token" \
  -H "Content-Type: application/json" \
  -d '{"deviceToken": "test-fcm-token", "platform": "android"}'
```

## Integration Phase

### 1. **Central Platform Integration**
- Implement webhook endpoint authentication
- Add retry logic for failed callbacks
- Create order status update callbacks

### 2. **Mobile App Integration**
- FCM/APNS token registration
- WebSocket connection management
- Real-time notification handling

### 3. **Web Dashboard Integration**
- WebSocket connection for browser clients
- Real-time order status updates
- Push notification fallback

## Monitoring Setup

### 1. **CloudWatch Alarms**
```bash
# Lambda error rates
# DynamoDB throttling
# WebSocket connection failures
# SNS delivery failures
```

### 2. **Log Analysis**
- Set up log insights queries
- Error pattern detection
- Performance monitoring

## Production Readiness

### 1. **Security Hardening**
- API rate limiting
- Input validation
- Authentication improvements

### 2. **Performance Optimization**
- DynamoDB capacity planning
- Lambda cold start optimization
- WebSocket connection pooling

### 3. **Disaster Recovery**
- Backup strategies
- Multi-region deployment
- Failover procedures

---

## Quick Commands Reference

```bash
# Deploy infrastructure
cd backend && npx serverless deploy --stage dev --region us-east-1

# Deploy single function
npx serverless deploy function -f merchantOrderManagement --stage dev

# Check logs
npx serverless logs -f merchantOrderManagement --tail

# Get stack outputs
aws cloudformation describe-stacks --stack-name order-receiver-api-dev \
  --query 'Stacks[0].Outputs'

# Test endpoint
curl -X GET "https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev/auth/health"
```

**Priority Order:**
1. Fix merchant handler exports issue
2. Configure push notification credentials  
3. Test all endpoints
4. Set up monitoring
5. Integration testing
6. Production deployment
