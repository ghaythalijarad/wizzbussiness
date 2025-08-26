#!/bin/zsh
# FINAL DEPLOYMENT EXECUTION SCRIPT
# Run this after configuring AWS credentials with: aws configure

set -e

echo "🚀 FINAL DEPLOYMENT EXECUTION"
echo "=============================="
echo ""

# Check credentials
echo "✅ Step 1: Verifying AWS credentials..."
if ! aws sts get-caller-identity; then
    echo "❌ AWS credentials not configured"
    echo "Run: aws configure"
    exit 1
fi

echo ""
echo "✅ Step 2: Navigating to backend directory..."
cd /Users/ghaythallaheebi/order-receiver-app-2/backend

echo ""
echo "✅ Step 3: Building SAM application..."
sam build

echo ""
echo "✅ Step 4: Deploying backend changes..."
sam deploy --no-confirm-changeset

echo ""
echo "🎉 DEPLOYMENT COMPLETE!"
echo "======================="
echo ""
echo "✅ Document upload fix deployed successfully!"
echo ""
echo "🎯 What was fixed:"
echo "• Registration now saves ALL document URLs to DynamoDB"
echo "• Backend accepts: businessPhotoUrl, licenseUrl, identityUrl, healthCertificateUrl, ownerPhotoUrl"
echo "• New upload endpoints: /upload/business-license, /upload/owner-identity, /upload/health-certificate, /upload/owner-photo"
echo ""
echo "🧪 Test the fix:"
echo "1. Run Flutter app: flutter run -d A3DDA783-158C-4D71-B5D6-E617966BE41D"
echo "2. Navigate to registration"
echo "3. Upload business photo + additional documents"
echo "4. Complete registration"
echo "5. Check DynamoDB - all documents should be saved!"
echo ""
echo "📊 Expected DynamoDB fields with values:"
echo "• businessPhotoUrl ✅"
echo "• businessLicenseUrl ✅"
echo "• healthCertificateUrl ✅"
echo "• ownerIdentityUrl ✅"
echo "• ownerPhotoUrl ✅"
