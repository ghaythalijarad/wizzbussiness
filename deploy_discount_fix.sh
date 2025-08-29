#!/bin/zsh

echo "🎯 Deploying Discount Management Authorization Fix"
echo "=================================================="

# Check AWS credentials first
echo "🔐 Checking AWS credentials..."
if aws sts get-caller-identity >/dev/null 2>&1; then
    echo "✅ AWS credentials are working"
else
    echo "❌ AWS credentials not configured"
    echo ""
    echo "Please configure AWS credentials:"
    echo "aws configure"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Verify the discount endpoints are in the template
echo ""
echo "✅ Checking CloudFormation template..."
if grep -q "DiscountManagementFunction" /Users/ghaythallaheebi/order-receiver-app-2/backend/template.yaml; then
    echo "✅ Discount management function found in template"
else
    echo "❌ Discount management function missing from template"
    exit 1
fi

if grep -q "/discounts:" /Users/ghaythallaheebi/order-receiver-app-2/backend/template.yaml; then
    echo "✅ Discount endpoints found in template"
else
    echo "❌ Discount endpoints missing from template"
    exit 1
fi

# Deploy the backend changes
echo ""
echo "🚀 Building and deploying backend..."
cd /Users/ghaythallaheebi/order-receiver-app-2/backend

if sam build; then
    echo "✅ Build successful"
    
    if sam deploy --no-confirm-changeset; then
        echo "✅ Deployment successful!"
        
        # Test the discount endpoints
        echo ""
        echo "🧪 Testing discount management endpoints..."
        
        # Get fresh tokens
        AUTH_RESPONSE=$(curl -s -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/signin" \
          -H "Content-Type: application/json" \
          -d '{"email": "g87_a@yahoo.com", "password": "Gha@551987"}')
        
        ID_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.data.IdToken')
        
        if [ "$ID_TOKEN" = "null" ] || [ -z "$ID_TOKEN" ]; then
            echo "⚠️  Could not get ID token for testing"
        else
            echo "✅ Got ID token for testing"
            
            # Test GET discounts
            echo "💰 Testing GET /discounts..."
            RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
              -X GET "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/discounts" \
              -H "Authorization: Bearer $ID_TOKEN" \
              -H "Content-Type: application/json")
            
            HTTP_STATUS=$(echo "$RESPONSE" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
            RESPONSE_BODY=$(echo "$RESPONSE" | sed 's/HTTPSTATUS:[0-9]*$//')
            
            echo "Status: $HTTP_STATUS"
            echo "Response: $RESPONSE_BODY"
            
            if [ "$HTTP_STATUS" = "200" ]; then
                echo "🎉 SUCCESS: Discount management is working!"
                echo "✅ Authorization issue has been fixed"
            elif [ "$HTTP_STATUS" = "403" ]; then
                echo "❌ Still getting 403 - authorization issue persists"
                echo "🔍 Check if endpoints are properly configured"
            else
                echo "ℹ️  HTTP Status: $HTTP_STATUS"
            fi
        fi
        
    else
        echo "❌ Deployment failed"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi

echo ""
echo "🏁 DEPLOYMENT COMPLETE"
echo "======================"
