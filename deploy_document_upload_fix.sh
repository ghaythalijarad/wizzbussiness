#!/bin/bash

# Document Upload Fix Deployment Script
# This script completes the deployment of the registration document upload system

set -e

echo "🚀 Document Upload Fix Deployment Script"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Checking AWS credentials...${NC}"
if aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${GREEN}✅ AWS credentials are valid${NC}"
    aws sts get-caller-identity
else
    echo -e "${RED}❌ AWS credentials are invalid or expired${NC}"
    echo ""
    echo "Please run: aws configure"
    echo "Enter your AWS credentials:"
    echo "- AWS Access Key ID: [Your access key]"
    echo "- AWS Secret Access Key: [Your secret key]"
    echo "- Default region: us-east-1"
    echo "- Default output format: json"
    echo ""
    echo "After configuring credentials, run this script again."
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 2: Navigating to backend directory...${NC}"
cd /Users/ghaythallaheebi/order-receiver-app-2/backend

echo ""
echo -e "${YELLOW}Step 3: Building SAM application...${NC}"
sam build

echo ""
echo -e "${YELLOW}Step 4: Deploying backend changes...${NC}"
sam deploy --no-confirm-changeset

echo ""
echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo ""
echo "🎯 What was deployed:"
echo "- Enhanced auth handler to accept all document URLs"
echo "- Updated upload handler with document endpoints"
echo "- DynamoDB schema updated to store all document types"
echo ""
echo "📋 Test the fix:"
echo "1. Open Flutter app"
echo "2. Go to registration"
echo "3. Upload business photo + additional documents"
echo "4. Complete registration"
echo "5. Check DynamoDB - all document URLs should be saved!"
echo ""
echo "🔍 Check results in DynamoDB table: WhizzMerchants_Businesses"
echo "Fields that should now have values:"
echo "- businessPhotoUrl"
echo "- businessLicenseUrl"
echo "- healthCertificateUrl"  
echo "- ownerIdentityUrl"
echo "- ownerPhotoUrl"
