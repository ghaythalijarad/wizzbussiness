#!/bin/bash

# Serverless deployment script for local development
# Usage: ./deploy-serverless.sh [environment] [stack-name]

set -e

ENVIRONMENT=${1:-dev}
STACK_NAME=${2:-order-receiver-serverless-$ENVIRONMENT}
AWS_REGION=${AWS_REGION:-us-east-1}

echo "🚀 Deploying serverless stack: $STACK_NAME to $ENVIRONMENT"

# Navigate to backend directory
cd "$(dirname "$0")/../backend"

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    echo "❌ SAM CLI not found. Please install it first:"
    echo "   brew install aws-sam-cli"
    echo "   or visit: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
    exit 1
fi

# Check AWS credentials
echo "🔍 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run:"
    echo "   aws configure"
    exit 1
fi

echo "✅ AWS credentials configured"

# Validate SAM template
echo "🔍 Validating SAM template..."
sam validate --template template.yaml
echo "✅ SAM template is valid"

# Build the application
echo "🏗️ Building SAM application..."
sam build --template template.yaml

# Deploy based on environment
echo "🚀 Deploying to $ENVIRONMENT environment..."

case $ENVIRONMENT in
    "dev")
        CORS_ORIGINS="*"
        ;;
    "staging")
        CORS_ORIGINS="https://staging.yourdomain.com"
        ;;
    "prod")
        CORS_ORIGINS="https://yourdomain.com"
        ;;
    *)
        CORS_ORIGINS="*"
        ;;
esac

# Deploy the stack
sam deploy \
    --template-file .aws-sam/build/template.yaml \
    --stack-name "$STACK_NAME" \
    --parameter-overrides Environment="$ENVIRONMENT" CorsOrigins="$CORS_ORIGINS" \
    --capabilities CAPABILITY_IAM \
    --region "$AWS_REGION" \
    --no-confirm-changeset \
    --no-fail-on-empty-changeset

# Get the API Gateway URL
echo "📋 Getting deployment information..."
API_URL=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text \
    --region "$AWS_REGION")

TABLE_NAME=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`BusinessesTableName`].OutputValue' \
    --output text \
    --region "$AWS_REGION")

echo ""
echo "✅ Deployment successful!"
echo "🌐 API Gateway URL: $API_URL"
echo "🗄️ DynamoDB Table: $TABLE_NAME"
echo ""

# Test the deployment
echo "🧪 Testing deployment..."

echo "  Testing root endpoint..."
if curl -s -f "${API_URL}" > /dev/null; then
    echo "  ✅ Root endpoint is healthy"
else
    echo "  ❌ Root endpoint failed"
fi

echo "  Testing health endpoint..."
if curl -s -f "${API_URL}health" > /dev/null; then
    echo "  ✅ Health endpoint is healthy"
else
    echo "  ❌ Health endpoint failed"
fi

echo "  Testing auth health endpoint..."
if curl -s -f "${API_URL}auth/health" > /dev/null; then
    echo "  ✅ Auth health endpoint is healthy"
else
    echo "  ❌ Auth health endpoint failed"
fi

echo ""
echo "🎉 Serverless deployment complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Update your frontend configuration to use: $API_URL"
echo "  2. Test business registration: POST ${API_URL}auth/register-business"
echo "  3. Monitor logs: aws logs tail /aws/lambda/order-receiver-register-business-$ENVIRONMENT --follow"
echo ""

# Save deployment info for later use
cat > .deployment-info << EOF
ENVIRONMENT=$ENVIRONMENT
API_URL=$API_URL
TABLE_NAME=$TABLE_NAME
STACK_NAME=$STACK_NAME
REGION=$AWS_REGION
DEPLOYED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

echo "💾 Deployment info saved to .deployment-info"
