#!/bin/bash
# Determine stage (dev, staging, prod) from first argument or default to dev
STAGE=${1:-dev}
case "${STAGE}" in
  dev|development)
    ENVIRONMENT=development
    API_URL="https://tb6gkr97w0.execute-api.us-east-1.amazonaws.com/Prod"
    ;;
  staging)
    ENVIRONMENT=staging
    API_URL="https://tb6gkr97w0.execute-api.us-east-1.amazonaws.com/Prod"
    ;;
  prod|production)
    ENVIRONMENT=production
    API_URL="https://tb6gkr97w0.execute-api.us-east-1.amazonaws.com/Prod"
    ;;
  *)
    echo "Usage: $0 [dev|staging|prod]"
    exit 1
    ;;
esac

# Kill any existing flutter processes
pkill -f flutter || true

# Clear terminal
clear

echo "🚀 Starting Flutter Order Receiver App..."
echo "📱 Configuration:"
echo "   - Environment: ${ENVIRONMENT}"
echo "   - Auth Mode: Cognito"
echo "   - API URL: ${API_URL}"
echo "   - Cognito Pool: us-east-1_bDqnKdrqo"
echo ""

# Run Flutter with stage-aware environment variables
flutter run \
  --dart-define=AUTH_MODE=cognito \
  --dart-define=COGNITO_USER_POOL_ID=us-east-1_bDqnKdrqo \
  --dart-define=COGNITO_USER_POOL_CLIENT_ID=6n752vrmqmbss6nmlg6be2nn9a \
  --dart-define=COGNITO_REGION=us-east-1 \
  --dart-define=ENVIRONMENT=${ENVIRONMENT} \
  --dart-define=API_URL=${API_URL} \
  --hot
