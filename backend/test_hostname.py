#!/usr/bin/env python3
"""
Test different MongoDB Atlas cluster URLs to find the correct one
"""
import socket
import sys

def test_hostname_resolution(hostname):
    """Test if a hostname resolves"""
    try:
        socket.gethostbyname(hostname)
        return True
    except socket.gaierror:
        return False

def main():
    print("🔍 Testing MongoDB Atlas cluster hostname resolution")
    print("=" * 60)
    
    # Common MongoDB Atlas hostname patterns
    base_patterns = [
        "cluster0.v0zrhmy.mongodb.net",
        "cluster0-v0zrhmy.mongodb.net", 
        "cluster0.mongodb.net",
        "ac-v0zrhmy-shard-00-00.v0zrhmy.mongodb.net",
        "ac-v0zrhmy-shard-00-01.v0zrhmy.mongodb.net",
        "ac-v0zrhmy-shard-00-02.v0zrhmy.mongodb.net"
    ]
    
    print("\nTesting hostname resolution:")
    for hostname in base_patterns:
        print(f"  {hostname}: ", end="")
        if test_hostname_resolution(hostname):
            print("✅ RESOLVES")
        else:
            print("❌ NO RESOLUTION")
    
    print("\n" + "=" * 60)
    print("💡 POSSIBLE SOLUTIONS:")
    print("1. Check your MongoDB Atlas dashboard for the correct connection string")
    print("2. Verify the cluster is still active and not paused")
    print("3. Check if the cluster region/hostname has changed")
    print("4. Ensure your IP is whitelisted in MongoDB Atlas Network Access")
    print("5. Try connecting from MongoDB Compass first to verify credentials")
    
    print("\n📋 TO FIX:")
    print("1. Go to MongoDB Atlas Dashboard")
    print("2. Click on 'Connect' for your cluster")
    print("3. Choose 'Connect your application'")
    print("4. Copy the exact connection string")
    print("5. Update the MONGO_URI in the .env file")

if __name__ == "__main__":
    main()
