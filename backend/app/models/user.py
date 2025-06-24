"""
User model and related schemas using OOP principles.
"""
import re
from typing import Optional
from beanie import Document, PydanticObjectId
from fastapi_users.db import BeanieBaseUser
from pydantic import validator
import pymongo
from pymongo.collation import Collation


class User(BeanieBaseUser, Document):
    """User document model for MongoDB, compatible with fastapi-users and Beanie."""
    
    # Additional user fields can be added here
    phone_number: Optional[str] = None
    business_name: Optional[str] = None
    business_type: Optional[str] = None
    
    class Settings(BeanieBaseUser.Settings):
        name = "WB_users"
        # Case-insensitive collation for email lookups
        email_collation = Collation("en", strength=2)
        # Define unique, case-insensitive index for the email field
        indexes = [
            pymongo.IndexModel(
                [("email", pymongo.ASCENDING)],
                unique=True,
                collation=email_collation,
                name="unique_email_idx",
            ),
        ]
    
    def __str__(self) -> str:
        return f"User(id={self.id}, email={self.email})"
    
    def __repr__(self) -> str:
        return self.__str__()
    
    def to_dict(self) -> dict:
        """Convert user to dictionary representation."""
        return {
            "id": str(self.id),
            "email": self.email,
            "is_active": self.is_active,
            "is_superuser": self.is_superuser,
            "is_verified": self.is_verified,
            "phone_number": self.phone_number,
            "business_name": self.business_name,
            "business_type": self.business_type,
        }


class PasswordValidator:
    """Password validation utility class."""
    
    @staticmethod
    def validate(password: str) -> str:
        """Validate password complexity."""
        if len(password) < 8:
            raise ValueError("Password must be at least 8 characters long")
        if not re.search(r"[A-Z]", password):
            raise ValueError("Password must contain at least one uppercase letter")
        if not re.search(r"[a-z]", password):
            raise ValueError("Password must contain at least one lowercase letter")
        if not re.search(r"\d", password):
            raise ValueError("Password must contain at least one number")
        return password
