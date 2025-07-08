#!/usr/bin/env python3
"""
Simple script to configure Cognito SES and verify users
"""
import boto3
import json

def quick_ses_setup():
    print("🔧 Quick SES Configuration for Cognito")
    
    # Initialize clients
    cognito = boto3.client('cognito-idp', region_name='us-east-1')
    ses = boto3.client('ses', region_name='us-east-1')
    
    user_pool_id = "us-east-1_bDqnKdrqo"
    email = "g87_a@outlook.com"
    
    try:
        # 1. Verify email in SES
        print(f"📧 Verifying {email} in SES...")
        ses.verify_email_identity(EmailAddress=email)
        print("✅ Email verification initiated")
        
        # 2. Configure Cognito to use SES
        print("🔄 Configuring Cognito to use SES...")
        cognito.update_user_pool(
            UserPoolId=user_pool_id,
            EmailConfiguration={
                'SourceArn': f'arn:aws:ses:us-east-1:109804294167:identity/{email}',
                'EmailSendingAccount': 'DEVELOPER',
                'From': email,
                'ReplyToEmailAddress': email
            }
        )
        print("✅ Cognito configured to use SES")
        
        # 3. List users and their status
        print("📋 Checking user status...")
        users = cognito.list_users(UserPoolId=user_pool_id)
        for user in users['Users']:
            username = user['Username']
            status = user['UserStatus']
            email_attr = next((attr['Value'] for attr in user['Attributes'] if attr['Name'] == 'email'), 'No email')
            print(f"   {username} ({email_attr}): {status}")
        
        print("\n🎉 Configuration complete!")
        print("📋 Next steps:")
        print("1. Try registering a new user in the Flutter app")
        print("2. Check your email for the verification code")
        print("3. Or manually confirm existing users if needed")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    quick_ses_setup()
