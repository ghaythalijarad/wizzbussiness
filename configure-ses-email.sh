#!/bin/bash

# Configure Cognito to use SES for email delivery
USER_POOL_ID="us-east-1_bDqnKdrqo"
FROM_EMAIL="g87_a@outlook.com"
REPLY_TO_EMAIL="g87_a@outlook.com"

echo "Configuring Cognito User Pool to use SES for email delivery..."

# First, verify the email address in SES if not already done
echo "Verifying email address in SES..."
aws ses verify-email-identity --email-address "$FROM_EMAIL" || echo "Email might already be verified"

# Wait a moment for verification
sleep 2

# Update Cognito User Pool to use SES
echo "Updating Cognito User Pool email configuration..."
aws cognito-idp update-user-pool \
  --user-pool-id "$USER_POOL_ID" \
  --email-configuration "SourceArn=arn:aws:ses:us-east-1:109804294167:identity/$FROM_EMAIL,EmailSendingAccount=DEVELOPER,From=$FROM_EMAIL,ReplyToEmailAddress=$REPLY_TO_EMAIL"

if [ $? -eq 0 ]; then
    echo "✅ Successfully configured Cognito to use SES"
    echo "From email: $FROM_EMAIL"
    echo "Reply-to email: $REPLY_TO_EMAIL"
else
    echo "❌ Failed to configure Cognito SES integration"
    exit 1
fi

# Verify the configuration
echo "Verifying new configuration..."
aws cognito-idp describe-user-pool --user-pool-id "$USER_POOL_ID" --query 'UserPool.EmailConfiguration' --output json

echo "Configuration complete! Verification emails should now be delivered more reliably."
