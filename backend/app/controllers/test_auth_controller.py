"""
Temporary authentication bypass for testing login functionality
when database is not available.
"""
import logging
from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import OAuth2PasswordRequestForm
from datetime import datetime, timedelta
import jwt
from typing import Dict

from ..core.config import config

# Create a simple test router
test_auth_router = APIRouter(prefix="/test-auth", tags=["test-auth"])

@test_auth_router.post("/login")
async def test_login(form_data: OAuth2PasswordRequestForm = Depends()):
    """
    Test login endpoint that works without database.
    Only for testing the specific credentials: saif@yahoo.com / Gha@551987
    """
    
    # Test credentials
    TEST_EMAIL = "saif@yahoo.com"
    TEST_PASSWORD = "Gha@551987"
    
    logging.info(f"🔐 Test login attempt for: {form_data.username}")
    
    # Check credentials
    if form_data.username != TEST_EMAIL or form_data.password != TEST_PASSWORD:
        logging.warning(f"❌ Invalid credentials for: {form_data.username}")
        raise HTTPException(
            status_code=401, 
            detail="Invalid credentials. Only test user saif@yahoo.com with correct password is allowed."
        )
    
    # Generate JWT token (same as the real auth system would)
    try:
        payload = {
            "sub": TEST_EMAIL,
            "user_id": "test-user-id-12345", 
            "email": TEST_EMAIL,
            "exp": datetime.utcnow() + timedelta(seconds=config.security.jwt_lifetime_seconds),
            "iat": datetime.utcnow(),
            "type": "access"
        }
        
        token = jwt.encode(
            payload,
            config.security.secret_key,
            algorithm="HS256"
        )
        
        logging.info(f"✅ Test login successful for: {form_data.username}")
        
        return {
            "access_token": token,
            "token_type": "bearer",
            "expires_in": config.security.jwt_lifetime_seconds,
            "test_mode": True,
            "message": "Test authentication successful - database not connected"
        }
        
    except Exception as e:
        logging.error(f"💥 Token generation failed: {e}")
        raise HTTPException(status_code=500, detail=f"Token generation failed: {str(e)}")

@test_auth_router.get("/me")
async def test_get_current_user():
    """
    Test user profile endpoint that works without database.
    Returns mock profile data for the test user.
    """
    
    # Mock user profile data for the test user
    test_user_profile = {
        "id": "test-user-id-12345",
        "email": "saif@yahoo.com",
        "is_active": True,
        "is_superuser": False,
        "is_verified": True,
        "phone_number": "+1234567890",
        "business_name": "Test Restaurant",
        "business_type": "restaurant",
        "owner_name": "Saif Al-Test",
        "test_mode": True
    }
    
    logging.info(f"🧪 Test user profile requested")
    
    return test_user_profile

@test_auth_router.get("/verify")
async def test_verify():
    """Test endpoint to verify the router is working"""
    return {
        "status": "Test auth router is working",
        "timestamp": datetime.utcnow().isoformat(),
        "test_credentials": {
            "email": "saif@yahoo.com",
            "password": "Use the provided password"
        }
    }

@test_auth_router.post("/verify-user/{email}")
async def verify_test_user(email: str):
    """
    Test endpoint to manually verify a user for testing purposes.
    This bypasses the normal email verification process.
    """
    try:
        from ..models.user import User
        
        # Find user by email
        user = await User.find_one(User.email == email)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Verify the user
        user.is_verified = True
        await user.save()
        
        logging.info(f"✅ User {email} has been manually verified for testing")
        
        return {
            "message": f"User {email} has been verified successfully",
            "user_id": str(user.id),
            "is_verified": user.is_verified,
            "test_mode": True
        }
        
    except Exception as e:
        logging.error(f"💥 Failed to verify user {email}: {e}")
        raise HTTPException(status_code=500, detail=f"Verification failed: {str(e)}")
