#!/usr/bin/env python3
"""
Debug MongoDB Atlas connection issues
"""
import asyncio
import motor.motor_asyncio
import urllib.parse
from pymongo import MongoClient
import os
from dotenv import load_dotenv
import socket

# Load environment variables
load_dotenv()

async def test_mongodb_connection():
    """Test MongoDB connection with various configurations"""
    
    # Test credentials
    username = "alwershmohammed"
    password = "MOHmar"
    cluster = "cluster0.v0zrhmy.mongodb.net"
    
    # Quick resolution check to avoid long timeouts
    print(f"🔍 Checking DNS resolution for {cluster}")
    try:
        socket.gethostbyname(cluster)
        print(f"✅ Hostname {cluster} resolves correctly")
    except Exception as e:
        print(f"❌ Hostname resolution failed: {e}")
        print("Abort further tests. Please verify the correct MongoDB Atlas cluster URL.")
        return
    
    database = "Wizz_central_DB"
    
    print("🔍 MongoDB Atlas Connection Debug")
    print("=" * 50)
    
    # Test 1: Basic connection without database specification
    print("\n1️⃣ Testing basic connection...")
    uri1 = f"mongodb+srv://{username}:{password}@{cluster}/?retryWrites=true&w=majority"
    await test_connection_async(uri1, "Basic connection")
    
    # Test 2: With database specified
    print("\n2️⃣ Testing with database specified...")
    uri2 = f"mongodb+srv://{username}:{password}@{cluster}/{database}?retryWrites=true&w=majority"
    await test_connection_async(uri2, "With database")
    
    # Test 3: URL encoded password
    print("\n3️⃣ Testing with URL encoded password...")
    encoded_password = urllib.parse.quote_plus(password)
    uri3 = f"mongodb+srv://{username}:{encoded_password}@{cluster}/{database}?retryWrites=true&w=majority"
    await test_connection_async(uri3, "URL encoded password")
    
    # Test 4: Different database names
    print("\n4️⃣ Testing different database names...")
    for db_name in ["admin", "test", "wizz_central_db", "WizzCentralDB"]:
        uri = f"mongodb+srv://{username}:{password}@{cluster}/{db_name}?retryWrites=true&w=majority"
        await test_connection_async(uri, f"Database: {db_name}")
    
    # Test 5: Synchronous connection test
    print("\n5️⃣ Testing synchronous connection...")
    test_sync_connection(f"mongodb+srv://{username}:{password}@{cluster}/?retryWrites=true&w=majority")

async def test_connection_async(uri, description):
    """Test async connection"""
    try:
        client = motor.motor_asyncio.AsyncIOMotorClient(uri, serverSelectionTimeoutMS=5000)
        
        # Test ping
        result = await client.admin.command('ping')
        print(f"  ✅ {description}: SUCCESS")
        
        # List databases
        databases = await client.list_database_names()
        print(f"    📁 Available databases: {databases}")
        
        # Test specific database access if specified
        if "/" in uri and "?" in uri:
            db_name = uri.split("/")[-1].split("?")[0]
            if db_name and db_name != "":
                db = client[db_name]
                collections = await db.list_collection_names()
                print(f"    📂 Collections in {db_name}: {collections}")
        
        client.close()
        return True
        
    except Exception as e:
        print(f"  ❌ {description}: FAILED")
        print(f"    Error: {e}")
        return False

def test_sync_connection(uri):
    """Test synchronous connection"""
    try:
        client = MongoClient(uri, serverSelectionTimeoutMS=5000)
        
        # Test ping
        result = client.admin.command('ping')
        print(f"  ✅ Synchronous connection: SUCCESS")
        
        # List databases
        databases = client.list_database_names()
        print(f"    📁 Available databases: {databases}")
        
        client.close()
        return True
        
    except Exception as e:
        print(f"  ❌ Synchronous connection: FAILED")
        print(f"    Error: {e}")
        return False

if __name__ == "__main__":
    asyncio.run(test_mongodb_connection())
