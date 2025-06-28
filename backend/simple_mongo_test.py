#!/usr/bin/env python3
"""
Simple MongoDB Atlas connection test
"""
from pymongo import MongoClient
import sys

def test_connection():
    username = "alwershmohammed"
    password = "MOHmar"
    cluster = "cluster0.v0zrhmy.mongodb.net"
    
    # Test basic connection
    uri = f"mongodb+srv://{username}:{password}@{cluster}/?retryWrites=true&w=majority"
    
    print(f"Testing connection to: mongodb+srv://{username}:****@{cluster}")
    
    try:
        client = MongoClient(uri, serverSelectionTimeoutMS=5000)
        
        # Test ping
        result = client.admin.command('ping')
        print("✅ Connection successful!")
        print(f"Ping result: {result}")
        
        # List databases
        databases = client.list_database_names()
        print(f"Available databases: {databases}")
        
        # Check if Wizz_central_DB exists or can be created
        if "Wizz_central_DB" in databases:
            print("✅ Wizz_central_DB exists!")
            db = client["Wizz_central_DB"]
            collections = db.list_collection_names()
            print(f"Collections in Wizz_central_DB: {collections}")
        else:
            print("⚠️ Wizz_central_DB not found, but user can create it")
            # Try to create a test collection
            db = client["Wizz_central_DB"]
            test_collection = db["test"]
            test_collection.insert_one({"test": "document"})
            test_collection.delete_one({"test": "document"})
            print("✅ Successfully created and accessed Wizz_central_DB")
        
        client.close()
        return True
        
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False

if __name__ == "__main__":
    success = test_connection()
    sys.exit(0 if success else 1)
