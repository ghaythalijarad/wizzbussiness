#!/bin/bash

# Quick deployment script for testing business registration endpoint
# This creates a simple Lambda function for testing without full SAM deployment

echo "🚀 Quick AWS Lambda Deployment for Business Registration Testing"

# Function name
FUNCTION_NAME="hadhir-business-registration-test"
ROLE_NAME="hadhir-lambda-role-test"

# Check if Lambda function already exists
if aws lambda get-function --function-name $FUNCTION_NAME >/dev/null 2>&1; then
    echo "✅ Lambda function $FUNCTION_NAME already exists"
    
    # Get the function URL
    FUNCTION_URL=$(aws lambda get-function-url-config --function-name $FUNCTION_NAME --query 'FunctionUrl' --output text 2>/dev/null || echo "")
    
    if [ -n "$FUNCTION_URL" ]; then
        echo "🌐 Function URL: $FUNCTION_URL"
        echo ""
        echo "📝 Test the business registration endpoint:"
        echo "POST $FUNCTION_URL/auth/register-business"
        echo ""
        echo "📋 Test payload:"
        cat << 'EOF'
{
  "cognito_user_id": "test-user-123",
  "email": "test@example.com",
  "business_name": "Test Restaurant",
  "business_type": "restaurant",
  "owner_name": "Test Owner",
  "phone_number": "+9641234567890",
  "address": {
    "city": "Baghdad",
    "district": "Karrada",
    "country": "Iraq"
  }
}
EOF
    else
        echo "❌ Function URL not configured"
    fi
else
    echo "❌ Lambda function $FUNCTION_NAME not found"
    echo "💡 Would you like to create it? This will require:"
    echo "  1. Creating IAM role"
    echo "  2. Packaging Lambda function"
    echo "  3. Creating Lambda function"
    echo "  4. Setting up function URL"
fi
