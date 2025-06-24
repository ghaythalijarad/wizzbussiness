"""
Comprehensive registration tests for all business types.
Tests user registration and business creation for restaurant, store, pharmacy, and kitchen.
"""
import pytest
import asyncio
import httpx
from datetime import datetime, date
import json
import time


class TestBusinessRegistration:
    """Test suite for business registration across all business types."""
    
    BASE_URL = "http://localhost:8001"
    
    # Test data for different business types
    BUSINESS_TEST_DATA = {
        "restaurant": {
            "user_data": {
                "email": "restaurant@test.com",
                "password": "TestPassword123",
                "business_name": "Mediterranean Delights Restaurant",
                "business_type": "restaurant",
                "phone_number": "+966501234567"
            },
            "business_data": {
                "name": "Mediterranean Delights Restaurant",
                "business_type": "restaurant",
                "phone_number": "+966501234567",
                "email": "restaurant@test.com",
                "website": "https://mediterranean-delights.com",
                "address": {
                    "country": "Saudi Arabia",
                    "city": "Riyadh",
                    "district": "Al Malqa",
                    "neighbourhood": "North District",
                    "street": "King Fahd Road",
                    "building_number": "123",
                    "zip_code": "12345",
                    "latitude": 24.7136,
                    "longitude": 46.6753
                },
                "owner_name": "Ahmed Al-Restaurant",
                "owner_national_id": "1234567890",
                "owner_date_of_birth": "1985-03-15T00:00:00"
            },
            "pos_settings": {
                "enabled": True,
                "autoSendOrders": True,
                "systemType": "toast",
                "apiEndpoint": "https://api.toastpos.com/v1",
                "apiKey": "toast_api_key_restaurant_123",
                "accessToken": "toast_access_token_456",
                "locationId": "restaurant_location_789"
            }
        },
        "store": {
            "user_data": {
                "email": "store@test.com",
                "password": "TestPassword123",
                "business_name": "Fresh Market Store",
                "business_type": "store",
                "phone_number": "+966501234568"
            },
            "business_data": {
                "name": "Fresh Market Store",
                "business_type": "store",
                "phone_number": "+966501234568",
                "email": "store@test.com",
                "website": "https://fresh-market.com",
                "address": {
                    "country": "Saudi Arabia",
                    "city": "Jeddah",
                    "district": "Al Salamah",
                    "neighbourhood": "West District",
                    "street": "Prince Mohammed Road",
                    "building_number": "456",
                    "zip_code": "23456",
                    "latitude": 21.5433,
                    "longitude": 39.1728
                },
                "owner_name": "Fatima Al-Store",
                "owner_national_id": "2345678901",
                "owner_date_of_birth": "1987-07-22T00:00:00"
            },
            "pos_settings": {
                "enabled": True,
                "autoSendOrders": False,
                "systemType": "square",
                "apiEndpoint": "https://api.squareup.com/v2",
                "apiKey": "square_api_key_store_123",
                "accessToken": "square_access_token_456",
                "locationId": "store_location_789"
            }
        },
        "pharmacy": {
            "user_data": {
                "email": "pharmacy@test.com",
                "password": "TestPassword123",
                "business_name": "HealthCare Plus Pharmacy",
                "business_type": "pharmacy",
                "phone_number": "+966501234569"
            },
            "business_data": {
                "name": "HealthCare Plus Pharmacy",
                "business_type": "pharmacy",
                "phone_number": "+966501234569",
                "email": "pharmacy@test.com",
                "website": "https://healthcare-plus.com",
                "address": {
                    "country": "Saudi Arabia",
                    "city": "Dammam",
                    "district": "Al Faisaliyah",
                    "neighbourhood": "East District",
                    "street": "King Abdul Aziz Road",
                    "building_number": "789",
                    "zip_code": "34567",
                    "latitude": 26.4207,
                    "longitude": 50.0888
                },
                "owner_name": "Dr. Mohammed Al-Pharmacy",
                "owner_national_id": "3456789012",
                "owner_date_of_birth": "1980-11-10T00:00:00"
            },
            "pos_settings": {
                "enabled": True,
                "autoSendOrders": True,
                "systemType": "shopify",
                "apiEndpoint": "https://healthcare-plus.myshopify.com/admin/api/2023-10",
                "apiKey": "shopify_api_key_pharmacy_123",
                "accessToken": "shopify_access_token_456",
                "locationId": "pharmacy_location_789"
            }
        },
        "kitchen": {
            "user_data": {
                "email": "kitchen@test.com",
                "password": "TestPassword123",
                "business_name": "Gourmet Cloud Kitchen",
                "business_type": "kitchen",
                "phone_number": "+966501234570"
            },
            "business_data": {
                "name": "Gourmet Cloud Kitchen",
                "business_type": "kitchen",
                "phone_number": "+966501234570",
                "email": "kitchen@test.com",
                "website": "https://gourmet-kitchen.com",
                "address": {
                    "country": "Saudi Arabia",
                    "city": "Mecca",
                    "district": "Al Aziziyah",
                    "neighbourhood": "Central District",
                    "street": "Mecca Road",
                    "building_number": "101",
                    "zip_code": "45678",
                    "latitude": 21.3891,
                    "longitude": 39.8579
                },
                "owner_name": "Omar Al-Kitchen",
                "owner_national_id": "4567890123",
                "owner_date_of_birth": "1990-01-25T00:00:00"
            },
            "pos_settings": {
                "enabled": True,
                "autoSendOrders": False,
                "systemType": "clover",
                "apiEndpoint": "https://api.clover.com/v3",
                "apiKey": "clover_api_key_kitchen_123",
                "accessToken": "clover_access_token_456",
                "locationId": "kitchen_location_789"
            }
        }
    }
    
    def __init__(self):
        self.registered_users = {}
        self.created_businesses = {}
        # Add timestamp to make emails unique
        self.timestamp = str(int(time.time()))
        
    async def test_health_check(self):
        """Test that the API is running."""
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.BASE_URL}/health")
            assert response.status_code == 200
            assert response.json()["status"] == "healthy"
        print("✅ Health check passed")
    
    async def test_user_registration(self, business_type: str):
        """Test user registration for a specific business type."""
        user_data = self.BUSINESS_TEST_DATA[business_type]["user_data"].copy()
        # Make email unique with timestamp
        user_data["email"] = f"{business_type}_{self.timestamp}@test.com"
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.BASE_URL}/auth/register",
                json=user_data,
                headers={"Content-Type": "application/json"}
            )
            
            assert response.status_code == 200, f"Registration failed for {business_type}: {response.text}"
            
            user = response.json()
            assert user["email"] == user_data["email"]
            assert user["business_name"] == user_data["business_name"]
            assert user["business_type"] == user_data["business_type"]
            assert user["phone_number"] == user_data["phone_number"]
            assert user["is_active"] == True
            assert "id" in user
            
            self.registered_users[business_type] = user
            print(f"✅ User registration successful for {business_type}: {user['email']}")
            return user
    
    async def test_user_login(self, business_type: str):
        """Test user login for a specific business type."""
        user_data = self.BUSINESS_TEST_DATA[business_type]["user_data"].copy()
        # Use the same unique email
        user_data["email"] = f"{business_type}_{self.timestamp}@test.com"
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.BASE_URL}/auth/jwt/login",
                data={
                    "username": user_data["email"],
                    "password": user_data["password"]
                },
                headers={"Content-Type": "application/x-www-form-urlencoded"}
            )
            
            assert response.status_code == 200, f"Login failed for {business_type}: {response.text}"
            
            token_data = response.json()
            assert "access_token" in token_data
            assert token_data["token_type"] == "bearer"
            
            print(f"✅ User login successful for {business_type}")
            return token_data["access_token"]
    
    async def test_business_creation(self, business_type: str, access_token: str):
        """Test business creation for a specific business type."""
        business_data = self.BUSINESS_TEST_DATA[business_type]["business_data"].copy()
        # Use the same unique email
        business_data["email"] = f"{business_type}_{self.timestamp}@test.com"
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.BASE_URL}/businesses/",
                json=business_data,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {access_token}"
                }
            )
            
            assert response.status_code == 200, f"Business creation failed for {business_type}: {response.text}"
            
            business = response.json()
            assert business["name"] == business_data["name"]
            assert business["business_type"] == business_data["business_type"]
            assert business["phone_number"] == business_data["phone_number"]
            assert business["email"] == business_data["email"]
            assert business["status"] == "pending"
            assert business["is_online"] == True
            assert "id" in business
            
            # Check default POS settings
            assert "settings" in business
            assert "pos" in business["settings"]
            pos_settings = business["settings"]["pos"]
            assert pos_settings["enabled"] == False  # Default value
            assert pos_settings["autoSendOrders"] == False  # Default value
            assert pos_settings["systemType"] == "square"  # Default value
            assert "apiEndpoint" in pos_settings
            assert "apiKey" in pos_settings
            assert "accessToken" in pos_settings
            assert "locationId" in pos_settings
            
            self.created_businesses[business_type] = business
            print(f"✅ Business creation successful for {business_type}: {business['name']}")
            return business
    
    async def test_pos_settings_update(self, business_type: str, access_token: str):
        """Test POS settings update for a specific business type."""
        business = self.created_businesses[business_type]
        pos_settings = self.BUSINESS_TEST_DATA[business_type]["pos_settings"]
        
        async with httpx.AsyncClient() as client:
            response = await client.put(
                f"{self.BASE_URL}/businesses/{business['id']}/pos-settings",
                json=pos_settings,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {access_token}"
                }
            )
            
            assert response.status_code == 200, f"POS settings update failed for {business_type}: {response.text}"
            
            result = response.json()
            assert "message" in result
            assert "pos_settings" in result
            
            updated_pos = result["pos_settings"]
            assert updated_pos["enabled"] == pos_settings["enabled"]
            assert updated_pos["autoSendOrders"] == pos_settings["autoSendOrders"]
            assert updated_pos["systemType"] == pos_settings["systemType"]
            assert updated_pos["apiEndpoint"] == pos_settings["apiEndpoint"]
            assert updated_pos["apiKey"] == pos_settings["apiKey"]
            assert updated_pos["accessToken"] == pos_settings["accessToken"]
            assert updated_pos["locationId"] == pos_settings["locationId"]
            
            print(f"✅ POS settings update successful for {business_type}: {pos_settings['systemType']}")
            return result
    
    async def test_pos_settings_retrieval(self, business_type: str, access_token: str):
        """Test POS settings retrieval for a specific business type."""
        business = self.created_businesses[business_type]
        expected_pos = self.BUSINESS_TEST_DATA[business_type]["pos_settings"]
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.BASE_URL}/businesses/{business['id']}/pos-settings",
                headers={"Authorization": f"Bearer {access_token}"}
            )
            
            assert response.status_code == 200, f"POS settings retrieval failed for {business_type}: {response.text}"
            
            result = response.json()
            assert "pos_settings" in result
            
            retrieved_pos = result["pos_settings"]
            assert retrieved_pos["enabled"] == expected_pos["enabled"]
            assert retrieved_pos["systemType"] == expected_pos["systemType"]
            assert retrieved_pos["apiEndpoint"] == expected_pos["apiEndpoint"]
            
            print(f"✅ POS settings retrieval successful for {business_type}")
            return result
    
    async def test_my_businesses(self, business_type: str, access_token: str):
        """Test retrieving user's businesses."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.BASE_URL}/businesses/my-businesses",
                headers={"Authorization": f"Bearer {access_token}"}
            )
            
            assert response.status_code == 200, f"My businesses retrieval failed for {business_type}: {response.text}"
            
            businesses = response.json()
            assert isinstance(businesses, list)
            assert len(businesses) >= 1
            
            # Find our business in the list
            created_business = self.created_businesses[business_type]
            found_business = None
            for biz in businesses:
                if biz["id"] == created_business["id"]:
                    found_business = biz
                    break
            
            assert found_business is not None, f"Created business not found in my-businesses for {business_type}"
            assert found_business["business_type"] == business_type
            
            print(f"✅ My businesses retrieval successful for {business_type}")
            return businesses
    
    async def test_single_business_type(self, business_type: str):
        """Test complete flow for a single business type."""
        print(f"\n🧪 Testing {business_type.upper()} registration flow...")
        
        # 1. Register user
        user = await self.test_user_registration(business_type)
        
        # 2. Login user
        access_token = await self.test_user_login(business_type)
        
        # 3. Create business
        business = await self.test_business_creation(business_type, access_token)
        
        # 4. Update POS settings
        await self.test_pos_settings_update(business_type, access_token)
        
        # 5. Retrieve POS settings
        await self.test_pos_settings_retrieval(business_type, access_token)
        
        # 6. Test my businesses endpoint
        await self.test_my_businesses(business_type, access_token)
        
        print(f"🎉 {business_type.upper()} registration flow completed successfully!\n")
    
    async def run_all_tests(self):
        """Run comprehensive tests for all business types."""
        print("🚀 Starting comprehensive business registration tests...")
        print("=" * 60)
        
        try:
            # Test health check first
            await self.test_health_check()
            
            # Test each business type
            for business_type in ["restaurant", "store", "pharmacy", "kitchen"]:
                await self.test_single_business_type(business_type)
            
            # Summary
            print("📊 TEST SUMMARY")
            print("=" * 60)
            print(f"✅ Total users registered: {len(self.registered_users)}")
            print(f"✅ Total businesses created: {len(self.created_businesses)}")
            
            for business_type in self.registered_users:
                user = self.registered_users[business_type]
                business = self.created_businesses[business_type]
                pos_settings = self.BUSINESS_TEST_DATA[business_type]["pos_settings"]
                
                print(f"\n📋 {business_type.upper()}:")
                print(f"   User: {user['email']} (ID: {user['id']})")
                print(f"   Business: {business['name']} (ID: {business['id']})")
                print(f"   POS System: {pos_settings['systemType']}")
                print(f"   Collection: WB_{business_type}s")
            
            print(f"\n🎉 ALL TESTS PASSED! All business types successfully registered.")
            print("💾 Data stored in MongoDB Atlas with WB_ prefixes")
            print("🔧 POS settings configured for all business types")
            
        except Exception as e:
            print(f"❌ Test failed with error: {str(e)}")
            raise


async def main():
    """Main test execution function."""
    test_suite = TestBusinessRegistration()
    await test_suite.run_all_tests()


if __name__ == "__main__":
    # Run the tests
    print("🚀 Starting test execution...")
    try:
        asyncio.run(main())
        print("✅ Tests completed successfully!")
    except Exception as e:
        print(f"❌ Test execution failed: {e}")
        import traceback
        traceback.print_exc()
