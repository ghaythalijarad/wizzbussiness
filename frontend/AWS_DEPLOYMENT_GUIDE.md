# Flutter Frontend AWS Deployment Guide

## Overview
The Flutter frontend has been configured to work seamlessly with AWS infrastructure while maintaining all existing UI functionality.

## Configuration System

### App Configuration (`lib/config/app_config.dart`)
- Centralized configuration management
- Environment-based URL switching
- Automatic platform detection (Android/iOS/Web)
- Support for AWS API Gateway URLs

### Environment Files
- `.env.development` - Local development
- `.env.staging` - Staging environment  
- `.env.production` - Production environment

## Building for Different Environments

### Development (Local)
```bash
cd frontend
./build.sh development
```

### Staging
```bash
cd frontend  
./build.sh staging
```

### Production (AWS)
```bash
cd frontend
./build.sh production
```

## AWS Deployment Steps

### 1. Update Production Configuration
Edit `frontend/.env.production` and replace the API URL:
```bash
API_URL=https://YOUR_API_GATEWAY_ID.execute-api.us-east-1.amazonaws.com/production
ENVIRONMENT=production
```

### 2. Build for Production
```bash
cd frontend
./build.sh production
```

### 3. Deploy to S3 (after AWS infrastructure is deployed)
```bash
aws s3 sync frontend/build/web/ s3://your-frontend-bucket-name/ --delete
```

### 4. Invalidate CloudFront Cache
```bash
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

## Configuration Features

### Automatic Environment Detection
- Development: Uses localhost URLs
- Production: Uses AWS API Gateway URLs
- Staging: Uses staging AWS URLs

### Platform Support
- **Web**: Direct API calls to AWS
- **Android**: Configured for both emulator and device
- **iOS**: Configured for both simulator and device

### Security
- Bearer token authentication (compatible with AWS Cognito)
- HTTPS support for production
- Configurable timeouts

## Testing the Configuration

### 1. Verify Configuration Loading
The app will print configuration details in debug mode:
```
=== App Configuration ===
Environment: production
Base URL: https://your-api-gateway-id.execute-api.us-east-1.amazonaws.com/production
WebSocket URL: wss://your-api-gateway-id.execute-api.us-east-1.amazonaws.com/production
Platform: web
========================
```

### 2. Test API Connectivity
- Login/logout functionality
- Data fetching from backend
- File uploads
- Real-time updates (if WebSocket is implemented)

## Integration with AWS Services

### API Gateway
- RESTful API calls via HTTP client
- Automatic Bearer token authentication
- JSON request/response handling

### S3 + CloudFront
- Static web hosting
- Global CDN distribution
- Custom domain support

### Cognito (when implemented)
- JWT token management
- Automatic token refresh
- Secure authentication flow

## Build Outputs

### Web Build (`build/web/`)
- Optimized for AWS S3 hosting
- Progressive Web App support
- Responsive design maintained

### Mobile Builds
- Android APK/AAB for Play Store
- iOS IPA for App Store
- Same backend connectivity

## Troubleshooting

### Common Issues
1. **CORS Errors**: Ensure API Gateway has proper CORS configuration
2. **Authentication**: Verify Bearer tokens are properly formatted
3. **Network**: Check AWS API Gateway endpoints are accessible

### Debug Mode
Development builds include detailed logging for troubleshooting connectivity issues.

## Next Steps
1. Deploy AWS infrastructure
2. Update `.env.production` with actual API Gateway URL
3. Build and deploy frontend to S3
4. Test end-to-end functionality
