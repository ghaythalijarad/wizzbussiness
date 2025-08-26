#!/bin/bash

# Script to verify complete registration flow - both Cognito and DynamoDB
echo "🔍 Verifying Complete Registration Flow..."

export AWS_PROFILE=wizz-merchants-dev

if [ -z "$1" ]; then
    echo "Usage: $0 <email_address>"
    echo "Example: $0 test.user@example.com"
    exit 1
fi

EMAIL="$1"
echo "📧 Checking registration for email: $EMAIL"

echo ""
echo "1️⃣ Checking Cognito User Pool..."
COGNITO_USER=$(aws cognito-idp admin-get-user \
    --user-pool-id us-east-1_PHPkG78b5 \
    --username "$EMAIL" \
    --region us-east-1 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ User found in Cognito"
    USER_SUB=$(echo "$COGNITO_USER" | jq -r '.Username')
    USER_STATUS=$(echo "$COGNITO_USER" | jq -r '.UserStatus')
    echo "   User ID: $USER_SUB"
    echo "   Status: $USER_STATUS"
else
    echo "❌ User NOT found in Cognito"
    exit 1
fi

echo ""
echo "2️⃣ Checking DynamoDB Business Table..."
BUSINESS_RECORD=$(aws dynamodb scan \
    --table-name WhizzMerchants_Businesses \
    --filter-expression "email = :email" \
    --expression-attribute-values "{\":email\":{\"S\":\"$EMAIL\"}}" \
    --region us-east-1 2>/dev/null)

BUSINESS_COUNT=$(echo "$BUSINESS_RECORD" | jq '.Count')
if [ "$BUSINESS_COUNT" -gt 0 ]; then
    echo "✅ Business record found in DynamoDB"
    BUSINESS_ID=$(echo "$BUSINESS_RECORD" | jq -r '.Items[0].businessId.S')
    BUSINESS_NAME=$(echo "$BUSINESS_RECORD" | jq -r '.Items[0].businessName.S')
    BUSINESS_STATUS=$(echo "$BUSINESS_RECORD" | jq -r '.Items[0].status.S')
    echo "   Business ID: $BUSINESS_ID"
    echo "   Business Name: $BUSINESS_NAME"
    echo "   Status: $BUSINESS_STATUS"
else
    echo "❌ Business record NOT found in DynamoDB"
    exit 1
fi

echo ""
echo "3️⃣ Checking DynamoDB Users Table (optional)..."
USER_RECORD=$(aws dynamodb scan \
    --table-name WhizzMerchants_Users \
    --filter-expression "email = :email" \
    --expression-attribute-values "{\":email\":{\"S\":\"$EMAIL\"}}" \
    --region us-east-1 2>/dev/null)

USER_COUNT=$(echo "$USER_RECORD" | jq '.Count' 2>/dev/null || echo "0")
if [ "$USER_COUNT" -gt 0 ]; then
    echo "✅ User record found in DynamoDB Users table"
    USER_TYPE=$(echo "$USER_RECORD" | jq -r '.Items[0].userType.S // "N/A"')
    echo "   User Type: $USER_TYPE"
else
    echo "ℹ️  User record not found in DynamoDB Users table (this is optional)"
fi

echo ""
echo "🎉 REGISTRATION VERIFICATION COMPLETE!"
echo "Summary:"
echo "- Cognito User: ✅ Created"
echo "- DynamoDB Business: ✅ Created" 
echo "- DynamoDB User: ℹ️  Optional"
echo ""
echo "✅ Registration flow is working correctly!"
