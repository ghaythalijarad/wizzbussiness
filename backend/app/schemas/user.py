"""
User schemas for API request/response models using OOP principles.
"""
import re
from typing import Optional, Union
from fastapi_users import schemas
from pydantic import validator, field_serializer, BaseModel
from beanie import PydanticObjectId


class UserRead(schemas.BaseUser[Union[str, PydanticObjectId]]):
    """Schema for reading a user; handles both string and ObjectId."""
    phone_number: Optional[str] = None
    business_name: Optional[str] = None
    business_type: Optional[str] = None
    
    @field_serializer('id')
    def serialize_id(self, value: Union[str, PydanticObjectId]) -> str:
        """Convert ObjectId to string for JSON serialization."""
        return str(value)


class UserCreate(schemas.BaseUserCreate):
    """Schema for creating a new user with validation."""
    phone_number: Optional[str] = None
    business_name: Optional[str] = None
    business_type: Optional[str] = None
    
    @validator("password")
    def validate_password(cls, v: str) -> str:
        """Validate password complexity using OOP approach."""
        from ..models.user import PasswordValidator
        return PasswordValidator.validate(v)
    
    @validator("phone_number")
    def validate_phone_number(cls, v: Optional[str]) -> Optional[str]:
        """Validate phone number format."""
        if v is None:
            return v
        # Basic phone number validation (can be enhanced)
        if not re.match(r'^\+?[\d\s\-\(\)]+$', v):
            raise ValueError("Invalid phone number format")
        return v
    
    @validator("business_type")
    def validate_business_type(cls, v: Optional[str]) -> Optional[str]:
        """Validate business type."""
        if v is None:
            return v
        valid_types = ["restaurant", "store", "pharmacy", "kitchen"]
        if v.lower() not in valid_types:
            raise ValueError(f"Business type must be one of: {', '.join(valid_types)}")
        return v.lower()


class UserUpdate(schemas.BaseUserUpdate):
    """Schema for updating user information."""
    phone_number: Optional[str] = None
    business_name: Optional[str] = None
    business_type: Optional[str] = None
    
    @validator("phone_number")
    def validate_phone_number(cls, v: Optional[str]) -> Optional[str]:
        """Validate phone number format."""
        if v is None:
            return v
        if not re.match(r'^\+?[\d\s\-\(\)]+$', v):
            raise ValueError("Invalid phone number format")
        return v
    
    @validator("business_type")
    def validate_business_type(cls, v: Optional[str]) -> Optional[str]:
        """Validate business type."""
        if v is None:
            return v
        valid_types = ["restaurant", "store", "pharmacy", "kitchen"]
        if v.lower() not in valid_types:
            raise ValueError(f"Business type must be one of: {', '.join(valid_types)}")
        return v.lower()


class ChangePassword(BaseModel):
    old_password: str
    new_password: str

    @validator('new_password')
    def validate_new_password(cls, v: str) -> str:
        from ..models.user import PasswordValidator
        return PasswordValidator.validate(v)
