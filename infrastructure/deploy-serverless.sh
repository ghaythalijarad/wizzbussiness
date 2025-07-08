#!/bin/bash

# AWS Serverless Deployment Script for Order Receiver Application
# Using AWS SAM (Serverless Application Model)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="order-receiver"
AWS_REGION="eu-north-1"
BACKEND_DIR="../backend"
FRONTEND_DIR="../frontend"
STACK_NAME="${PROJECT_NAME}-serverless"
DYNAMODB_TABLE_NAME="order-receiver-data"

echo -e "${BLUE}🚀 Starting Serverless AWS deployment for Order Receiver Application${NC}"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    exit 1
fi

if ! command -v sam &> /dev/null; then
    echo -e "${YELLOW}⚠️  AWS SAM CLI not found. Installing...${NC}"
    if command -v brew &> /dev/null; then
        brew install aws-sam-cli
    else
        echo -e "${RED}❌ Please install AWS SAM CLI: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html${NC}"
        exit 1
    fi
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed (required for SAM)${NC}"
    exit 1
fi

# Check AWS credentials
echo -e "${YELLOW}🔑 Verifying AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ AWS Account: ${AWS_ACCOUNT_ID}${NC}"

# Get deployment parameters
if [ ! -f "samconfig.toml" ]; then
    echo -e "${YELLOW}📝 Creating SAM configuration...${NC}"
    
    # Generate secret key
    SECRET_KEY=$(openssl rand -base64 32)
    
    # Create samconfig.toml
    cat > samconfig.toml << EOF
version = 0.1
[default]
[default.deploy]
[default.deploy.parameters]
stack_name = "${STACK_NAME}"
s3_bucket = "${STACK_NAME}-sam-artifacts-${AWS_ACCOUNT_ID}"
s3_prefix = "artifacts"
region = "${AWS_REGION}"
capabilities = "CAPABILITY_IAM"
parameter_overrides = [
    "Environment=dev",
    "SecretKey=${SECRET_KEY}",
    "CorsOrigins=*",
    "DynamoDBTableName=${DYNAMODB_TABLE_NAME}"
]
confirm_changeset = false
disable_rollback = false

[default.build]
[default.build.parameters]
parallel = true
EOF
    
    echo -e "${GREEN}✅ SAM configuration created${NC}"
fi

# Create S3 bucket for SAM artifacts if it doesn't exist
SAM_BUCKET="${STACK_NAME}-sam-artifacts-${AWS_ACCOUNT_ID}"
if ! aws s3 ls "s3://${SAM_BUCKET}" 2>/dev/null; then
    echo -e "${YELLOW}📦 Creating S3 bucket for SAM artifacts...${NC}"
    aws s3 mb "s3://${SAM_BUCKET}" --region ${AWS_REGION}
fi

# Copy backend application code to Lambda function directory
echo -e "${YELLOW}📋 Preparing Lambda function code...${NC}"

# Copy main application code
rm -rf lambda/api/app
cp -r ${BACKEND_DIR}/app lambda/api/

# Create __init__.py files if they don't exist
find lambda/api/app -type d -exec touch {}/__init__.py \;

# Build Lambda Layer for dependencies
echo -e "${YELLOW}🔨 Building Lambda Layer...${NC}"

# Create layer structure
mkdir -p layers/dependencies/python/lib/python3.11/site-packages

# Install dependencies to layer
pip install -r layers/dependencies/requirements.txt -t layers/dependencies/python/lib/python3.11/site-packages/

# Remove unnecessary files to reduce size
find layers/dependencies/python/lib/python3.11/site-packages/ -name "*.pyc" -delete
find layers/dependencies/python/lib/python3.11/site-packages/ -name "__pycache__" -type d -exec rm -rf {} +
find layers/dependencies/python/lib/python3.11/site-packages/ -name "*.so" -exec strip {} \;

# Build the SAM application
echo -e "${YELLOW}🔨 Building SAM application...${NC}"
sam build

# Deploy the application
echo -e "${YELLOW}🚀 Deploying to AWS...${NC}"
sam deploy

# Get outputs
echo -e "${YELLOW}📊 Getting deployment outputs...${NC}"
API_URL=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' --output text)
FRONTEND_URL=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`FrontendUrl`].OutputValue' --output text)
S3_BUCKET=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' --output text)

echo -e "${GREEN}✅ Serverless deployment completed successfully!${NC}"
echo -e "${BLUE}📝 Deployment Information:${NC}"
echo -e "${BLUE}   API Gateway URL: ${API_URL}${NC}"
echo -e "${BLUE}   Frontend URL: ${FRONTEND_URL}${NC}"
echo -e "${BLUE}   S3 Bucket: ${S3_BUCKET}${NC}"

# Run database migrations
echo -e "${YELLOW}🗄️  Running database migrations...${NC}"
if [ -f "${BACKEND_DIR}/alembic.ini" ]; then
    # Update database URL in environment
    export DATABASE_URL=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' --output text)
    export DATABASE_URL="postgresql://orderadmin:${DATABASE_PASSWORD}@${DATABASE_URL}:5432/order_receiver"
    
    cd ${BACKEND_DIR}
    # Install alembic if not already installed
    pip install alembic
    alembic upgrade head
    cd ../infrastructure
    
    echo -e "${GREEN}✅ Database migrations completed${NC}"
else
    echo -e "${YELLOW}⚠️  No Alembic configuration found. Skipping migrations.${NC}"
fi

# Deploy frontend if build exists
if [ -d "${FRONTEND_DIR}/build/web" ]; then
    echo -e "${YELLOW}📱 Deploying frontend to S3...${NC}"
    
    # Sync files to S3
    aws s3 sync ${FRONTEND_DIR}/build/web s3://${S3_BUCKET}/ --delete
    
    # Invalidate CloudFront cache
    DISTRIBUTION_ID=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --query 'Stacks[0].Resources[?ResourceType==`AWS::CloudFront::Distribution`].PhysicalResourceId' --output text)
    if [ ! -z "$DISTRIBUTION_ID" ]; then
        aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths "/*"
    fi
    
    echo -e "${GREEN}✅ Frontend deployed successfully!${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend build not found. Run 'flutter build web' in the frontend directory first.${NC}"
fi

# Test the deployment
echo -e "${YELLOW}🧪 Testing deployment...${NC}"
if curl -s -o /dev/null -w "%{http_code}" "${API_URL}/health" | grep -q "200"; then
    echo -e "${GREEN}✅ API health check passed!${NC}"
else
    echo -e "${YELLOW}⚠️  API health check failed. The deployment may still be initializing.${NC}"
fi

echo -e "${GREEN}🎉 Serverless deployment completed!${NC}"
echo -e "${BLUE}📱 Access your application:${NC}"
echo -e "${BLUE}   API: ${API_URL}${NC}"
echo -e "${BLUE}   Frontend: ${FRONTEND_URL}${NC}"
echo -e "${BLUE}   API Docs: ${API_URL}/docs${NC}"

echo -e "${YELLOW}⏳ Note: Lambda cold starts may cause initial requests to be slower.${NC}"
echo -e "${YELLOW}💡 Consider setting up custom domain names for production use.${NC}"
