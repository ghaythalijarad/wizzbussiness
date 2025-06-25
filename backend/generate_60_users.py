#!/usr/bin/env python3
"""
Direct Registration System for 60 New Users
Creates 15 users each for restaurant, store, pharmacy, and kitchen business types.
Each business gets default categories and realistic items.

Usage: python generate_60_users.py
"""
import asyncio
import httpx
import json
import random
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class UserDataGenerator:
    """Generates realistic user and business data."""
    
    # Iraqi cities and districts
    IRAQI_LOCATIONS = [
        {"city": "Baghdad", "district": "Karrada", "neighbourhood": "Al-Jadriya"},
        {"city": "Baghdad", "district": "Mansour", "neighbourhood": "Al-Mansour"},
        {"city": "Baghdad", "district": "Rusafa", "neighbourhood": "Al-Rusafa"},
        {"city": "Baghdad", "district": "Karkh", "neighbourhood": "Al-Karkh"},
        {"city": "Basra", "district": "Ashar", "neighbourhood": "Al-Ashar"},
        {"city": "Basra", "district": "Hayaniya", "neighbourhood": "Al-Hayaniya"},
        {"city": "Erbil", "district": "Ainkawa", "neighbourhood": "Ainkawa"},
        {"city": "Erbil", "district": "Sami Rahman", "neighbourhood": "Sami Rahman"},
        {"city": "Sulaymaniyah", "district": "Malik Mahmud", "neighbourhood": "Malik Mahmud"},
        {"city": "Kirkuk", "district": "Azadi", "neighbourhood": "Azadi"},
        {"city": "Najaf", "district": "Old City", "neighbourhood": "Old Najaf"},
        {"city": "Karbala", "district": "City Center", "neighbourhood": "Al-Husayniyah"}
    ]
    
    # Business names by type
    BUSINESS_NAMES = {
        "restaurant": [
            "Al-Fayhaa Restaurant", "Baghdad Grill", "Mesopotamia Kitchen", "Tigris Dining",
            "Golden Palace Restaurant", "Al-Rashid Cuisine", "Babylon Bistro", "Cedar Restaurant",
            "Al-Salam Eatery", "Heritage Kitchen", "River View Restaurant", "Al-Nakheel Dining",
            "Royal Iraqi Kitchen", "Al-Andalus Restaurant", "Euphrates Grill"
        ],
        "store": [
            "Al-Noor Supermarket", "Baghdad General Store", "City Center Market", "Al-Farouk Shop",
            "Modern Mart", "Al-Rasheed Store", "Family Market", "Golden Shop",
            "Al-Salam Store", "Victory Market", "Al-Nakheel Shop", "Heritage Store",
            "Central Market", "Al-Andalus Store", "Tigris Shopping"
        ],
        "pharmacy": [
            "Al-Shifa Pharmacy", "Baghdad Medical", "Health Plus Pharmacy", "Al-Noor Drugstore",
            "Care Pharmacy", "Al-Rasheed Medical", "Wellness Pharmacy", "Al-Salam Drugs",
            "Family Pharmacy", "Al-Nakheel Medical", "Modern Pharmacy", "Al-Andalus Health",
            "Victory Pharmacy", "Heritage Medical", "Central Drugstore"
        ],
        "kitchen": [
            "Al-Bayt Kitchen", "Home Style Cooking", "Mama's Kitchen", "Traditional Kitchen",
            "Al-Dar Kitchen", "Heritage Cooking", "Family Kitchen", "Al-Salam Cooking",
            "Home Delights", "Al-Nakheel Kitchen", "Traditional Flavors", "Al-Andalus Kitchen",
            "Baghdad Home Kitchen", "Authentic Kitchen", "Classic Home Cooking"
        ]
    }
    
    # Owner names
    OWNER_NAMES = [
        "Ahmed Al-Baghdadi", "Fatima Al-Basri", "Mohammed Al-Kurdi", "Zainab Al-Najafi",
        "Ali Al-Karbali", "Sarah Al-Mosuli", "Hassan Al-Tikrit", "Maryam Al-Kirkuki",
        "Omar Al-Fallujahi", "Noor Al-Ramadi", "Yusuf Al-Nasiriyahi", "Layla Al-Diwaniyahi",
        "Khalid Al-Sammari", "Amal Al-Hillawi", "Saad Al-Maysan", "Huda Al-Wasiti",
        "Tariq Al-Anbar", "Rana Al-Babylon", "Salam Al-Qadisiyah", "Nadia Al-Muthanna"
    ]
    
    # Street names
    STREET_NAMES = [
        "Al-Rasheed Street", "Haifa Street", "Al-Mutanabbi Street", "Palestine Street",
        "Airport Road", "Al-Mansour Street", "Al-Jadiriyah Bridge Road", "Al-Karrada Street",
        "Al-Kadhimiya Street", "Al-A'zamiyah Street", "Al-Bayaa Road", "Al-Dora Street"
    ]

    @classmethod
    def generate_user_data(cls, business_type: str, index: int) -> Dict:
        """Generate realistic user registration data."""
        timestamp = int(time.time()) + index
        location = random.choice(cls.IRAQI_LOCATIONS)
        business_name = cls.BUSINESS_NAMES[business_type][index % len(cls.BUSINESS_NAMES[business_type])]
        owner_name = cls.OWNER_NAMES[index % len(cls.OWNER_NAMES)]
        street = random.choice(cls.STREET_NAMES)
        
        # Generate birth date (25-65 years old)
        birth_year = random.randint(1959, 1999)
        birth_month = random.randint(1, 12)
        birth_day = random.randint(1, 28)
        birth_date = f"{birth_year}-{birth_month:02d}-{birth_day:02d}"
        
        # Generate phone number
        phone_prefix = random.choice(["750", "751", "770", "771", "780", "781", "790", "791"])
        phone_suffix = random.randint(1000000, 9999999)
        
        return {
            "email": f"{business_type}_{index}_{timestamp}@example.com",
            "password": "SecurePass123!",
            "business_name": business_name,
            "business_type": business_type,
            "phone_number": f"+964{phone_prefix}{phone_suffix}",
            "owner_name": owner_name,
            "national_id": f"{random.randint(100000000, 999999999)}",
            "date_of_birth": birth_date,
            "address": {
                "country": "Iraq",
                "city": location["city"],
                "district": location["district"],
                "neighbourhood": location["neighbourhood"],
                "street": street,
                "building_number": str(random.randint(1, 999)),
                "zip_code": f"{random.randint(10000, 99999)}"
            }
        }


class ItemGenerator:
    """Generates realistic items for each business type."""
    
    RESTAURANT_ITEMS = {
        "Appetizers": [
            {"name": "Hummus", "price": 3.50, "description": "Traditional chickpea dip with tahini"},
            {"name": "Fattoush", "price": 4.00, "description": "Mixed salad with toasted bread pieces"},
            {"name": "Kibbeh", "price": 5.00, "description": "Fried bulgur and meat balls"},
            {"name": "Baba Ganoush", "price": 3.75, "description": "Roasted eggplant dip"},
            {"name": "Labneh", "price": 3.25, "description": "Strained yogurt with olive oil"}
        ],
        "Main Courses": [
            {"name": "Masgouf", "price": 15.00, "description": "Grilled carp fish - Iraqi specialty"},
            {"name": "Kebab", "price": 12.50, "description": "Grilled lamb skewers with rice"},
            {"name": "Dolma", "price": 8.00, "description": "Stuffed grape leaves with rice and herbs"},
            {"name": "Biryani", "price": 10.00, "description": "Spiced rice with chicken or lamb"},
            {"name": "Qozi", "price": 18.00, "description": "Roasted lamb with rice and almonds"}
        ],
        "Beverages": [
            {"name": "Chai", "price": 1.50, "description": "Traditional Iraqi tea"},
            {"name": "Arabic Coffee", "price": 2.00, "description": "Strong cardamom coffee"},
            {"name": "Ayran", "price": 2.50, "description": "Yogurt drink with mint"},
            {"name": "Fresh Orange Juice", "price": 3.00, "description": "Freshly squeezed orange juice"},
            {"name": "Tamarind Juice", "price": 2.75, "description": "Sweet and tangy tamarind drink"}
        ],
        "Desserts": [
            {"name": "Baklava", "price": 4.00, "description": "Layered pastry with honey and nuts"},
            {"name": "Knafeh", "price": 5.00, "description": "Sweet cheese pastry with syrup"},
            {"name": "Ma'moul", "price": 3.50, "description": "Date-filled semolina cookies"},
            {"name": "Halva", "price": 3.00, "description": "Sweet tahini confection"},
            {"name": "Rice Pudding", "price": 3.25, "description": "Creamy rice pudding with cinnamon"}
        ]
    }
    
    STORE_ITEMS = {
        "Groceries": [
            {"name": "Rice - 5kg", "price": 8.50, "description": "Premium basmati rice"},
            {"name": "Olive Oil - 1L", "price": 12.00, "description": "Extra virgin olive oil"},
            {"name": "Bulgur - 2kg", "price": 5.50, "description": "Fine bulgur wheat"},
            {"name": "Lentils - 1kg", "price": 3.50, "description": "Red lentils"},
            {"name": "Dates - 500g", "price": 6.00, "description": "Premium Medjool dates"}
        ],
        "Beverages": [
            {"name": "Water Bottle - 1.5L", "price": 0.75, "description": "Pure drinking water"},
            {"name": "Coca Cola - 330ml", "price": 1.25, "description": "Carbonated soft drink"},
            {"name": "Orange Juice - 1L", "price": 3.50, "description": "100% orange juice"},
            {"name": "Energy Drink", "price": 2.50, "description": "Energy boost drink"},
            {"name": "Mineral Water - 6 pack", "price": 4.00, "description": "Natural mineral water"}
        ],
        "Snacks": [
            {"name": "Chips - Assorted", "price": 2.00, "description": "Various flavored chips"},
            {"name": "Cookies Pack", "price": 3.50, "description": "Assorted cookies"},
            {"name": "Nuts Mix", "price": 5.50, "description": "Mixed roasted nuts"},
            {"name": "Chocolate Bar", "price": 2.25, "description": "Milk chocolate bar"},
            {"name": "Crackers", "price": 2.75, "description": "Salted crackers"}
        ],
        "Household": [
            {"name": "Dish Soap", "price": 4.50, "description": "Concentrated dish washing liquid"},
            {"name": "Toilet Paper - 12 rolls", "price": 8.00, "description": "Soft toilet tissue"},
            {"name": "Laundry Detergent", "price": 12.50, "description": "Concentrated laundry powder"},
            {"name": "Kitchen Towels", "price": 6.00, "description": "Absorbent paper towels"},
            {"name": "Hand Soap", "price": 3.25, "description": "Antibacterial hand soap"}
        ]
    }
    
    PHARMACY_ITEMS = {
        "Medications": [
            {"name": "Paracetamol 500mg", "price": 3.50, "description": "Pain relief and fever reducer"},
            {"name": "Ibuprofen 400mg", "price": 4.00, "description": "Anti-inflammatory medication"},
            {"name": "Aspirin 325mg", "price": 2.50, "description": "Pain relief and blood thinner"},
            {"name": "Cough Syrup", "price": 6.50, "description": "Relief for cough and cold"},
            {"name": "Antihistamine", "price": 5.00, "description": "Allergy relief medication"}
        ],
        "Vitamins": [
            {"name": "Vitamin C - 1000mg", "price": 8.00, "description": "Immune system support"},
            {"name": "Vitamin D3", "price": 12.00, "description": "Bone health support"},
            {"name": "Multivitamin", "price": 15.50, "description": "Complete vitamin complex"},
            {"name": "Omega-3", "price": 18.00, "description": "Heart and brain health"},
            {"name": "Iron Supplement", "price": 9.50, "description": "Iron deficiency support"}
        ],
        "Personal Care": [
            {"name": "Hand Sanitizer", "price": 4.50, "description": "70% alcohol hand sanitizer"},
            {"name": "Face Masks - 50 pack", "price": 12.50, "description": "Disposable surgical masks"},
            {"name": "Thermometer", "price": 25.00, "description": "Digital body thermometer"},
            {"name": "First Aid Kit", "price": 35.00, "description": "Complete first aid supplies"},
            {"name": "Blood Pressure Monitor", "price": 85.00, "description": "Digital BP monitor"}
        ],
        "Baby Care": [
            {"name": "Baby Diapers - Size 3", "price": 22.00, "description": "Ultra-soft baby diapers"},
            {"name": "Baby Formula", "price": 28.50, "description": "Infant nutrition formula"},
            {"name": "Baby Wipes", "price": 8.50, "description": "Gentle baby wipes"},
            {"name": "Baby Shampoo", "price": 12.00, "description": "Tear-free baby shampoo"},
            {"name": "Diaper Cream", "price": 15.00, "description": "Protective diaper rash cream"}
        ]
    }
    
    KITCHEN_ITEMS = {
        "Home Meals": [
            {"name": "Family Biryani", "price": 25.00, "description": "Serves 4-6 people, chicken biryani"},
            {"name": "Stuffed Grape Leaves", "price": 18.00, "description": "10 pieces of homemade dolma"},
            {"name": "Lentil Soup", "price": 8.50, "description": "Traditional Iraqi lentil soup for 4"},
            {"name": "Kabsa Rice", "price": 22.00, "description": "Spiced rice with lamb, serves 4-6"},
            {"name": "Vegetable Stew", "price": 15.00, "description": "Mixed vegetable stew, serves 4"}
        ],
        "Desserts": [
            {"name": "Homemade Baklava", "price": 12.00, "description": "6 pieces of fresh baklava"},
            {"name": "Date Ma'moul", "price": 15.00, "description": "12 traditional date cookies"},
            {"name": "Rice Pudding", "price": 10.00, "description": "Serves 4, creamy rice pudding"},
            {"name": "Sesame Halva", "price": 8.50, "description": "Traditional sesame halva"},
            {"name": "Honey Cakes", "price": 14.00, "description": "6 small honey-soaked cakes"}
        ],
        "Breakfast": [
            {"name": "Iraqi Breakfast Platter", "price": 12.50, "description": "Eggs, cheese, bread, and tea"},
            {"name": "Falafel Plate", "price": 8.00, "description": "6 pieces falafel with tahini"},
            {"name": "Cheese Manakish", "price": 6.50, "description": "Flatbread with cheese and herbs"},
            {"name": "Ful Medames", "price": 7.50, "description": "Fava beans with bread and pickles"},
            {"name": "Shakshuka", "price": 9.00, "description": "Eggs in tomato sauce with bread"}
        ],
        "Beverages": [
            {"name": "Fresh Mint Tea", "price": 2.50, "description": "Traditional mint tea"},
            {"name": "Arabic Coffee Set", "price": 8.00, "description": "Coffee with dates and sweets"},
            {"name": "Fresh Lemonade", "price": 3.50, "description": "Fresh squeezed lemonade"},
            {"name": "Rose Water Drink", "price": 4.00, "description": "Refreshing rose water beverage"},
            {"name": "Tamarind Drink", "price": 3.75, "description": "Sweet tamarind refresher"}
        ]
    }

    @classmethod
    def get_items_for_business_type(cls, business_type: str) -> Dict[str, List[Dict]]:
        """Get items based on business type."""
        items_map = {
            "restaurant": cls.RESTAURANT_ITEMS,
            "store": cls.STORE_ITEMS,
            "pharmacy": cls.PHARMACY_ITEMS,
            "kitchen": cls.KITCHEN_ITEMS
        }
        return items_map.get(business_type, {})


class DirectRegistrationSystem:
    """Main system for creating 60 users with direct registration."""
    
    def __init__(self, base_url: str = "http://localhost:8001"):
        self.base_url = base_url
        self.registered_users: List[Dict] = []
        self.created_businesses: List[Dict] = []
        self.success_count = 0
        self.error_count = 0
        
    async def health_check(self) -> bool:
        """Check if the API is running."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{self.base_url}/health")
                if response.status_code == 200:
                    logger.info("✅ API health check passed")
                    return True
                else:
                    logger.error(f"❌ API health check failed: {response.status_code}")
                    return False
        except Exception as e:
            logger.error(f"❌ Failed to connect to API: {e}")
            return False
    
    async def register_user(self, user_data: Dict) -> Optional[Dict]:
        """Register a single user."""
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    f"{self.base_url}/auth/register",
                    json=user_data,
                    headers={"Content-Type": "application/json"}
                )
                
                if response.status_code in [200, 201]:
                    user = response.json()
                    logger.info(f"✅ User registered: {user_data['business_name']} ({user_data['business_type']})")
                    self.success_count += 1
                    return user
                else:
                    logger.error(f"❌ Registration failed for {user_data['business_name']}: {response.text}")
                    self.error_count += 1
                    return None
                    
        except Exception as e:
            logger.error(f"❌ Exception during registration of {user_data['business_name']}: {e}")
            self.error_count += 1
            return None
    
    async def login_user(self, email: str, password: str) -> Optional[str]:
        """Login user and get access token."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/auth/jwt/login",
                    data={"username": email, "password": password},
                    headers={"Content-Type": "application/x-www-form-urlencoded"}
                )
                
                if response.status_code == 200:
                    token_data = response.json()
                    return token_data["access_token"]
                else:
                    logger.error(f"❌ Login failed for {email}: {response.text}")
                    return None
                    
        except Exception as e:
            logger.error(f"❌ Exception during login for {email}: {e}")
            return None
    
    async def get_user_businesses(self, access_token: str) -> List[Dict]:
        """Get businesses for a user."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/businesses/my-businesses",
                    headers={"Authorization": f"Bearer {access_token}"}
                )
                
                if response.status_code == 200:
                    return response.json()
                else:
                    logger.error(f"❌ Failed to get businesses: {response.text}")
                    return []
                    
        except Exception as e:
            logger.error(f"❌ Exception getting businesses: {e}")
            return []
    
    async def create_item(self, business_id: str, access_token: str, item_data: Dict) -> bool:
        """Create an item for a business."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/api/items/",
                    json=item_data,
                    headers={"Authorization": f"Bearer {access_token}"},
                    params={"business_id": business_id}
                )
                
                if response.status_code in [200, 201]:
                    return True
                else:
                    logger.warning(f"⚠️ Failed to create item {item_data['name']}: {response.text}")
                    return False
                    
        except Exception as e:
            logger.warning(f"⚠️ Exception creating item {item_data['name']}: {e}")
            return False
    
    async def get_business_categories(self, business_id: str, access_token: str) -> List[Dict]:
        """Get categories for a business."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/api/categories/",
                    headers={"Authorization": f"Bearer {access_token}"},
                    params={"business_id": business_id}
                )
                
                if response.status_code == 200:
                    return response.json()
                else:
                    logger.warning(f"⚠️ Failed to get categories: {response.text}")
                    return []
                    
        except Exception as e:
            logger.warning(f"⚠️ Exception getting categories: {e}")
            return []
    
    async def add_items_to_business(self, business: Dict, access_token: str, business_type: str):
        """Add realistic items to a business based on its type."""
        business_id = business["id"]
        business_name = business["name"]
        
        logger.info(f"📝 Adding items to {business_name}...")
        
        # Get business categories
        categories = await self.get_business_categories(business_id, access_token)
        if not categories:
            logger.warning(f"⚠️ No categories found for {business_name}")
            return
        
        # Create a mapping of category names to IDs
        category_map = {cat["name"]: cat["id"] for cat in categories}
        
        # Get items for this business type
        items_by_category = ItemGenerator.get_items_for_business_type(business_type)
        
        items_created = 0
        for category_name, items in items_by_category.items():
            if category_name in category_map:
                category_id = category_map[category_name]
                
                # Add 3-5 items per category
                items_to_add = random.sample(items, min(len(items), random.randint(3, 5)))
                
                for item in items_to_add:
                    item_data = {
                        "name": item["name"],
                        "description": item["description"],
                        "price": item["price"],
                        "category_id": category_id,
                        "is_available": True,
                        "stock_quantity": random.randint(10, 100)
                    }
                    
                    if await self.create_item(business_id, access_token, item_data):
                        items_created += 1
                        
                    # Small delay to avoid overwhelming the API
                    await asyncio.sleep(0.1)
        
        logger.info(f"✅ Added {items_created} items to {business_name}")
    
    async def process_user_registration(self, user_data: Dict) -> bool:
        """Process complete user registration including business setup."""
        business_type = user_data["business_type"]
        business_name = user_data["business_name"]
        
        logger.info(f"🔄 Processing {business_name} ({business_type})...")
        
        # Step 1: Register user
        user = await self.register_user(user_data)
        if not user:
            return False
        
        self.registered_users.append(user)
        
        # Step 2: Login to get access token
        access_token = await self.login_user(user_data["email"], user_data["password"])
        if not access_token:
            return False
        
        # Small delay for business creation
        await asyncio.sleep(1)
        
        # Step 3: Get automatically created business
        businesses = await self.get_user_businesses(access_token)
        if not businesses:
            logger.warning(f"⚠️ No businesses found for {business_name}")
            return False
        
        business = businesses[0]  # Take the first (and should be only) business
        self.created_businesses.append(business)
        
        # Step 4: Add items to the business
        await self.add_items_to_business(business, access_token, business_type)
        
        logger.info(f"✅ Completed setup for {business_name}")
        return True
    
    async def generate_all_users(self):
        """Generate all 60 users (15 per business type)."""
        business_types = ["restaurant", "store", "pharmacy", "kitchen"]
        users_per_type = 15
        
        logger.info(f"🚀 Starting generation of {users_per_type * len(business_types)} users...")
        logger.info(f"📊 Target: {users_per_type} each of {', '.join(business_types)}")
        
        # Check API health first
        if not await self.health_check():
            logger.error("❌ API health check failed. Cannot proceed.")
            return
        
        start_time = time.time()
        
        for business_type in business_types:
            logger.info(f"\n🏢 Creating {users_per_type} {business_type} businesses...")
            
            for i in range(users_per_type):
                user_data = UserDataGenerator.generate_user_data(business_type, i)
                await self.process_user_registration(user_data)
                
                # Progress indicator
                completed = (business_types.index(business_type) * users_per_type) + i + 1
                total = users_per_type * len(business_types)
                logger.info(f"📈 Progress: {completed}/{total} ({(completed/total)*100:.1f}%)")
                
                # Small delay between users
                await asyncio.sleep(0.5)
        
        # Summary
        end_time = time.time()
        duration = end_time - start_time
        
        logger.info(f"\n🎉 GENERATION COMPLETE!")
        logger.info(f"⏱️  Total time: {duration:.1f} seconds")
        logger.info(f"✅ Successfully created: {self.success_count} users")
        logger.info(f"❌ Failed: {self.error_count} users")
        logger.info(f"🏢 Businesses created: {len(self.created_businesses)}")
        
        # Business type breakdown
        logger.info(f"\n📊 Business Type Breakdown:")
        for business_type in business_types:
            count = len([b for b in self.created_businesses if b["business_type"] == business_type])
            logger.info(f"   {business_type.title()}: {count} businesses")
        
        if self.success_count > 0:
            logger.info(f"\n🎯 Sample businesses created:")
            for i, business in enumerate(self.created_businesses[:5]):
                logger.info(f"   {i+1}. {business['name']} ({business['business_type']})")
            if len(self.created_businesses) > 5:
                logger.info(f"   ... and {len(self.created_businesses) - 5} more")


async def main():
    """Main execution function."""
    logger.info("🚀 Direct Registration System for 60 Users")
    logger.info("=" * 50)
    
    system = DirectRegistrationSystem()
    await system.generate_all_users()
    
    logger.info("\n" + "=" * 50)
    logger.info("✅ All done! Your system now has 60 new users with businesses and items.")


if __name__ == "__main__":
    asyncio.run(main())
