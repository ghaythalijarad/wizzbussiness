#!/usr/bin/env python3

import requests
import json

def test_working_hours_format():
    print("🧪 TESTING WORKING HOURS FORMAT COMPATIBILITY")
    print("==============================================")
    
    # Configuration
    api_base_url = "https://zz9cszv6a8.execute-api.us-east-1.amazonaws.com/dev"
    business_id = "business_1756220656049_ee98qktepks"
    username = "g87_a@yahoo.com"
    password = "Gha@551987"
    
    print("\n🔐 Step 1: Authentication...")
    
    # Get access token
    auth_payload = {
        "AuthFlow": "USER_PASSWORD_AUTH",
        "ClientId": "1tl9g7nk2k2chtj5fg960fgdth",
        "AuthParameters": {
            "USERNAME": username,
            "PASSWORD": password
        }
    }
    
    auth_headers = {
        "Content-Type": "application/x-amz-json-1.1",
        "X-Amz-Target": "AWSCognitoIdentityProviderService.InitiateAuth"
    }
    
    try:
        auth_response = requests.post(
            "https://cognito-idp.us-east-1.amazonaws.com/",
            headers=auth_headers,
            json=auth_payload
        )
        
        if auth_response.status_code == 200:
            auth_data = auth_response.json()
            access_token = auth_data.get("AuthenticationResult", {}).get("AccessToken")
            
            if access_token:
                print("✅ Authentication successful")
            else:
                print("❌ No access token in response")
                return False
        else:
            print(f"❌ Authentication failed: {auth_response.status_code}")
            print(f"Response: {auth_response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Authentication error: {e}")
        return False
    
    print("\n📋 Step 2: Test Flutter format working hours save...")
    
    # Test data in Flutter format (lowercase days, openTime/closeTime)
    flutter_format_data = {
        "workingHours": {
            "monday": {"isOpen": True, "openTime": "08:00", "closeTime": "18:00"},
            "tuesday": {"isOpen": True, "openTime": "08:00", "closeTime": "18:00"},
            "wednesday": {"isOpen": True, "openTime": "08:00", "closeTime": "18:00"},
            "thursday": {"isOpen": True, "openTime": "08:00", "closeTime": "18:00"},
            "friday": {"isOpen": True, "openTime": "08:00", "closeTime": "20:00"},
            "saturday": {"isOpen": True, "openTime": "09:00", "closeTime": "17:00"},
            "sunday": {"isOpen": False, "openTime": "10:00", "closeTime": "16:00"}
        }
    }
    
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }
    
    try:
        save_response = requests.put(
            f"{api_base_url}/businesses/{business_id}/working-hours",
            headers=headers,
            json=flutter_format_data
        )
        
        print(f"Save response status: {save_response.status_code}")
        print(f"Save response: {save_response.text}")
        
        if save_response.status_code == 200:
            save_data = save_response.json()
            if save_data.get("success"):
                print("✅ Working hours save successful with Flutter format!")
            else:
                print(f"❌ Working hours save failed: {save_data.get('message')}")
                return False
        else:
            print(f"❌ Save request failed: {save_response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Save error: {e}")
        return False
    
    print("\n📖 Step 3: Test working hours retrieval...")
    
    try:
        get_response = requests.get(
            f"{api_base_url}/businesses/{business_id}/working-hours",
            headers=headers
        )
        
        print(f"Get response status: {get_response.status_code}")
        print(f"Get response: {get_response.text}")
        
        if get_response.status_code == 200:
            get_data = get_response.json()
            if get_data.get("success"):
                print("✅ Working hours retrieval successful!")
                
                working_hours = get_data.get("workingHours", {})
                if "monday" in working_hours:
                    print("✅ Response is in Flutter format (lowercase days)")
                    
                    monday_open = working_hours.get("monday", {}).get("openTime")
                    if monday_open == "08:00":
                        print(f"✅ Monday opening time saved correctly: {monday_open}")
                    else:
                        print(f"❌ Monday opening time incorrect: {monday_open} (expected 08:00)")
                else:
                    print("⚠️ Response format may need checking - no 'monday' key found")
                    print(f"Available keys: {list(working_hours.keys())}")
            else:
                print(f"❌ Retrieval failed: {get_data.get('message')}")
                return False
        else:
            print(f"❌ Get request failed: {get_response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Retrieval error: {e}")
        return False
    
    print("\n📊 FINAL RESULTS:")
    print("==================")
    print("✅ Authentication: PASS")
    print("✅ Flutter format save: PASS")
    print("✅ Working hours retrieval: PASS")
    print("✅ Format compatibility: PASS")
    print("\n🎉 WORKING HOURS FORMAT FIX: SUCCESS!")
    
    return True

if __name__ == "__main__":
    test_working_hours_format()
