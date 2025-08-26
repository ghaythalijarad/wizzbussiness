#!/bin/zsh

# Quick Fix Deployment Script
# This will help you deploy the registration fix immediately

echo "🚀 URGENT: Deploying Registration Fix"
echo "======================================"

# Check if backend fix is in place
echo "✅ Checking backend fix..."
if grep -q "Name: 'name', Value:" /Users/ghaythallaheebi/order-receiver-app-2/backend/functions/auth/unified_auth_handler.js; then
    echo "✅ Backend fix is in place in the code"
else
    echo "❌ Backend fix missing - this shouldn't happen"
    exit 1
fi

# Test current deployed backend
echo ""
echo "🧪 Testing current deployed backend..."
CURRENT_RESPONSE=$(curl -s -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/register-with-business" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!","businessName":"Test","firstName":"Test","lastName":"User"}')

echo "Current backend response: $CURRENT_RESPONSE"

if echo "$CURRENT_RESPONSE" | grep -q "name.formatted.*required"; then
    echo "❌ Confirmed: Backend needs deployment (still has the bug)"
    echo ""
    echo "🔧 SOLUTION: Deploy the backend fix"
    echo ""
    
    # Check AWS credentials
    echo "🔐 Checking AWS credentials..."
    if aws sts get-caller-identity >/dev/null 2>&1; then
        echo "✅ AWS credentials are working"
        
        # Deploy the fix
        echo ""
        echo "🚀 Deploying backend fix..."
        cd /Users/ghaythallaheebi/order-receiver-app-2/backend
        
        if sam build; then
            echo "✅ Build successful"
            
            if sam deploy; then
                echo "✅ Deployment successful!"
                
                # Test the fix
                echo ""
                echo "🧪 Testing deployed fix..."
                sleep 5  # Give AWS time to propagate
                
                NEW_RESPONSE=$(curl -s -X POST "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev/auth/register-with-business" \
                  -H "Content-Type: application/json" \
                  -d '{"email":"test'$(date +%s)'@example.com","password":"Test123!","businessName":"Test Business","firstName":"Test","lastName":"User","businessType":"restaurant"}')
                
                echo "New backend response: $NEW_RESPONSE"
                
                if echo "$NEW_RESPONSE" | grep -q '"success": true'; then
                    echo ""
                    echo "🎉 SUCCESS! Registration fix is now deployed and working!"
                    echo "✅ Users can now register for business accounts"
                    echo "✅ Verification emails will be sent"
                    echo "✅ Registration button will work in the Flutter app"
                    echo ""
                    echo "🧪 Try the registration in your Flutter app now!"
                else
                    echo "❌ Something went wrong with the deployment"
                    echo "Response: $NEW_RESPONSE"
                fi
            else
                echo "❌ Deployment failed"
                echo ""
                echo "💡 Manual deployment options:"
                echo "1. Try: sam deploy --guided"
                echo "2. Or configure AWS credentials: aws configure"
            fi
        else
            echo "❌ Build failed"
        fi
        
    else
        echo "❌ AWS credentials are not working"
        echo ""
        echo "🔧 Please configure AWS credentials:"
        echo ""
        echo "Option 1 - AWS CLI:"
        echo "  aws configure"
        echo "  # Enter your AWS Access Key ID"
        echo "  # Enter your AWS Secret Access Key"
        echo "  # Region: us-east-1"
        echo ""
        echo "Option 2 - Environment variables:"
        echo "  export AWS_ACCESS_KEY_ID='your-access-key'"
        echo "  export AWS_SECRET_ACCESS_KEY='your-secret-key'"
        echo "  export AWS_DEFAULT_REGION='us-east-1'"
        echo ""
        echo "Then run this script again: ./deploy_fix_now.sh"
    fi
    
elif echo "$CURRENT_RESPONSE" | grep -q '"success": true'; then
    echo "🎉 Great! The fix is already deployed and working!"
    echo "✅ Registration should work in your Flutter app now"
    echo ""
    echo "🧪 If it's still not working in Flutter, check:"
    echo "1. Make sure you're using the latest app build"
    echo "2. Check the Flutter console for debug output"
    echo "3. Try hot restart: 'R' in the Flutter terminal"
    
else
    echo "⚠️ Unexpected response - manual verification needed"
    echo "Response: $CURRENT_RESPONSE"
fi
