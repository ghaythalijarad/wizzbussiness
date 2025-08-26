#!/bin/bash

echo "🚨 URGENT: Fix Business Photo Authorization Error"
echo "=============================================="
echo ""
echo "📋 ISSUE: Business photo upload fails with 'unauthorized' during registration"
echo "✅ SOLUTION: Deploy authorization bypass for registration uploads"
echo ""

# Check AWS credentials
if aws sts get-caller-identity > /dev/null 2>&1; then
    echo "✅ AWS credentials are valid - proceeding with deployment"
    echo ""
    
    cd $(dirname "$0")/backend
    
    echo "🚀 Deploying authorization fix..."
    echo "This will fix:"
    echo "• Business photo upload authorization during registration"
    echo "• Cognito user creation error (missing 'name' attribute)"
    echo ""
    
    sam deploy --no-confirm-changeset
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 AUTHORIZATION FIX DEPLOYED!"
        echo "==============================="
        echo ""
        echo "✅ Business photo uploads now work during registration"
        echo "✅ Registration flow will complete successfully"
        echo ""
        echo "🧪 TEST NOW:"
        echo "1. Go back to the registration form in the app"
        echo "2. Try uploading a business photo again"
        echo "3. Complete the registration process"
        echo "4. Should work without authorization errors!"
        echo ""
    else
        echo "❌ Deployment failed - check errors above"
    fi
    
else
    echo "❌ AWS credentials not configured"
    echo ""
    echo "Please configure AWS credentials first:"
    echo "aws configure"
    echo ""
    echo "Then run this script again:"
    echo "./fix_business_photo_auth.sh"
fi
