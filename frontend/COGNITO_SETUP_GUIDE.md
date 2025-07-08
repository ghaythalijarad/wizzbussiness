# AWS Cognito Setup Guide

## Creating AWS Cognito User Pool

### Step 1: Create User Pool
1. Go to AWS Cognito Console: https://console.aws.amazon.com/cognito/
2. Click "Create user pool"
3. Configure the following settings:

#### Authentication providers
- **Cognito user pool sign-in options**: Email
- **Username requirements**: Allow users to sign in with preferred username

#### Security requirements
- **Password policy**: Custom
  - Minimum length: 8 characters
  - Require numbers: Yes
  - Require special characters: Yes
  - Require uppercase letters: Yes
  - Require lowercase letters: Yes
- **Multi-factor authentication**: Optional (recommended for production)

#### Required attributes
- Email (required)
- Given name (optional)
- Family name (optional)

#### Email configuration
- **Email provider**: Send email with Cognito (for development)
- **FROM email address**: Use default

### Step 2: Create User Pool Client
1. In your User Pool, go to "App integration" tab
2. Click "Create app client"
3. Configure:
   - **App type**: Public client
   - **App client name**: hadhir-business-app
   - **Client secret**: Don't generate (for mobile apps)
   - **Authentication flows**: 
     - ALLOW_USER_PASSWORD_AUTH: Yes
     - ALLOW_USER_SRP_AUTH: Yes
     - ALLOW_REFRESH_TOKEN_AUTH: Yes

### Step 3: Get Configuration Values
After creation, note down these values:
- **User Pool ID**: us-east-1_XXXXXXXXX
- **User Pool Client ID**: xxxxxxxxxxxxxxxxxxxxxxxxxx
- **AWS Region**: us-east-1 (or your chosen region)

### Step 4: Update Environment Configuration
Update your environment files with the actual values:

#### For Production (.env.production):
```bash
AUTH_MODE=cognito
COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
COGNITO_USER_POOL_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
COGNITO_REGION=us-east-1
COGNITO_IDENTITY_POOL_ID=us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

#### For Staging (.env.staging):
```bash
AUTH_MODE=cognito
COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
COGNITO_USER_POOL_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
COGNITO_REGION=us-east-1
COGNITO_IDENTITY_POOL_ID=us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

## Testing the Setup

### Test with Flutter App
Run the app with Cognito configuration:
```bash
flutter run --dart-define=ENV=production \
  --dart-define=AUTH_MODE=cognito \
  --dart-define=COGNITO_USER_POOL_ID=your-user-pool-id \
  --dart-define=COGNITO_USER_POOL_CLIENT_ID=your-client-id \
  --dart-define=COGNITO_REGION=us-east-1
```

### Verify Registration Flow
1. Open the app
2. Go to registration screen
3. Try registering with a valid email
4. Check email for verification code
5. Complete email verification

## Troubleshooting

### Common Issues:
1. **"User pool client does not exist"**: Verify the Client ID is correct
2. **"User pool does not exist"**: Verify the User Pool ID is correct
3. **"Invalid region"**: Ensure the region matches where you created the resources
4. **Email verification not working**: Check email provider configuration in Cognito

### Development vs Production
- **Development**: Use AUTH_MODE=custom (existing backend)
- **Production/Staging**: Use AUTH_MODE=cognito (AWS Cognito)
