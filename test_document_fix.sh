#!/bin/zsh

# Test Document Upload Fix After Deployment
echo "🧪 Testing Document Upload Fix"
echo "=============================="
echo ""

# Test the registration endpoint to see if it accepts all document parameters
echo "Testing registration endpoint with all document parameters..."
echo ""

API_ENDPOINT="https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"

curl -X POST "${API_ENDPOINT}/auth/register-with-business" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test.documents.'"$(date +%s)"'@example.com",
    "password": "TestPassword123!",
    "businessName": "Test Document Upload Business",
    "firstName": "Test",
    "lastName": "User",
    "businessType": "restaurant",
    "phoneNumber": "+9647801234567",
    "address": {
      "street": "Test Street",
      "city": "Baghdad",
      "district": "Karrada",
      "country": "Iraq"
    },
    "businessPhotoUrl": "https://example.com/business-photo.jpg",
    "licenseUrl": "https://example.com/business-license.jpg",
    "identityUrl": "https://example.com/owner-identity.jpg", 
    "healthCertificateUrl": "https://example.com/health-certificate.jpg",
    "ownerPhotoUrl": "https://example.com/owner-photo.jpg"
  }' | jq '.' || echo "Response received (jq not available for formatting)"

echo ""
echo "✅ Test completed!"
echo ""
echo "If the registration was successful, check DynamoDB table 'WhizzMerchants_Businesses'"
echo "The business record should now contain all document URLs:"
echo "• businessPhotoUrl"
echo "• businessLicenseUrl" 
echo "• healthCertificateUrl"
echo "• ownerIdentityUrl"
echo "• ownerPhotoUrl"
