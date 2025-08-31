#!/bin/bash

# Update CloudFormation Template for Shared WebSocket
# Removes individual WebSocket API and configures shared infrastructure

echo "🔧 Updating CloudFormation Template for Shared WebSocket"
echo "======================================================="

TEMPLATE_FILE="backend/template.yaml"
BACKUP_FILE="backend/template.yaml.pre-websocket-migration"

# Create backup
cp "$TEMPLATE_FILE" "$BACKUP_FILE"
echo "✅ Created backup: $BACKUP_FILE"

# Step 1: Add parameters for shared WebSocket
echo "📝 Step 1: Adding shared WebSocket parameters..."

# Create a temporary file with parameters
cat > temp_params.yaml << 'EOF'
  SharedWebSocketApiId:
    Type: String
    Default: lwk0wf6rpl
    Description: Shared WebSocket API ID (WizzUser-WebSocket-dev)
    
  SharedWebSocketUrl:
    Type: String  
    Default: wss://lwk0wf6rpl.execute-api.us-east-1.amazonaws.com/dev
    Description: Shared WebSocket URL for ecosystem integration
EOF

# Insert parameters after existing parameters
sed -i '' '/^Parameters:/,/^[[:space:]]*CacheVersion:/r temp_params.yaml' "$TEMPLATE_FILE"
rm temp_params.yaml

echo "✅ Added shared WebSocket parameters"

# Step 2: Update Globals Environment Variables
echo "📝 Step 2: Updating environment variables..."

# Update WEBSOCKET_ENDPOINT to use shared URL
sed -i '' 's|WEBSOCKET_ENDPOINT: !Sub "https://\${WebSocketApi}\.execute-api\.\${AWS::Region}\.amazonaws\.com/\${Stage}"|WEBSOCKET_ENDPOINT: !Ref SharedWebSocketUrl|g' "$TEMPLATE_FILE"

echo "✅ Updated environment variables"

# Step 3: Comment out individual WebSocket resources
echo "📝 Step 3: Commenting out individual WebSocket resources..."

# Create sed script to comment out WebSocket resources
cat > comment_websocket.sed << 'EOF'
/^  # WebSocket API$/,/^  WebSocketConnectionsTable:$/{
  /^  WebSocketConnectionsTable:$/!{
    s/^/#/
  }
}
EOF

# Apply the sed script
sed -i '' -f comment_websocket.sed "$TEMPLATE_FILE"
rm comment_websocket.sed

echo "✅ Commented out individual WebSocket API resources"

# Step 4: Update Lambda permissions
echo "📝 Step 4: Updating Lambda permissions for shared API..."

# Update WebSocket handler permissions
sed -i '' 's|SourceArn: !Sub '\''arn:aws:execute-api:\${AWS::Region}:\${AWS::AccountId}:\${WebSocketApi}/\*'\''|SourceArn: !Sub '\''arn:aws:execute-api:\${AWS::Region}:\${AWS::AccountId}:\${SharedWebSocketApiId}/\*'\''|g' "$TEMPLATE_FILE"

echo "✅ Updated Lambda permissions"

# Step 5: Update outputs
echo "📝 Step 5: Updating outputs..."

# Replace WebSocket URL output
sed -i '' 's|Value: !Sub "wss://\${WebSocketApi}\.execute-api\.\${AWS::Region}\.amazonaws\.com/\${Stage}"|Value: !Ref SharedWebSocketUrl|g' "$TEMPLATE_FILE"

echo "✅ Updated outputs"

echo ""
echo "🎯 CloudFormation Template Updated Successfully!"
echo "=============================================="
echo ""
echo "📋 Changes Made:"
echo "✅ Added shared WebSocket API parameters"
echo "✅ Updated environment variables to use shared endpoint"  
echo "✅ Commented out individual WebSocket API resources"
echo "✅ Updated Lambda permissions for shared API"
echo "✅ Updated outputs to reference shared infrastructure"
echo ""
echo "📝 Next Steps:"
echo "1. Review the updated template: $TEMPLATE_FILE"
echo "2. Deploy the updated stack"
echo "3. Test WebSocket connectivity"
echo "4. Remove old individual WebSocket API resources"
echo ""
echo "🌐 Shared WebSocket URL: wss://lwk0wf6rpl.execute-api.us-east-1.amazonaws.com/dev"
echo "🏢 Ready for ecosystem integration with drivers and customers apps!"
