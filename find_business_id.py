#!/usr/bin/env python3
"""
Script to find existing business IDs in the database
"""
import asyncio
import motor.motor_asyncio
from bson import ObjectId
import os
import json

async def find_businesses():
    """Find existing businesses in the database"""
    
    # Connect to MongoDB (using the same connection string as the backend)
    # You may need to adjust this connection string
    connection_string = os.getenv('MONGODB_CONNECTION_STRING', 
                                 'mongodb+srv://ghaythallahebiuae:9gZN2MKHbg7QI2jA@order-receiver-cluster.ffimw.mongodb.net/order_receiver_db?retryWrites=true&w=majority')
    
    try:
        client = motor.motor_asyncio.AsyncIOMotorClient(connection_string)
        db = client.order_receiver_db
        
        # Find all businesses
        businesses_collection = db.businesses
        businesses = await businesses_collection.find({}).to_list(length=10)
        
        print("📋 Found businesses in database:")
        print("=" * 50)
        
        if not businesses:
            print("❌ No businesses found in the database!")
            print("\n💡 Suggestion: Create a test business first")
            
            # Let's create a simple test business
            test_business = {
                "name": "Test Restaurant",
                "email": "test@restaurant.com",
                "owner_name": "Test Owner",
                "phone": "+971501234567",
                "address": "Test Address, Dubai, UAE",
                "business_type": "restaurant",
                "is_online": True,
                "is_active": True,
                "created_at": "2025-06-28T11:00:00Z"
            }
            
            result = await businesses_collection.insert_one(test_business)
            print(f"\n✅ Created test business with ID: {result.inserted_id}")
            return str(result.inserted_id)
        else:
            for business in businesses:
                print(f"🏪 Business ID: {business['_id']}")
                print(f"   Name: {business.get('name', 'N/A')}")
                print(f"   Email: {business.get('email', 'N/A')}")
                print(f"   Online: {business.get('is_online', False)}")
                print(f"   Active: {business.get('is_active', False)}")
                print("-" * 30)
            
            return str(businesses[0]['_id'])
        
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return None
    finally:
        client.close()

if __name__ == "__main__":
    business_id = asyncio.run(find_businesses())
    if business_id:
        print(f"\n🎯 Use this business ID for testing: {business_id}")
    else:
        print("\n❌ Could not find or create a business ID")
