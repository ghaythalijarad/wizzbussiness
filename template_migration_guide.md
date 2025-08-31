# CloudFormation Template Changes for Shared WebSocket Migration

## Changes Required in template.yaml

### 1. Add Parameters Section
Add these parameters to reference the shared WebSocket infrastructure:

```yaml
Parameters:
  # ... existing parameters ...
  
  SharedWebSocketApiId:
    Type: String
    Default: lwk0wf6rpl
    Description: Shared WebSocket API ID (WizzUser-WebSocket-dev)
    
  SharedWebSocketUrl:
    Type: String  
    Default: wss://lwk0wf6rpl.execute-api.us-east-1.amazonaws.com/dev
    Description: Shared WebSocket URL
```

### 2. Update Lambda Environment Variables
Update the Globals section to use shared WebSocket endpoint:

```yaml
Globals:
  Function:
    Environment:
      Variables:
        # ... existing variables ...
        WEBSOCKET_ENDPOINT: !Ref SharedWebSocketUrl
        SHARED_WEBSOCKET_API_ID: !Ref SharedWebSocketApiId
```

### 3. Remove Individual WebSocket Resources
Comment out or remove these resources (lines ~1755-1830):
- WebSocketApi
- WebSocketConnectRoute  
- WebSocketDisconnectRoute
- WebSocketDefaultRoute
- WebSocketConnectIntegration
- WebSocketDisconnectIntegration
- WebSocketDefaultIntegration
- WebSocketDeployment
- WebSocketStage
- WebSocketConnectionsTable (if creating individual table)

### 4. Update Lambda Permissions
Replace WebSocket API permissions with shared API permissions:

```yaml
WebSocketHandlerInvokePermission:
  Type: AWS::Lambda::Permission
  Properties:
    Action: lambda:InvokeFunction
    FunctionName: !Ref WebSocketHandlerFunction
    Principal: apigateway.amazonaws.com
    SourceArn: !Sub 'arn:aws:execute-api:${AWS::Region}:${AWS::AccountId}:${SharedWebSocketApiId}/*'
```

### 5. Update Outputs Section
Replace individual WebSocket outputs with shared references:

```yaml
Outputs:
  # ... existing outputs ...
  
  SharedWebSocketUrl:
    Description: "Shared WebSocket URL for ecosystem"
    Value: !Ref SharedWebSocketUrl
    Export:
      Name: !Sub "${AWS::StackName}-SharedWebSocketUrl"
      
  SharedWebSocketApiId:
    Description: "Shared WebSocket API ID"  
    Value: !Ref SharedWebSocketApiId
    Export:
      Name: !Sub "${AWS::StackName}-SharedWebSocketApiId"
```

## Migration Benefits

✅ **Ecosystem Integration**: Connect with drivers and customers apps  
✅ **Unified Infrastructure**: Single WebSocket API for all apps  
✅ **Cost Reduction**: No duplicate AWS resources  
✅ **Cross-App Communication**: Enable real-time messaging between apps  
✅ **Simplified Management**: One WebSocket infrastructure to maintain
