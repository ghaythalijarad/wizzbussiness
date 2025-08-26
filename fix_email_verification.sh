#!/bin/bash

echo "📧 FIXING EMAIL VERIFICATION CONFIGURATION"
echo "=========================================="
echo ""

USER_POOL_ID="us-east-1_PHPkG78b5"
PROFILE="wizz-merchants-dev"

echo "🔍 Current configuration:"
echo "- AutoVerifiedAttributes: email, phone_number"
echo "- UsernameAttributes: email, phone_number"
echo "- EmailConfiguration: COGNITO_DEFAULT"
echo "- SmsConfiguration: Enabled with SNS role"
echo ""
echo "💡 Solution: Update to use only email verification"
echo ""

# Method 1: Try to update User Pool to email-only verification
echo "1️⃣ Attempting to update User Pool for email-only verification..."

UPDATE_RESPONSE=$(aws cognito-idp update-user-pool \
  --user-pool-id $USER_POOL_ID \
  --profile $PROFILE \
  --auto-verified-attributes email \
  --username-attributes email \
  --policies '{
    "PasswordPolicy": {
      "MinimumLength": 8,
      "RequireUppercase": true,
      "RequireLowercase": true,
      "RequireNumbers": true,
      "RequireSymbols": true,
      "TemporaryPasswordValidityDays": 7
    }
  }' \
  --mfa-configuration OFF 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ User Pool updated successfully!"
    echo ""
    echo "🔍 Verifying new configuration..."
    
    aws cognito-idp describe-user-pool \
      --user-pool-id $USER_POOL_ID \
      --profile $PROFILE \
      --query 'UserPool.{AutoVerifiedAttributes:AutoVerifiedAttributes,UsernameAttributes:UsernameAttributes}' \
      --output json
    
    echo ""
    echo "🧪 Testing email verification..."
    
    # Test with a new email to see if it uses email verification
    TEST_EMAIL="test-email-verification-$(date +%s)@gmail.com"
    echo "Testing registration with: $TEST_EMAIL"
    
    REGISTER_RESPONSE=$(curl -s -X POST \
      "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/register-with-business" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"TestPass123!\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"businessName\": \"Test Business $(date +%s)\",
        \"businessType\": \"restaurant\",
        \"phoneNumber\": \"+1234567890\"
      }")
    
    echo "Registration response: $REGISTER_RESPONSE"
    
    # Check delivery method
    DELIVERY_MEDIUM=$(echo $REGISTER_RESPONSE | jq -r '.code_delivery_details.DeliveryMedium' 2>/dev/null)
    
    if [ "$DELIVERY_MEDIUM" = "EMAIL" ]; then
        echo "✅ SUCCESS: Verification code sent via EMAIL!"
        echo ""
        echo "🎉 Email verification is now working!"
        echo ""
        echo "📧 Now test with your email:"
        echo "curl -s -X POST 'https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/resend-code' \\"
        echo "  -H 'Content-Type: application/json' \\"
        echo "  -d '{\"email\": \"write2ghayth@gmail.com\"}'"
        
    else
        echo "⚠️  Still using: $DELIVERY_MEDIUM"
        echo "May need additional configuration or user-specific settings"
    fi
    
else
    echo "❌ Failed to update User Pool:"
    echo "$UPDATE_RESPONSE"
    echo ""
    echo "🔧 Alternative solutions:"
    echo "1. Update via AWS Console"
    echo "2. Delete and recreate user account"
    echo "3. Use different email for registration"
fi

echo ""
echo "🏁 Email verification fix completed"
