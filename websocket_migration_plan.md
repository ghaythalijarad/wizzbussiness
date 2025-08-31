# WebSocket Migration to Shared Infrastructure

## Current Issue
Your order receiver app is using its own WebSocket API instead of the shared `WizzUser-WebSocket-dev` infrastructure used across your ecosystem.

## Current Architecture
```
Order Receiver App (Individual):
├── WebSocket API: order-receiver-websocket-api-dev
├── WebSocket URL: wss://pyc140yn0h.execute-api.us-east-1.amazonaws.com/dev
├── Table: order-receiver-websocket-connections-dev
└── Isolated from drivers app and customers app
```

## Target Architecture (Shared)
```
Ecosystem (Shared):
├── WebSocket API: WizzUser-WebSocket-dev
├── WebSocket URL: wss://[shared-api-id].execute-api.us-east-1.amazonaws.com/dev
├── Tables: WizzUser_websocket_connections_dev
├── Tables: WizzUser_websocket_subscriptions_dev
├── Used by: Drivers App ✅
├── Used by: Customers App ✅
└── Used by: Order Receiver App ❌ → ✅
```

## Migration Steps

### Step 1: Get Shared WebSocket API Details
```bash
# Find the shared WebSocket API ID
aws apigatewayv2 get-apis --query 'Items[?Name==`WizzUser-WebSocket-dev`]' --profile wizz-merchants-dev --region us-east-1

# Get the WebSocket URL
aws apigatewayv2 get-apis --query 'Items[?Name==`WizzUser-WebSocket-dev`].{ApiId:ApiId,Name:Name}' --profile wizz-merchants-dev --region us-east-1 --output table
```

### Step 2: Update CloudFormation Template
- Remove individual WebSocket API creation
- Remove individual WebSocket table creation  
- Update Lambda environment variables to use shared resources
- Configure Lambda permissions for shared WebSocket API

### Step 3: Update Lambda Functions
- Modify WebSocket handler to work with shared API
- Update connection routing logic for multi-app ecosystem
- Ensure proper entity type handling (merchant vs driver vs customer)

### Step 4: Update Flutter App
- Change WebSocket connection URL to shared endpoint
- Update connection parameters for ecosystem compatibility
- Test WebSocket functionality with shared infrastructure

### Step 5: Migration Deployment
- Deploy updated backend configuration
- Test WebSocket connectivity
- Verify real-time messaging works
- Clean up old individual resources

## Benefits After Migration
✅ **Unified Communication**: All apps use same WebSocket infrastructure  
✅ **Cross-App Messaging**: Enable communication between drivers, customers, and merchants  
✅ **Reduced Infrastructure**: No duplicate WebSocket APIs  
✅ **Ecosystem Integration**: Full compatibility with drivers and customers apps  
✅ **Cost Optimization**: Shared resources reduce AWS costs  

## Next Steps
1. Run discovery script to find shared WebSocket API details
2. Update CloudFormation template
3. Test migration in development environment
4. Deploy to production once verified
