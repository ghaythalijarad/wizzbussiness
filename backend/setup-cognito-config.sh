#!/bin/bash

# Cognito Configuration Setup Script
# Run this script to set up environment variables for Cognito integration

echo "🔧 Setting up Cognito Configuration for Order Receiver Backend"
echo "=============================================================="

# Check if we're in the backend directory
if [ ! -f "serverless.yml" ]; then
    echo "❌ Error: This script must be run from the backend directory"
    echo "   Please run: cd backend && ./setup-cognito-config.sh"
    exit 1
fi

# Function to prompt for environment variable
prompt_for_var() {
    local var_name=$1
    local description=$2
    local current_value=${!var_name}
    
    echo ""
    echo "📋 $description"
    if [ -n "$current_value" ]; then
        echo "   Current value: $current_value"
        read -p "   Enter new value (or press Enter to keep current): " new_value
        if [ -n "$new_value" ]; then
            export $var_name="$new_value"
        fi
    else
        read -p "   Enter value: " new_value
        export $var_name="$new_value"
    fi
}

echo ""
echo "🏗️  Cognito Setup Required"
echo "To use Cognito authentication, you need to set up the following:"
echo ""
echo "1. Create a Cognito User Pool in AWS Console"
echo "2. Create a User Pool Client (App Client)"
echo "3. Set the environment variables below"
echo ""

# Prompt for Cognito configuration
prompt_for_var "COGNITO_USER_POOL_ID" "Cognito User Pool ID (e.g., us-east-1_XXXXXXXXX)"
prompt_for_var "COGNITO_CLIENT_ID" "Cognito Client ID (e.g., 1234567890abcdefghijklmnop)"

# Optional: Prompt for AWS region if not set
if [ -z "$AWS_DEFAULT_REGION" ]; then
    prompt_for_var "AWS_DEFAULT_REGION" "AWS Region (default: us-east-1)"
    if [ -z "$AWS_DEFAULT_REGION" ]; then
        export AWS_DEFAULT_REGION="us-east-1"
    fi
fi

echo ""
echo "✅ Configuration Complete!"
echo ""
echo "Environment variables set:"
echo "  COGNITO_USER_POOL_ID: ${COGNITO_USER_POOL_ID}"
echo "  COGNITO_CLIENT_ID: ${COGNITO_CLIENT_ID}"
echo "  AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}"
echo ""

# Create .env file for local development
echo "📝 Creating .env file for local development..."
cat > .env << EOF
# Cognito Configuration for Order Receiver Backend
COGNITO_USER_POOL_ID=${COGNITO_USER_POOL_ID}
COGNITO_CLIENT_ID=${COGNITO_CLIENT_ID}
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
ENVIRONMENT=dev
DYNAMODB_TABLE_NAME=order-receiver-businesses-dev
EOF

echo "   ✅ Created .env file"
echo ""

# Create deployment script
echo "📝 Creating deployment command..."
echo ""
echo "To deploy with these settings, run:"
echo ""
echo "  # Development deployment"
echo "  COGNITO_USER_POOL_ID='${COGNITO_USER_POOL_ID}' COGNITO_CLIENT_ID='${COGNITO_CLIENT_ID}' ./deploy.sh dev"
echo ""
echo "  # Production deployment"
echo "  COGNITO_USER_POOL_ID='${COGNITO_USER_POOL_ID}' COGNITO_CLIENT_ID='${COGNITO_CLIENT_ID}' ./deploy.sh prod"
echo ""

# Update the deploy.sh script to use environment variables
if [ -f "deploy.sh" ]; then
    echo "📝 Updating deploy.sh script to include Cognito variables..."
    
    # Create backup
    cp deploy.sh deploy.sh.backup
    
    # Update deploy.sh to export Cognito variables
    cat > deploy.sh << 'EOF'
#!/bin/bash

# Enhanced deployment script with Cognito support
set -e

STAGE=${1:-dev}

echo "🚀 Deploying Order Receiver Serverless Backend to: $STAGE"
echo "=================================================="

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
    echo "📋 Loading environment variables from .env file..."
    source .env
fi

# Check required Cognito environment variables
if [ -z "$COGNITO_USER_POOL_ID" ] || [ -z "$COGNITO_CLIENT_ID" ]; then
    echo "⚠️  Warning: Cognito environment variables not set"
    echo "   Run ./setup-cognito-config.sh to configure Cognito authentication"
    echo "   Deploying without Cognito support..."
fi

# Install serverless dependencies if not present
if [ ! -d "node_modules" ]; then
    echo "📦 Installing serverless dependencies..."
    npm install
fi

# Deploy using serverless framework
echo "🚀 Deploying serverless functions..."
if [ -n "$COGNITO_USER_POOL_ID" ] && [ -n "$COGNITO_CLIENT_ID" ]; then
    echo "   ✅ Deploying with Cognito authentication support"
    COGNITO_USER_POOL_ID="$COGNITO_USER_POOL_ID" COGNITO_CLIENT_ID="$COGNITO_CLIENT_ID" npx serverless deploy --stage $STAGE
else
    echo "   ⚠️  Deploying without Cognito authentication"
    npx serverless deploy --stage $STAGE
fi

echo ""
echo "✅ Deployment complete!"
echo ""

# Show deployment info
npx serverless info --stage $STAGE

echo ""
echo "📋 Available endpoints:"
echo "  Health: GET    /health"
echo "  Auth:   GET    /auth/health"
echo "  Auth:   POST   /auth/register-business"
if [ -n "$COGNITO_USER_POOL_ID" ]; then
    echo "  Cognito: GET   /auth/cognito/health"
    echo "  Cognito: POST  /auth/cognito/login"
    echo "  Cognito: POST  /auth/cognito/register"
    echo "  Cognito: POST  /auth/cognito/verify-email"
fi
echo ""
EOF

    chmod +x deploy.sh
    echo "   ✅ Updated deploy.sh script"
fi

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Create Cognito User Pool in AWS Console if you haven't already"
echo "2. Run './deploy.sh dev' to deploy to development"
echo "3. Test the endpoints using the deployment URL"
echo ""
