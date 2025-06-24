#!/usr/bin/env python3
"""
Data migration script to populate WB_businesses collection with existing business data.
This script implements the dual-storage approach by copying data from type-specific 
collections to the unified WB_businesses collection.
"""
import asyncio
import os
import sys
from typing import List

# Add the backend app path to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.core.database import db_manager
from app.models.business import Business, Restaurant, Store, Pharmacy, Kitchen


class BusinessDataMigration:
    """Data migration service for business collections."""
    
    def __init__(self):
        self.migrated_count = 0
        self.error_count = 0
        self.errors = []
    
    async def migrate_businesses_from_collection(self, collection_model, collection_name: str):
        """Migrate businesses from a specific collection to unified collection."""
        print(f"\n🔄 Migrating {collection_name}...")
        
        try:
            # Get all businesses from the specific collection
            businesses = await collection_model.find().to_list()
            
            if not businesses:
                print(f"   ℹ️  No businesses found in {collection_name}")
                return
            
            for business in businesses:
                try:
                    # Check if business already exists in unified collection
                    existing = await Business.get(business.id)
                    
                    if existing:
                        print(f"   ⚠️  Business {business.name} already exists in unified collection")
                        continue
                    
                    # Create new business in unified collection with same ID
                    unified_business_data = {
                        "owner_id": business.owner_id,
                        "owner_name": business.owner_name,
                        "owner_national_id": business.owner_national_id,
                        "owner_date_of_birth": business.owner_date_of_birth,
                        "name": business.name,
                        "business_type": business.business_type,
                        "phone_number": business.phone_number,
                        "email": business.email,
                        "website": business.website,
                        "address": business.address,
                        "status": business.status,
                        "is_verified": business.is_verified,
                        "is_online": business.is_online,
                        "settings": business.settings,
                        "created_at": business.created_at,
                        "updated_at": business.updated_at,
                        "documents": business.documents,
                    }
                    
                    # Create unified business with the same ID
                    unified_business = Business(**unified_business_data)
                    unified_business.id = business.id
                    await unified_business.save()
                    
                    self.migrated_count += 1
                    print(f"   ✅ Migrated: {business.name} (ID: {business.id})")
                    
                except Exception as e:
                    self.error_count += 1
                    error_msg = f"Error migrating business {business.name}: {str(e)}"
                    self.errors.append(error_msg)
                    print(f"   ❌ {error_msg}")
            
        except Exception as e:
            error_msg = f"Error accessing {collection_name}: {str(e)}"
            self.errors.append(error_msg)
            print(f"   ❌ {error_msg}")
    
    async def run_migration(self):
        """Run the complete migration process."""
        print("🚀 Starting Business Data Migration")
        print("=" * 60)
        print("Purpose: Populate WB_businesses collection with existing business data")
        print("Approach: Dual-storage (specific collections + unified collection)")
        print("=" * 60)
        
        # Initialize database connection
        try:
            await db_manager.connect()
            
            # Initialize Beanie ODM with document models
            from beanie import init_beanie
            await init_beanie(database=db_manager.database, document_models=[Business, Restaurant, Store, Pharmacy, Kitchen])
            
            print("✅ Database connection established")
        except Exception as e:
            print(f"❌ Failed to connect to database: {e}")
            return
        
        # Migration tasks
        migration_tasks = [
            (Restaurant, "WB_restaurants"),
            (Store, "WB_stores"),
            (Pharmacy, "WB_pharmacies"),
            (Kitchen, "WB_kitchens")
        ]
        
        # Run migrations
        for model, collection_name in migration_tasks:
            await self.migrate_businesses_from_collection(model, collection_name)
        
        # Summary
        print(f"\n📊 MIGRATION SUMMARY")
        print("=" * 60)
        print(f"✅ Businesses migrated: {self.migrated_count}")
        print(f"❌ Errors encountered: {self.error_count}")
        
        if self.errors:
            print(f"\n🔍 ERROR DETAILS:")
            for error in self.errors:
                print(f"   • {error}")
        
        # Verify the migration
        await self.verify_migration()
        
        # Close database connection
        await db_manager.disconnect()
        print("\n🔐 Database connection closed")
    
    async def verify_migration(self):
        """Verify the migration was successful."""
        print(f"\n🔍 VERIFYING MIGRATION")
        print("-" * 60)
        
        try:
            # Count businesses in unified collection
            unified_count = len(await Business.find().to_list())
            print(f"📊 Total businesses in WB_businesses: {unified_count}")
            
            # Count businesses in each specific collection
            restaurant_count = len(await Restaurant.find().to_list())
            store_count = len(await Store.find().to_list())
            pharmacy_count = len(await Pharmacy.find().to_list())
            kitchen_count = len(await Kitchen.find().to_list())
            
            total_specific = restaurant_count + store_count + pharmacy_count + kitchen_count
            
            print(f"📊 Total in specific collections: {total_specific}")
            print(f"   • Restaurants: {restaurant_count}")
            print(f"   • Stores: {store_count}")
            print(f"   • Pharmacies: {pharmacy_count}")
            print(f"   • Kitchens: {kitchen_count}")
            
            if unified_count == total_specific:
                print("✅ MIGRATION SUCCESSFUL: Counts match!")
            else:
                print(f"⚠️  Count mismatch: {unified_count} vs {total_specific}")
                
            # Sample verification
            if unified_count > 0:
                sample_business = await Business.find().first_or_none()
                if sample_business:
                    print(f"\n📋 SAMPLE BUSINESS IN UNIFIED COLLECTION:")
                    print(f"   • Name: {sample_business.name}")
                    print(f"   • Type: {sample_business.business_type}")
                    print(f"   • ID: {sample_business.id}")
                    print(f"   • Status: {sample_business.status}")
                    
        except Exception as e:
            print(f"❌ Error during verification: {e}")


async def main():
    """Main migration function."""
    migration = BusinessDataMigration()
    await migration.run_migration()


if __name__ == "__main__":
    print("🏢 Business Data Migration Tool")
    print("This will populate the WB_businesses collection with existing business data.")
    print("The unified collection enables cross-business type queries for the dashboard.")
    
    confirm = input("\nDo you want to proceed? (y/N): ").lower().strip()
    
    if confirm == 'y':
        asyncio.run(main())
        print("\n🎉 Migration completed!")
    else:
        print("❌ Migration cancelled.")
