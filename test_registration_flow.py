#!/usr/bin/env python3
"""
Test script to simulate the registration flow for existing unconfirmed users
"""
import json
import boto3
from botocore.exceptions import ClientError

def test_registration_flow():
    """Test the registration flow for existing unconfirmed users"""
    print("🧪 Testing Registration Flow for Existing Unconfirmed Users")
    print("=" * 60)
    
    # Known test email that exists but is unconfirmed
    test_email = "g87_a@outlook.com"
    user_pool_id = "us-east-1_bDqnKdrqo"
    client_id = "6n752vrmqmbss6nmlg6be2nn9a"
    
    cognito_client = boto3.client('cognito-idp', region_name='us-east-1')
    
    try:
        # Step 1: Check current user status
        print(f"📋 Step 1: Checking current status of {test_email}")
        try:
            response = cognito_client.admin_get_user(
                UserPoolId=user_pool_id,
                Username=test_email
            )
            status = response['UserStatus']
            print(f"   Current status: {status}")
            
            if status == 'UNCONFIRMED':
                print("   ✅ Perfect! User exists but is unconfirmed - this is our test scenario")
            elif status == 'CONFIRMED':
                print("   ⚠️  User is already confirmed. Let's test anyway...")
            else:
                print(f"   ❓ Unexpected status: {status}")
                
        except ClientError as e:
            if e.response['Error']['Code'] == 'UserNotFoundException':
                print("   ❌ User does not exist. This test needs an existing unconfirmed user.")
                return
            else:
                print(f"   ❌ Error checking user: {e}")
                return
        
        # Step 2: Simulate sign up attempt (this should trigger the existing user flow)
        print(f"\n📝 Step 2: Simulating sign up attempt for {test_email}")
        try:
            response = cognito_client.sign_up(
                ClientId=client_id,
                Username=test_email,
                Password='TestPassword123!',
                UserAttributes=[
                    {'Name': 'email', 'Value': test_email},
                    {'Name': 'phone_number', 'Value': '+9649999999999'}
                ]
            )
            print("   ✅ Sign up succeeded (user was new)")
            print(f"   Response: {json.dumps(response, indent=2, default=str)}")
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == 'UsernameExistsException':
                print("   ✅ Got UsernameExistsException - this is expected!")
                print("   🔄 Now testing resend confirmation code...")
                
                # Step 3: Try to resend confirmation code
                try:
                    resend_response = cognito_client.resend_confirmation_code(
                        ClientId=client_id,
                        Username=test_email
                    )
                    print("   ✅ Successfully resent confirmation code")
                    print(f"   Delivery: {resend_response.get('CodeDeliveryDetails', {})}")
                    
                    print("\n🎯 SUCCESS: The flow worked correctly!")
                    print("   - Detected existing unconfirmed user")
                    print("   - Successfully resent verification code")
                    print("   - User can now verify their email and complete registration")
                    
                except ClientError as resend_error:
                    resend_code = resend_error.response['Error']['Code']
                    if resend_code == 'InvalidParameterException':
                        print("   ⚠️  User might already be confirmed")
                        print("   This would trigger the 'please sign in' flow")
                    else:
                        print(f"   ❌ Failed to resend confirmation: {resend_error}")
            else:
                print(f"   ❌ Unexpected error during sign up: {e}")
        
        # Step 4: Show what the UI flow should look like
        print(f"\n🎨 Expected UI Flow:")
        print("   1. User enters email that already exists (unconfirmed)")
        print("   2. App detects UsernameExistsException") 
        print("   3. App automatically calls resend confirmation code")
        print("   4. App shows: 'Account exists but not verified. Check email for code.'")
        print("   5. User enters verification code")
        print("   6. User can complete registration process")
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

if __name__ == "__main__":
    test_registration_flow()
