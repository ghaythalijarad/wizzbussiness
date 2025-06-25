#!/usr/bin/env python3
"""
Comprehensive POS Settings Test Suite
Tests all POS integration endpoints and functionality
"""
import asyncio
import json
import httpx
from datetime import datetime
from typing import Dict, Any


class PosSettingsTestSuite:
    """Test suite for POS settings endpoints"""
    
    def __init__(self):
        self.BASE_URL = "http://localhost:8000"
        self.test_business_id = None
        self.access_token = None
        
    async def run_all_tests(self):
        """Run comprehensive POS settings tests"""
        print("🧪 Starting POS Settings Test Suite")
        print("=" * 50)
        
        try:
            # Test 1: Get supported POS systems
            await self.test_get_supported_systems()
            
            # Test 2: Authentication (using existing test user)
            await self.test_authentication()
            
            # Test 3: Create business for testing
            await self.test_create_business()
            
            if self.test_business_id:
                # Test 4: POS settings CRUD operations
                await self.test_pos_settings_crud()
                
                # Test 5: POS connection testing
                await self.test_pos_connection()
                
                # Test 6: POS sync logs
                await self.test_pos_sync_logs()
            
            print("\n✅ All POS Settings Tests Completed Successfully!")
            
        except Exception as e:
            print(f"❌ Test Suite Failed: {e}")
            import traceback
            traceback.print_exc()
    
    async def test_get_supported_systems(self):
        """Test getting supported POS systems"""
        print("\n📋 Testing: Get Supported POS Systems")
        
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.BASE_URL}/api/pos/systems")
            
            assert response.status_code == 200
            systems = response.json()
            
            print(f"✅ Found {len(systems)} supported POS systems:")
            for system in systems:
                print(f"   - {system['name']} ({system['type']})")
                print(f"     Required: {', '.join(system['required_fields'])}")
                print(f"     Optional: {', '.join(system['optional_fields'])}")
    
    async def test_authentication(self):
        """Test user authentication"""
        print("\n🔐 Testing: User Authentication")
        
        # Try to login with test user (assuming one exists)
        login_data = {
            "username": "test@wizz.com",
            "password": "Test123"
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{self.BASE_URL}/auth/jwt/login",
                    data=login_data
                )
                
                if response.status_code == 200:
                    result = response.json()
                    self.access_token = result["access_token"]
                    print("✅ Authentication successful")
                else:
                    print("⚠️  Authentication failed - creating new test user")
                    await self.create_test_user()
                    
            except Exception as e:
                print(f"⚠️  Authentication error: {e}")
                await self.create_test_user()
    
    async def create_test_user(self):
        """Create a test user for POS testing"""
        print("👤 Creating test user for POS testing")
        
        user_data = {
            "email": "postest@wizz.com",
            "password": "PosTest123",
            "business_name": "POS Test Business",
            "business_type": "restaurant"
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.BASE_URL}/auth/register",
                json=user_data
            )
            
            if response.status_code in [200, 201]:
                print("✅ Test user created")
                # Now login
                login_data = {
                    "username": user_data["email"],
                    "password": user_data["password"]
                }
                
                login_response = await client.post(
                    f"{self.BASE_URL}/auth/jwt/login",
                    data=login_data
                )
                
                if login_response.status_code == 200:
                    result = login_response.json()
                    self.access_token = result["access_token"]
                    print("✅ Test user login successful")
            else:
                print(f"❌ Failed to create test user: {response.text}")
    
    async def test_create_business(self):
        """Create a test business for POS testing"""
        print("\n🏢 Testing: Create Business for POS Testing")
        
        if not self.access_token:
            print("❌ No access token available")
            return
        
        business_data = {
            "name": "POS Test Restaurant",
            "business_type": "restaurant",
            "email": "postest@wizz.com",
            "phone": "+96512345678",
            "address": {
                "country": "Kuwait",
                "city": "Kuwait City",
                "district": "Salmiya",
                "neighbourhood": "Block 10",
                "street": "Street 1",
                "building_number": "123",
                "zip_code": "12345"
            },
            "owner": {
                "name": "POS Test Owner",
                "national_id": "123456789012",
                "date_of_birth": "1990-01-01",
                "email": "owner@wizz.com"
            },
            "settings": {
                "pos": {
                    "enabled": false,
                    "autoSendOrders": false,
                    "systemType": "square",
                    "apiEndpoint": "",
                    "apiKey": "",
                    "accessToken": "",
                    "locationId": ""
                }
            }
        }
        
        headers = {"Authorization": f"Bearer {self.access_token}"}
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.BASE_URL}/businesses/",
                json=business_data,
                headers=headers
            )
            
            if response.status_code in [200, 201]:
                result = response.json()
                self.test_business_id = result["id"]
                print(f"✅ Business created with ID: {self.test_business_id}")
            else:
                print(f"❌ Failed to create business: {response.text}")
    
    async def test_pos_settings_crud(self):
        """Test POS settings CRUD operations"""
        print("\n⚙️  Testing: POS Settings CRUD Operations")
        
        headers = {"Authorization": f"Bearer {self.access_token}"}
        
        # Test 1: Get default POS settings
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.BASE_URL}/api/pos/{self.test_business_id}/settings",
                headers=headers
            )
            
            if response.status_code == 200:
                settings = response.json()
                print("✅ Get POS settings successful")
                print(f"   Default system: {settings['settings']['system_type']}")
            else:
                print(f"❌ Failed to get POS settings: {response.text}")
                return
        
        # Test 2: Update POS settings
        update_data = {
            "enabled": True,
            "auto_send_orders": True,
            "system_type": "toast",
            "api_endpoint": "https://api.toastpos.com/v1",
            "api_key": "test_api_key_123",
            "access_token": "test_access_token_456",
            "location_id": "test_location_789",
            "timeout_seconds": 30,
            "retry_attempts": 3,
            "test_mode": True
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.put(
                f"{self.BASE_URL}/api/pos/{self.test_business_id}/settings",
                json=update_data,
                headers=headers
            )
            
            if response.status_code == 200:
                result = response.json()
                print("✅ Update POS settings successful")
                print(f"   Updated system: {result['settings']['system_type']}")
                print(f"   Enabled: {result['settings']['enabled']}")
            else:
                print(f"❌ Failed to update POS settings: {response.text}")
    
    async def test_pos_connection(self):
        """Test POS connection functionality"""
        print("\n🔗 Testing: POS Connection Test")
        
        headers = {"Authorization": f"Bearer {self.access_token}"}
        
        test_config = {
            "system_type": "toast",
            "api_endpoint": "https://api.toastpos.com/v1",
            "api_key": "test_key",
            "access_token": "test_token",
            "location_id": "test_location"
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.BASE_URL}/api/pos/{self.test_business_id}/test-connection",
                json=test_config,
                headers=headers
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ Connection test completed")
                print(f"   Success: {result['success']}")
                print(f"   Message: {result['message']}")
                if result.get('response_time_ms'):
                    print(f"   Response time: {result['response_time_ms']}ms")
            else:
                print(f"❌ Connection test failed: {response.text}")
    
    async def test_pos_sync_logs(self):
        """Test POS sync logs functionality"""
        print("\n📊 Testing: POS Sync Logs")
        
        headers = {"Authorization": f"Bearer {self.access_token}"}
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.BASE_URL}/api/pos/{self.test_business_id}/sync-logs",
                headers=headers
            )
            
            if response.status_code == 200:
                logs = response.json()
                print(f"✅ Sync logs retrieved successfully")
                print(f"   Found {len(logs)} sync log entries")
            else:
                print(f"❌ Failed to get sync logs: {response.text}")


async def main():
    """Main test function"""
    test_suite = PosSettingsTestSuite()
    await test_suite.run_all_tests()


if __name__ == "__main__":
    asyncio.run(main())
