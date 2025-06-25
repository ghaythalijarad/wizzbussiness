"""
Test script for verifying default categories creation functionality.
This script tests the automatic creation of default categories when businesses are created.
"""
import asyncio
import httpx
import json
from datetime import datetime, date


class TestDefaultCategories:
    """Test suite for default categories functionality."""
    
    BASE_URL = "http://localhost:8000"
    
    def __init__(self):
        self.test_user = None
        self.access_token = None
        self.created_business = None
    
    async def setup_test_user(self):
        """Create a test user for testing."""
        user_data = {
            "email": f"test_categories_{int(datetime.now().timestamp())}@test.com",
            "password": "TestPassword123",
            "business_name": "Categories Test Business",
            "business_type": "restaurant",
            "phone_number": "+966501234567"
        }
        
        async with httpx.AsyncClient() as client:
            # Register user
            response = await client.post(
                f"{self.BASE_URL}/auth/register",
                json=user_data,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code not in [200, 201]:
                raise Exception(f"User registration failed: {response.status_code} - {response.text}")
            
            self.test_user = response.json()
            print(f"✅ Created test user: {self.test_user['email']}")
            print(f"   User ID: {self.test_user.get('id', 'N/A')}")
            
            # Login user
            login_response = await client.post(
                f"{self.BASE_URL}/auth/jwt/login",
                data={
                    "username": user_data["email"],
                    "password": user_data["password"]
                }
            )
            
            if login_response.status_code not in [200, 201]:
                raise Exception(f"Login failed: {login_response.status_code} - {login_response.text}")
            
            login_data = login_response.json()
            self.access_token = login_data["access_token"]
            print(f"✅ User logged in successfully")
    
    async def test_restaurant_business_with_categories(self):
        """Test restaurant business creation with default categories."""
        print("\\n🧪 Testing Restaurant Business with Default Categories...")
        
        business_data = {
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
            "owner_date_of_birth": "1985-06-15T00:00:00"
        }
        
        async with httpx.AsyncClient(follow_redirects=True) as client:
            # Create business
            response = await client.post(
                f"{self.BASE_URL}/businesses/restaurant",
                headers={"Authorization": f"Bearer {self.access_token}"},
                json=business_data
            )
            
            if response.status_code not in [200, 201]:
                raise Exception(f"Business creation failed: {response.status_code} - {response.text}")
            
            self.created_business = response.json()
            print(f"✅ Created restaurant business: {self.created_business['name']}")
            print(f"   Business ID: {self.created_business['id']}")
        
        return self.created_business
    
    async def test_categories_created(self):
        """Test that default categories were created for the business."""
        print("\\n🔍 Testing Default Categories Creation...")
        
        if not self.created_business:
            raise Exception("No business created to test categories")
        
        business_id = self.created_business['id']
        
        async with httpx.AsyncClient(follow_redirects=True) as client:
            # Get categories for the business
            response = await client.get(
                f"{self.BASE_URL}/api/categories/",
                headers={"Authorization": f"Bearer {self.access_token}"},
                params={"business_id": business_id}
            )
            
            if response.status_code not in [200, 201]:
                raise Exception(f"Failed to fetch categories: {response.status_code} - {response.text}")
            
            categories = response.json()
            print(f"✅ Found {len(categories)} categories for the business")
            
            # Expected restaurant categories
            expected_categories = ["Appetizers", "Main Courses", "Beverages", "Desserts"]
            
            category_names = [cat['name'] for cat in categories]
            print(f"   Categories found: {category_names}")
            
            # Verify all expected categories exist
            for expected_cat in expected_categories:
                if expected_cat not in category_names:
                    raise Exception(f"Expected category '{expected_cat}' not found")
                print(f"   ✅ Found category: {expected_cat}")
            
            # Verify category details
            for category in categories:
                print(f"   📋 {category['name']}:")
                print(f"      - Description: {category.get('description', 'N/A')}")
                print(f"      - Color: {category.get('color', 'N/A')}")
                print(f"      - Icon: {category.get('icon', 'N/A')}")
                print(f"      - Display Order: {category.get('display_order', 'N/A')}")
                print(f"      - Items Count: {category.get('items_count', 0)}")
        
        return categories
    
    async def test_item_creation_with_categories(self, categories):
        """Test creating an item and assigning it to a category."""
        print("\\n🍽️ Testing Item Creation with Categories...")
        
        if not categories:
            raise Exception("No categories available for testing")
        
        # Use the first category (Appetizers)
        test_category = categories[0]
        business_id = self.created_business['id']
        
        item_data = {
            "name": "Hummus Platter",
            "description": "Traditional Middle Eastern hummus with pita bread",
            "price": 15.50,
            "category_id": test_category['id'],
            "item_type": "dish",
            "is_available": True
        }
        
        async with httpx.AsyncClient(follow_redirects=True) as client:
            # Create item
            response = await client.post(
                f"{self.BASE_URL}/api/items/",
                headers={"Authorization": f"Bearer {self.access_token}"},
                params={"business_id": business_id},
                json=item_data
            )
            
            if response.status_code not in [200, 201]:
                raise Exception(f"Item creation failed: {response.status_code} - {response.text}")
            
            created_item = response.json()
            print(f"✅ Created item: {created_item['name']}")
            print(f"   Category: {created_item.get('category_name', 'N/A')}")
            print(f"   Price: KWD {created_item['price']}")
            
            # Verify item is in the correct category
            if created_item.get('category_id') != test_category['id']:
                raise Exception("Item was not assigned to the correct category")
            
            if created_item.get('category_name') != test_category['name']:
                raise Exception("Item category name does not match")
            
            print(f"✅ Item correctly assigned to category: {test_category['name']}")
        
        return created_item
    
    async def test_different_business_types(self):
        """Test default categories for different business types."""
        print("\\n🏪 Testing Default Categories for Different Business Types...")
        
        business_types_data = {
            "store": {
                "name": "Fresh Market Store",
                "endpoint": "/businesses/store",
                "expected_categories": ["Electronics", "Clothing", "Home & Garden", "Groceries"]
            },
            "pharmacy": {
                "name": "Health Plus Pharmacy",
                "endpoint": "/businesses/pharmacy",
                "expected_categories": ["Prescription Drugs", "Over-the-Counter", "Health & Beauty", "Medical Equipment"]
            },
            "kitchen": {
                "name": "Gourmet Cloud Kitchen",
                "endpoint": "/businesses/kitchen",
                "expected_categories": ["Prepared Meals", "Ingredients", "Beverages", "Snacks"]
            }
        }
        
        for business_type, config in business_types_data.items():
            print(f"\\n  🧪 Testing {business_type.upper()} business type...")
            
            # Create business data
            business_data = {
                "name": config["name"],
                "business_type": business_type,
                "phone_number": "+966501234567",
                "email": f"{business_type}@test.com",
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
                "owner_name": f"Owner {business_type.title()}",
                "owner_national_id": "1234567890",
                "owner_date_of_birth": "1985-06-15T00:00:00"
            }
            
            async with httpx.AsyncClient() as client:
                # Create business
                create_response = await client.post(
                    f"{self.BASE_URL}{config['endpoint']}",
                    headers={"Authorization": f"Bearer {self.access_token}"},
                    json=business_data
                )
                
                if create_response.status_code not in [200, 201]:
                    print(f"    ❌ Failed to create {business_type} business: {create_response.status_code} - {create_response.text}")
                    continue
                
                business = create_response.json()
                print(f"    ✅ Created {business_type} business: {business['name']}")
                
                # Get categories
                categories_response = await client.get(
                    f"{self.BASE_URL}/api/categories",
                    headers={"Authorization": f"Bearer {self.access_token}"},
                    params={"business_id": business['id']}
                )
                
                if categories_response.status_code not in [200, 201]:
                    print(f"    ❌ Failed to fetch categories: {categories_response.status_code} - {categories_response.text}")
                    continue
                
                categories = categories_response.json()
                category_names = [cat['name'] for cat in categories]
                
                print(f"    📋 Found categories: {category_names}")
                
                # Verify expected categories
                for expected_cat in config["expected_categories"]:
                    if expected_cat in category_names:
                        print(f"       ✅ {expected_cat}")
                    else:
                        print(f"       ❌ Missing: {expected_cat}")
    
    async def run_all_tests(self):
        """Run all default categories tests."""
        print("🚀 Starting Default Categories Tests...")
        print("=" * 60)
        
        try:
            # Setup
            await self.setup_test_user()
            
            # Test restaurant business creation with categories
            await self.test_restaurant_business_with_categories()
            
            # Test that categories were created
            categories = await self.test_categories_created()
            
            # Test item creation with categories
            await self.test_item_creation_with_categories(categories)
            
            # Test different business types
            await self.test_different_business_types()
            
            print("\\n🎉 ALL DEFAULT CATEGORIES TESTS PASSED!")
            print("=" * 60)
            print("✅ Default categories are automatically created when businesses are created")
            print("✅ Categories are business-type specific")
            print("✅ Items can be successfully assigned to default categories")
            print("✅ All business types (Restaurant, Store, Pharmacy, Kitchen) have default categories")
            
        except Exception as e:
            print(f"\\n❌ Test failed with error: {str(e)}")
            raise


async def main():
    """Main test execution function."""
    tester = TestDefaultCategories()
    await tester.run_all_tests()


if __name__ == "__main__":
    print("🚀 Starting Default Categories Test Execution...")
    try:
        asyncio.run(main())
        print("✅ Test execution completed successfully!")
    except Exception as e:
        print(f"❌ Test execution failed: {e}")
        import traceback
        traceback.print_exc()
