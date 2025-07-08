# AWS Cognito Integration Guide

## Overview

The Flutter frontend now supports **AWS Cognito authentication** as an alternative to the custom backend authentication. This provides enterprise-grade authentication with features like:

- Email verification
- Password reset flows  
- Multi-factor authentication (configurable)
- Social login integration (configurable)
- Secure token management
- Automatic session refresh

## Architecture

The app uses a **Unified Authentication Service** that can switch between:
- **Custom Backend Authentication** (for local development)
- **AWS Cognito Authentication** (for production/staging)

## Configuration

### Environment Variables

The authentication mode is controlled by environment variables:

```bash
# Authentication mode: 'cognito' or 'custom'
AUTH_MODE=cognito

# AWS Cognito Configuration
COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
COGNITO_USER_POOL_CLIENT_ID=your-client-id-here
COGNITO_REGION=us-east-1
COGNITO_IDENTITY_POOL_ID=us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### Environment Files

- **Development**: `.env.development` - Uses custom auth (`AUTH_MODE=custom`)
- **Staging**: `.env.staging` - Uses Cognito (`AUTH_MODE=cognito`)
- **Production**: `.env.production` - Uses Cognito (`AUTH_MODE=cognito`)

## AWS Cognito Setup

### 1. Create User Pool

```bash
aws cognito-idp create-user-pool \
    --pool-name "hadhir-business-users" \
    --policies "PasswordPolicy={MinimumLength=8,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true}" \
    --username-attributes email \
    --auto-verified-attributes email \
    --verification-message-template "DefaultEmailOption=CONFIRM_WITH_CODE" \
    --email-configuration "SourceArn=arn:aws:ses:us-east-1:ACCOUNT:identity/noreply@yourdomain.com,ReplyToEmailAddress=noreply@yourdomain.com"
```

### 2. Create User Pool Client

```bash
aws cognito-idp create-user-pool-client \
    --user-pool-id us-east-1_XXXXXXXXX \
    --client-name "hadhir-business-app" \
    --no-generate-secret \
    --explicit-auth-flows ALLOW_USER_SRP_AUTH ALLOW_REFRESH_TOKEN_AUTH \
    --supported-identity-providers COGNITO
```

### 3. Create Identity Pool (Optional)

```bash
aws cognito-identity create-identity-pool \
    --identity-pool-name "hadhir_business_identity_pool" \
    --allow-unauthenticated-identities \
    --cognito-identity-providers ProviderName=cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXXXXXXX,ClientId=your-client-id,ServerSideTokenCheck=false
```

## User Registration Flow

### Custom Authentication (Development)
1. User fills registration form
2. Data sent to custom backend with files
3. Account created immediately
4. User can login right away

### Cognito Authentication (Production)
1. User fills registration form
2. Basic user data sent to Cognito
3. **Email verification required**
4. User receives verification code via email
5. User enters code to confirm registration
6. User can now login
7. Additional business data sent to backend API

## Implementation Details

### Services Structure

```
lib/services/
├── unified_auth_service.dart       # Main auth interface
├── cognito_auth_service.dart       # Cognito implementation  
├── auth_service.dart              # Custom backend auth
└── api_service.dart               # Business data API
```

### Key Features

#### Automatic Switching
The `UnifiedAuthService` automatically detects the configuration and uses the appropriate authentication method:

```dart
// This works with both Cognito and custom auth
final result = await UnifiedAuthService.signIn(
  email: email,
  password: password,
);
```

#### Email Verification Dialog
When using Cognito, the registration screen automatically shows an email verification dialog if needed:

```dart
if (response['isSignUpComplete'] == false && 
    response['nextStep']?.contains('CONFIRM_SIGN_UP') == true) {
  _showEmailVerificationDialog(email);
}
```

#### Token Management
- **Cognito**: Uses AWS Amplify's automatic token refresh
- **Custom**: Uses SharedPreferences storage

## Building for Different Environments

### Development (Custom Auth)
```bash
cd frontend
./build.sh development
```

### Production (Cognito)
```bash
cd frontend
./build.sh production
```

The build script automatically includes all necessary environment variables as compile-time constants.

## Testing

### Local Development
1. Use `AUTH_MODE=custom` 
2. Run against local backend
3. Test with existing registration flow

### AWS Staging
1. Set up Cognito User Pool
2. Update `.env.staging` with Cognito credentials
3. Build with `./build.sh staging`
4. Test email verification flow

### Production Deployment
1. Configure production Cognito User Pool
2. Update `.env.production` with production credentials
3. Build with `./build.sh production`
4. Deploy to S3/CloudFront

## Security Features

### Cognito Benefits
- **Password Policies**: Enforced server-side
- **Account Lockout**: After failed attempts
- **Email Verification**: Prevents fake accounts
- **Token Refresh**: Automatic and secure
- **CSRF Protection**: Built-in token validation
- **Rate Limiting**: AWS-managed

### Custom Auth Benefits  
- **Full Control**: Complete customization
- **File Uploads**: Business documents during registration
- **Local Development**: No internet required
- **Legacy Support**: Existing user base

## Error Handling

The Cognito service provides user-friendly error messages:

```dart
switch (e.runtimeType.toString()) {
  case 'UserNotFoundException':
    return 'User not found. Please check your email address.';
  case 'NotAuthorizedException':
    return 'Invalid email or password.';
  case 'UserNotConfirmedException':
    return 'Please verify your email before signing in.';
  // ... more cases
}
```

## Migration Strategy

### Phase 1: Development (Current)
- Use custom authentication
- Test unified service interface
- Verify both auth modes work

### Phase 2: Staging
- Set up Cognito User Pool
- Deploy with Cognito enabled
- Test email verification flow
- Validate token handling

### Phase 3: Production
- Production Cognito setup
- Full AWS deployment
- Monitor authentication metrics
- Support both new (Cognito) and existing (custom) users

## Monitoring

### Cognito Metrics
- User registrations
- Sign-in attempts
- Failed authentications
- Email verification rates

### Custom Metrics
- API response times
- File upload success rates
- Business registration completion

## Troubleshooting

### Common Issues

1. **iOS Build Errors**
   - Ensure iOS deployment target is 13.0+
   - Clean and rebuild: `flutter clean && flutter pub get`

2. **Email Verification Not Working**
   - Check SES configuration in Cognito
   - Verify email domain is verified in SES
   - Check spam folders

3. **Token Refresh Issues**
   - Ensure Cognito client allows refresh tokens
   - Check network connectivity
   - Verify region configuration

### Debug Mode

Enable detailed logging in development:

```dart
if (AppConfig.enableLogging) {
  print('Auth Mode: ${UnifiedAuthService.authMode}');
  print('Using Cognito: ${UnifiedAuthService.usingCognito}');
}
```

## Future Enhancements

- Social login integration (Google, Apple)
- Multi-factor authentication
- Biometric authentication
- Progressive user profile completion
- Advanced password policies
