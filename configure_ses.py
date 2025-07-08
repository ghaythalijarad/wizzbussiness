#!/usr/bin/env python3
"""
Configure Cognito User Pool to use SES for email delivery
"""
import boto3
import json
from botocore.exceptions import ClientError

def configure_cognito_ses():
    # Configuration
    user_pool_id = "us-east-1_bDqnKdrqo"
    from_email = "g87_a@outlook.com"
    reply_to_email = "g87_a@outlook.com"
    aws_account_id = "109804294167"
    
    # Initialize clients
    cognito_client = boto3.client('cognito-idp', region_name='us-east-1')
    ses_client = boto3.client('ses', region_name='us-east-1')
    
    print("🔧 Configuring Cognito to use SES for email delivery...")
    
    try:
        # Step 1: Verify email in SES
        print(f"📧 Verifying email address {from_email} in SES...")
        try:
            ses_client.verify_email_identity(EmailAddress=from_email)
            print(f"✅ Email verification initiated for {from_email}")
        except ClientError as e:
            if "already verified" in str(e).lower():
                print(f"✅ Email {from_email} is already verified")
            else:
                print(f"⚠️  SES verification warning: {e}")
        
        # Step 2: Update Cognito User Pool to use SES
        print(f"🔄 Updating Cognito User Pool {user_pool_id} to use SES...")
        
        # Create the SES ARN
        ses_arn = f"arn:aws:ses:us-east-1:{aws_account_id}:identity/{from_email}"
        
        email_config = {
            'SourceArn': ses_arn,
            'EmailSendingAccount': 'DEVELOPER',
            'From': from_email,
            'ReplyToEmailAddress': reply_to_email
        }
        
        response = cognito_client.update_user_pool(
            UserPoolId=user_pool_id,
            EmailConfiguration=email_config
        )
        
        print("✅ Successfully configured Cognito to use SES!")
        print(f"   From email: {from_email}")
        print(f"   Reply-to: {reply_to_email}")
        print(f"   SES ARN: {ses_arn}")
        
        # Step 3: Verify the configuration
        print("🔍 Verifying new configuration...")
        user_pool = cognito_client.describe_user_pool(UserPoolId=user_pool_id)
        email_config = user_pool['UserPool'].get('EmailConfiguration', {})
        
        print("\n📋 Current Email Configuration:")
        print(json.dumps(email_config, indent=2, default=str))
        
        print("\n🎉 Configuration complete! Verification emails should now be delivered more reliably.")
        
        return True
        
    except ClientError as e:
        print(f"❌ Error configuring Cognito SES integration: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

if __name__ == "__main__":
    success = configure_cognito_ses()
    if success:
        print("\n🚀 Next steps:")
        print("1. Try registering a new user in the Flutter app")
        print("2. Check your email for the verification code")
        print("3. Enter the code in the app to complete verification")
    else:
        print("\n💡 If this fails, you can manually configure SES in the AWS Console:")
        print("1. Go to Cognito User Pools > Your Pool > Messaging")
        print("2. Select 'Send emails with Amazon SES'")
        print("3. Configure the FROM email address")
