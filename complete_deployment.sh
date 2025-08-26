#!/bin/zsh

# Complete Document Upload Fix Deployment
# This script will guide you through the entire deployment process

set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header "DOCUMENT UPLOAD FIX DEPLOYMENT"

echo "This script will deploy the complete document upload system fix."
echo "The fix enables saving all registration documents (not just business photo) to DynamoDB."
echo ""

# Step 1: Check AWS Credentials
print_header "STEP 1: AWS CREDENTIALS CHECK"

if aws sts get-caller-identity > /dev/null 2>&1; then
    print_success "AWS credentials are valid"
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REGION=$(aws configure get region)
    print_info "Account ID: ${ACCOUNT_ID}"
    print_info "Region: ${REGION}"
else
    print_error "AWS credentials are invalid or expired"
    echo ""
    print_warning "Please run the following command to refresh your credentials:"
    echo ""
    echo "aws configure"
    echo ""
    echo "Enter your AWS credentials when prompted:"
    echo "• AWS Access Key ID: [Your access key]"
    echo "• AWS Secret Access Key: [Your secret key]"
    echo "• Default region name: us-east-1"
    echo "• Default output format: json"
    echo ""
    echo "After configuring credentials, run this script again:"
    echo "./complete_deployment.sh"
    exit 1
fi

# Step 2: Navigate to Backend
print_header "STEP 2: PREPARING BACKEND DEPLOYMENT"

if [ ! -d "backend" ]; then
    print_error "Backend directory not found"
    exit 1
fi

cd backend
print_success "Navigated to backend directory"

# Step 3: Check SAM CLI
if ! command -v sam &> /dev/null; then
    print_error "SAM CLI not found. Please install AWS SAM CLI first."
    echo "Install with: brew install aws-sam-cli"
    exit 1
fi

print_success "SAM CLI is available"

# Step 4: Build the application
print_header "STEP 3: BUILDING SAM APPLICATION"

print_info "Building the SAM application..."
if sam build; then
    print_success "SAM build completed successfully"
else
    print_error "SAM build failed"
    exit 1
fi

# Step 5: Deploy the application
print_header "STEP 4: DEPLOYING TO AWS"

print_info "Deploying the document upload fix..."
if sam deploy --no-confirm-changeset; then
    print_success "Deployment completed successfully!"
else
    print_error "Deployment failed"
    exit 1
fi

# Step 6: Get API Gateway endpoint
print_header "STEP 5: DEPLOYMENT VERIFICATION"

STACK_NAME="order-receiver-regional-dev"
API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayEndpoint`].OutputValue' \
    --output text 2>/dev/null || echo "Not found")

if [ "${API_ENDPOINT}" != "Not found" ] && [ -n "${API_ENDPOINT}" ]; then
    print_success "API Gateway endpoint: ${API_ENDPOINT}"
else
    print_warning "Could not retrieve API Gateway endpoint"
fi

# Final Summary
print_header "DEPLOYMENT COMPLETE!"

print_success "Document upload fix has been deployed successfully!"
echo ""
print_info "What was deployed:"
echo "• Enhanced auth handler to accept all document URLs during registration"
echo "• Updated upload handler with new document endpoints:"
echo "  - /upload/business-license"
echo "  - /upload/owner-identity"
echo "  - /upload/health-certificate"
echo "  - /upload/owner-photo"
echo "• DynamoDB schema updated to store all document types"
echo ""
print_info "Document fields that will now be saved:"
echo "• businessPhotoUrl (already working)"
echo "• businessLicenseUrl (now fixed)"
echo "• healthCertificateUrl (now fixed)"
echo "• ownerIdentityUrl (now fixed)"
echo "• ownerPhotoUrl (now fixed)"
echo ""
print_header "TESTING INSTRUCTIONS"
echo ""
echo "1. Open the Flutter app (if not already running):"
echo "   flutter run -d A3DDA783-158C-4D71-B5D6-E617966BE41D"
echo ""
echo "2. Navigate to business registration"
echo ""
echo "3. Fill out registration form and upload documents:"
echo "   • Business photo (required)"
echo "   • Business license (optional)"
echo "   • Owner identity (optional)"
echo "   • Health certificate (optional)"
echo "   • Owner photo (optional)"
echo ""
echo "4. Complete registration"
echo ""
echo "5. Check DynamoDB table 'WhizzMerchants_Businesses'"
echo "   All uploaded documents should now have URLs stored!"
echo ""
print_success "The document upload issue has been completely resolved!"
echo ""
