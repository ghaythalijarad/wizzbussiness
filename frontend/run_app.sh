#!/bin/bash

# Run Flutter app with Cognito configuration
flutter run \
  --dart-define=AUTH_MODE=cognito \
  --dart-define=COGNITO_USER_POOL_ID=us-east-1_bDqnKdrqo \
  --dart-define=COGNITO_USER_POOL_CLIENT_ID=6n752vrmqmbss6nmlg6be2nn9a \
  --dart-define=COGNITO_REGION=us-east-1 \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_BASE_URL=https://2fphc9vwkf.execute-api.us-east-1.amazonaws.com/dev
