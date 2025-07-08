#!/usr/bin/env python3
"""
Manually confirm a Cognito user to bypass email verification for testing
"""
import boto3
import sys
from botocore.exceptions import ClientError

def list_and_confirm_users():
    user_pool_id = "us-east-1_bDqnKdrqo"
    cognito_client = boto3.client('cognito-idp', region_name='us-east-1')
    
    try:
        # List all users
        print("📋 Listing users in Cognito User Pool...")
        response = cognito_client.list_users(UserPoolId=user_pool_id)
        users = response.get('Users', [])
        
        print(f"Found {len(users)} users:")
        for i, user in enumerate(users):
            username = user['Username']
            status = user['UserStatus']
            email = None
            
            # Get email from attributes
            for attr in user.get('Attributes', []):
                if attr['Name'] == 'email':
                    email = attr['Value']
                    break
            
            print(f"{i+1}. Username: {username}")
            print(f"   Email: {email}")
            print(f"   Status: {status}")
            print()
            
            # If user is UNCONFIRMED, offer to confirm them
            if status == 'UNCONFIRMED':
                confirm = input(f"Confirm user {username} ({email})? (y/n): ").lower()
                if confirm == 'y':
                    try:
                        cognito_client.admin_confirm_sign_up(
                            UserPoolId=user_pool_id,
                            Username=username
                        )
                        print(f"✅ Successfully confirmed user {username}")
                        
                        # Also set permanent password if needed
                        try:
                            cognito_client.admin_set_user_password(
                                UserPoolId=user_pool_id,
                                Username=username,
                                Password="TempPassword123!",  # You'll need to change this
                                Permanent=True
                            )
                            print(f"✅ Set permanent password for user {username}")
                        except ClientError as e:
                            print(f"⚠️  Could not set password: {e}")
                            
                    except ClientError as e:
                        print(f"❌ Failed to confirm user {username}: {e}")
                        
        return len([u for u in users if u['UserStatus'] == 'CONFIRMED'])
        
    except ClientError as e:
        print(f"❌ Error listing users: {e}")
        return 0

if __name__ == "__main__":
    confirmed_count = list_and_confirm_users()
    print(f"\n🎉 Total confirmed users: {confirmed_count}")
    if confirmed_count > 0:
        print("\n🚀 You can now test sign-in with a confirmed user!")
        print("💡 Try signing in with the confirmed user credentials in your Flutter app")
