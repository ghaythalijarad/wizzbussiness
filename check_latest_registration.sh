#!/bin/bash

echo "🔍 Checking latest business registration in DynamoDB..."

# Get the latest business record from DynamoDB
aws dynamodb scan \
  --table-name wizz-merchants-dev-businesses \
  --projection-expression "businessId, businessName, businessPhotoUrl, licenseUrl, identityUrl, healthCertificateUrl, ownerPhotoUrl, createdAt" \
  --profile wizz-merchants-dev \
  --region us-east-1 \
  --output json | jq -r '.Items | sort_by(.createdAt.S) | reverse | .[0] | 
  "
📊 LATEST BUSINESS REGISTRATION:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Business ID: \(.businessId.S // "N/A")
Business Name: \(.businessName.S // "N/A")
Created At: \(.createdAt.S // "N/A")

📋 DOCUMENT URLS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏢 Business Photo: \(.businessPhotoUrl.S // "❌ NULL")
📄 License: \(.licenseUrl.S // "❌ NULL") 
🆔 Owner Identity: \(.identityUrl.S // "❌ NULL")
🏥 Health Certificate: \(.healthCertificateUrl.S // "❌ NULL")
👤 Owner Photo: \(.ownerPhotoUrl.S // "❌ NULL")
"'

echo ""
echo "✅ Use the Flutter app to register with documents, then run this script again to verify!"
