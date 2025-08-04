#!/bin/bash

# Determine stage (dev, staging, prod) from first argument or default to dev
STAGE=${1:-dev}
case "${STAGE}" in
  dev|development)
    ENVIRONMENT=development
    API_URL="https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev"
    ;;
  staging)
    ENVIRONMENT=staging
    API_URL="https://q8oyxcwv4g.execute-api.eu-north-1.amazonaws.com/dev"
    ;;
  prod|production)
    ENVIRONMENT=production
    API_URL="https://q8oyxcwv4g.execute-api.eu-north-1.amazonaws.com/dev"
    ;;
  *)
    echo "Usage: $0 [dev|staging|prod]"
    exit 1
    ;;
esac

# Environment variables for the Flutter app
API_URL_LOCAL="https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev"
API_URL_ANDROID="https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev"
API_URL_IOS="https://72nmgq5rc4.execute-api.us-east-1.amazonaws.com/dev"
COGNITO_USER_POOL_ID="us-east-1_bDqnKdrqo"
COGNITO_CLIENT_ID="6n752vrmqmbss6nmlg6be2nn9a"

# Run Flutter app with Cognito configuration and selected stage
flutter run \
  --dart-define=AUTH_MODE=cognito \
  --dart-define=COGNITO_USER_POOL_ID=${COGNITO_USER_POOL_ID} \
  --dart-define=COGNITO_USER_POOL_CLIENT_ID=${COGNITO_CLIENT_ID} \
  --dart-define=COGNITO_REGION=us-east-1 \
  --dart-define=ENVIRONMENT=${ENVIRONMENT} \
  --dart-define=API_URL=${API_URL}
