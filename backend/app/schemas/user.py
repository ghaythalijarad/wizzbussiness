"""
User schemas for API request/response models using OOP principles.
"""
import re
from typing import Optional, Union, Dict, Any
from fastapi_users import schemas
from pydantic import validator, field_serializer, BaseModel
from beanie import PydanticObjectId
from datetime import datetime


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
    
    # Additional fields for automatic business creation
    owner_name: Optional[str] = None
    national_id: Optional[str] = None
    date_of_birth: Optional[str] = None  # Will be converted to datetime
    address: Optional[Dict[str, Any]] = None
    
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
    
    @validator("date_of_birth")
    def validate_date_of_birth(cls, v: Optional[str]) -> Optional[str]:
        """Validate date of birth format."""
        if v is None:
            return v
        # Try to parse the date to ensure it's valid
        try:
            # Accept various date formats
            for fmt in ['%Y-%m-%d', '%Y-%m-%dT%H:%M:%S', '%d/%m/%Y', '%m/%d/%Y']:
                try:
                    datetime.strptime(v, fmt)
                    return v
                except ValueError:
                    continue
            raise ValueError("Invalid date format")
        except:
            raise ValueError("Invalid date of birth format")
    
    @validator("address")
    def validate_address(cls, v: Optional[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
        """Validate address structure."""
        if v is None:
            return v
        required_fields = ['country', 'city', 'district']
        for field in required_fields:
            if field not in v or not v[field]:
                raise ValueError(f"Address must include {field}")
        return v


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
