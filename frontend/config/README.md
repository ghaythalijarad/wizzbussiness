# Environment Configuration

This directory contains environment-specific configuration files for the Flutter application.

## Files

- `.env.development` - Development environment settings
- `.env.production` - Production environment settings  
- `.env.staging` - Staging environment settings

## Usage

These files are automatically loaded by the Flutter application based on the `ENVIRONMENT` dart-define parameter.

Example:

```bash
flutter run --dart-define=ENVIRONMENT=development
```

## Configuration Variables

Each environment file should contain:

- API_URL - Backend API endpoint
- AUTH_MODE - Authentication mode (cognito)
- COGNITO_USER_POOL_ID - AWS Cognito User Pool ID
- APP_CLIENT_ID - AWS Cognito App Client ID
- COGNITO_REGION - AWS region for Cognito
- FEATURE_SET - Feature set to enable (enhanced/basic)
