#!/bin/bash

# Build script for different environments
set -e

ENVIRONMENT=${1:-development}

echo "🚀 Building Flutter app for environment: $ENVIRONMENT"

# Load environment variables
if [ -f ".env.$ENVIRONMENT" ]; then
    echo "📋 Loading environment configuration from .env.$ENVIRONMENT"
    export $(grep -v '^#' .env.$ENVIRONMENT | xargs)
else
    echo "⚠️  No .env.$ENVIRONMENT file found, using defaults"
fi

# Print configuration for verification
echo "📊 Build Configuration:"
echo "   Environment: $ENVIRONMENT"
echo "   API URL: ${API_URL:-'default (localhost)'}"
echo "   Auth Mode: ${AUTH_MODE:-'custom'}"
if [ "$AUTH_MODE" = "cognito" ]; then
    echo "   Cognito User Pool ID: ${COGNITO_USER_POOL_ID:-'not set'}"
    echo "   Cognito Client ID: ${COGNITO_USER_POOL_CLIENT_ID:-'not set'}"
    echo "   Cognito Region: ${COGNITO_REGION:-'us-east-1'}"
fi

# Build for web (for AWS S3 deployment)
echo "🔨 Building Flutter web app..."
flutter build web \
    --dart-define=API_URL="${API_URL:-}" \
    --dart-define=ENVIRONMENT="$ENVIRONMENT" \
    --dart-define=AUTH_MODE="${AUTH_MODE:-custom}" \
    --dart-define=COGNITO_USER_POOL_ID="${COGNITO_USER_POOL_ID:-}" \
    --dart-define=COGNITO_USER_POOL_CLIENT_ID="${COGNITO_USER_POOL_CLIENT_ID:-}" \
    --dart-define=COGNITO_REGION="${COGNITO_REGION:-us-east-1}" \
    --dart-define=COGNITO_IDENTITY_POOL_ID="${COGNITO_IDENTITY_POOL_ID:-}"

echo "✅ Build completed successfully!"
echo "📁 Output directory: build/web/"

if [ "$ENVIRONMENT" = "production" ]; then
    echo ""
    echo "🚀 Ready for AWS S3 deployment!"
    echo "💡 To deploy to S3, run:"
    echo "   aws s3 sync build/web/ s3://your-s3-bucket-name/ --delete"
fi
