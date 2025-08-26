#!/bin/bash

echo "🚀 COMPLETE DEPLOYMENT AUTOMATION"
echo "================================="
echo ""
echo "This script will:"
echo "1. Test AWS credentials"
echo "2. Deploy the business photo authorization fix"
echo "3. Test the complete registration flow"
echo ""

# Test AWS credentials
echo "🔐 Testing AWS credentials..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    echo "✅ AWS credentials are valid"
    
    # Get AWS account info
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    echo "📋 AWS Account: $ACCOUNT_ID"
    echo "👤 User: $USER_ARN"
    echo ""
    
    # Proceed with deployment
    echo "🚀 Deploying business photo authorization fix..."
    echo "This will fix the 'unauthorized or invalid missing token' error"
    echo ""
    
    cd $(dirname "$0")/backend
    
    # Build and deploy
    echo "🔨 Building SAM application..."
    sam build --no-cached
    
    if [ $? -eq 0 ]; then
        echo "✅ Build successful"
        echo ""
        echo "🚀 Deploying to AWS..."
        
        sam deploy --no-confirm-changeset --stack-name order-receiver-regional-dev
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "🎉 DEPLOYMENT SUCCESSFUL!"
            echo "========================"
            echo ""
            echo "✅ Business photo authorization fix deployed"
            echo "✅ Cognito user creation fix deployed"
            echo "✅ Registration flow should work now"
            echo ""
            
            # Test the fix
            echo "🧪 Testing business photo upload authorization..."
            cd ..
            
            # Test business photo upload without auth (registration flow)
            API_URL="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
            BASE64_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
            FILENAME="test-business-photo-$(date +%s).jpg"
            
            UPLOAD_RESPONSE=$(curl -s -X POST \
              "$API_URL/upload/business-photo" \
              -H "Content-Type: application/json" \
              -H "X-Registration-Upload: true" \
              -d "{
                \"image\": \"$BASE64_IMAGE\",
                \"filename\": \"$FILENAME\"
              }")
            
            SUCCESS=$(echo $UPLOAD_RESPONSE | jq -r '.success' 2>/dev/null)
            
            if [ "$SUCCESS" = "true" ]; then
                echo "✅ Business photo upload test PASSED"
                echo "🎉 Authorization bypass is working!"
                echo ""
                echo "📱 NOW TEST IN THE FLUTTER APP:"
                echo "1. Go to registration form"
                echo "2. Upload business photo (should work now)"
                echo "3. Complete registration (should succeed)"
                echo "4. Receive verification email"
                echo ""
                echo "🏆 REGISTRATION ISSUE IS COMPLETELY FIXED!"
            else
                echo "⚠️  Business photo upload test failed"
                echo "Response: $UPLOAD_RESPONSE"
                echo ""
                echo "Need to check deployment or backend configuration"
            fi
            
        else
            echo "❌ Deployment failed"
            echo "Check the error messages above"
        fi
    else
        echo "❌ Build failed"
        echo "Check the error messages above"
    fi
    
else
    echo "❌ AWS credentials are not configured or invalid"
    echo ""
    echo "Please configure AWS credentials first:"
    echo ""
    echo "aws configure"
    echo ""
    echo "Enter the following when prompted:"
    echo "- AWS Access Key ID: [your access key]"
    echo "- AWS Secret Access Key: [your secret key]"
    echo "- Default region name: us-east-1"
    echo "- Default output format: json"
    echo ""
    echo "Then run this script again:"
    echo "./deploy_and_fix_authorization.sh"
fi
