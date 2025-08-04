#!/bin/bash

# Script to update AWS SDK v3 operations in unified_auth_handler.js
cd /Users/ghaythallaheebi/order-receiver-app-2/backend/functions/auth

echo "🔄 Updating unified_auth_handler.js for AWS SDK v3..."

# Backup the original file
cp unified_auth_handler.js unified_auth_handler.js.backup

# Replace AWS client instantiations that weren't caught
sed -i '' 's/new AWS\.CognitoIdentityServiceProvider/new CognitoIdentityServiceProvider/g' unified_auth_handler.js
sed -i '' 's/new AWS\.DynamoDB\.DocumentClient({ region: process\.env\.COGNITO_REGION || '\''us-east-1'\'' })/DynamoDBDocumentClient.from(new DynamoDBClient({ region: process.env.COGNITO_REGION || '\''us-east-1'\'' }))/g' unified_auth_handler.js
sed -i '' 's/new AWS\.DynamoDB\.DocumentClient({ region: process\.env\.DYNAMODB_REGION || '\''us-east-1'\'' })/DynamoDBDocumentClient.from(new DynamoDBClient({ region: process.env.DYNAMODB_REGION || '\''us-east-1'\'' }))/g' unified_auth_handler.js

# Replace DynamoDB operations
sed -i '' 's/await dynamodb\.put(/await dynamodb.send(new PutCommand(/g' unified_auth_handler.js
sed -i '' 's/await dynamodb\.get(/await dynamodb.send(new GetCommand(/g' unified_auth_handler.js
sed -i '' 's/await dynamodb\.update(/await dynamodb.send(new UpdateCommand(/g' unified_auth_handler.js
sed -i '' 's/await dynamodb\.query(/await dynamodb.send(new QueryCommand(/g' unified_auth_handler.js
sed -i '' 's/await dynamodb\.scan(/await dynamodb.send(new ScanCommand(/g' unified_auth_handler.js
sed -i '' 's/await dynamodb\.delete(/await dynamodb.send(new DeleteCommand(/g' unified_auth_handler.js

# Replace Cognito operations 
sed -i '' 's/await cognito\.signUp(/await cognito.signUp(/g' unified_auth_handler.js
sed -i '' 's/await cognito\.confirmSignUp(/await cognito.confirmSignUp(/g' unified_auth_handler.js
sed -i '' 's/await cognito\.adminUpdateUserAttributes(/await cognito.adminUpdateUserAttributes(/g' unified_auth_handler.js
sed -i '' 's/await cognito\.adminGetUser(/await cognito.adminGetUser(/g' unified_auth_handler.js
sed -i '' 's/await cognito\.initiateAuth(/await cognito.initiateAuth(/g' unified_auth_handler.js
sed -i '' 's/await cognito\.resendConfirmationCode(/await cognito.resendConfirmationCode(/g' unified_auth_handler.js
sed -i '' 's/await cognito\.getUser(/await cognito.getUser(/g' unified_auth_handler.js
sed -i '' 's/await cognito\.adminDeleteUser(/await cognito.adminDeleteUser(/g' unified_auth_handler.js

# Remove .promise() calls
sed -i '' 's/\.promise()//g' unified_auth_handler.js

# Fix DynamoDB command calls - add closing parentheses
sed -i '' 's/await dynamodb\.send(new PutCommand({/await dynamodb.send(new PutCommand({/g' unified_auth_handler.js
sed -i '' 's/}).promise()/}))/g' unified_auth_handler.js

echo "✅ Updated unified_auth_handler.js for AWS SDK v3"
echo "📁 Backup saved as unified_auth_handler.js.backup"
