#!/bin/bash

# Production-ready script to configure AWS Cognito with SES for email delivery
# This script follows AWS best practices and handles real-world scenarios

set -e  # Exit on any error

# Configuration
USER_POOL_ID="us-east-1_bDqnKdrqo"
FROM_EMAIL="g87_a@outlook.com"
REPLY_TO_EMAIL="g87_a@outlook.com"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="109804294167"

echo "🚀 Configuring AWS Cognito with SES for production email delivery"
echo "=================================================="
echo "User Pool ID: $USER_POOL_ID"
echo "FROM Email: $FROM_EMAIL"
echo "Region: $AWS_REGION"
echo "=================================================="

# Step 1: Verify the email address in SES
echo "📧 Step 1: Verifying email address in SES..."
aws ses verify-email-identity \
    --email-address "$FROM_EMAIL" \
    --region "$AWS_REGION"

if [ $? -eq 0 ]; then
    echo "✅ Email verification request sent to $FROM_EMAIL"
    echo "   Please check your email and click the verification link"
else
    echo "❌ Failed to send verification email"
    exit 1
fi

# Step 2: Wait for user confirmation of email verification
echo ""
echo "⏳ Please check your email ($FROM_EMAIL) and click the verification link"
echo "   Press ENTER when you have verified your email address..."
read -r

# Step 3: Check if email is verified
echo "🔍 Checking email verification status..."
VERIFICATION_STATUS=$(aws ses get-identity-verification-attributes \
    --identities "$FROM_EMAIL" \
    --region "$AWS_REGION" \
    --query "VerificationAttributes.\"$FROM_EMAIL\".VerificationStatus" \
    --output text)

if [ "$VERIFICATION_STATUS" != "Success" ]; then
    echo "❌ Email is not verified yet. Current status: $VERIFICATION_STATUS"
    echo "   Please verify your email first before continuing"
    exit 1
fi

echo "✅ Email verification confirmed"

# Step 4: Create SES configuration set (optional but recommended for production)
echo "📋 Step 2: Creating SES configuration set..."
aws ses create-configuration-set \
    --configuration-set Name=cognito-email-config \
    --region "$AWS_REGION" 2>/dev/null || echo "   Configuration set may already exist"

# Step 5: Update Cognito User Pool to use SES
echo "🔧 Step 3: Configuring Cognito User Pool to use SES..."
SES_ARN="arn:aws:ses:$AWS_REGION:$AWS_ACCOUNT_ID:identity/$FROM_EMAIL"

aws cognito-idp update-user-pool \
    --user-pool-id "$USER_POOL_ID" \
    --email-configuration \
        SourceArn="$SES_ARN",EmailSendingAccount=DEVELOPER,From="$FROM_EMAIL",ReplyToEmailAddress="$REPLY_TO_EMAIL" \
    --region "$AWS_REGION"

if [ $? -eq 0 ]; then
    echo "✅ Successfully configured Cognito to use SES"
else
    echo "❌ Failed to configure Cognito"
    exit 1
fi

# Step 6: Verify the configuration
echo "🔍 Step 4: Verifying configuration..."
aws cognito-idp describe-user-pool \
    --user-pool-id "$USER_POOL_ID" \
    --region "$AWS_REGION" \
    --query 'UserPool.EmailConfiguration' \
    --output table

# Step 7: List current users and their status
echo ""
echo "👥 Current users in the pool:"
aws cognito-idp list-users \
    --user-pool-id "$USER_POOL_ID" \
    --region "$AWS_REGION" \
    --query 'Users[].{Username:Username,Status:UserStatus,Email:Attributes[?Name==`email`].Value|[0]}' \
    --output table

echo ""
echo "🎉 Configuration Complete!"
echo "=================================================="
echo "✅ SES is now configured for Cognito email delivery"
echo "✅ FROM email: $FROM_EMAIL"
echo "✅ All verification emails will now be sent via SES"
echo ""
echo "🚀 Next Steps:"
echo "1. Test user registration in your Flutter app"
echo "2. Verification emails should arrive more reliably"
echo "3. Monitor email delivery in SES Console"
echo "=================================================="
