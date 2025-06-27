"""
Business schemas for API request/response models using OOP principles.
"""
from typing import Optional, Dict, Any, List
from pydantic import BaseModel, validator
from datetime import datetime
from ..models.business import BusinessType, BusinessStatus


class AddressCreate(BaseModel):
    """Schema for creating address."""
    country: str
    city: str
    district: str
    neighbourhood: str
    street: str
    building_number: Optional[str] = None
    zip_code: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class AddressRead(AddressCreate):
    """Schema for reading address."""
    pass


class BusinessSettingsUpdate(BaseModel):
    """Schema for updating business settings."""
    pos: Optional[Dict[str, Any]] = None
    notifications: Optional[Dict[str, bool]] = None
    operating_hours: Optional[Dict[str, Dict[str, str]]] = None


class BusinessCreate(BaseModel):
    """Schema for creating a business."""
    # Owner information
    owner_name: str
    owner_national_id: str
    owner_date_of_birth: datetime
    
    # Business information
    name: str
    business_type: BusinessType
    phone_number: str
    email: Optional[str] = None
    website: Optional[str] = None
    
    # Address information
    address: AddressCreate
    
    # Optional settings
    settings: Optional[BusinessSettingsUpdate] = None
    
    # Documents
    documents: Optional[Dict[str, str]] = None
    
    @validator("business_type", pre=True)
    def validate_business_type(cls, v):
        """Validate business type."""
        if isinstance(v, str):
            try:
                return BusinessType(v.lower())
            except ValueError:
                raise ValueError(f"Invalid business type: {v}")
        return v
    
    @validator("phone_number")
    def validate_phone_number(cls, v):
        """Validate phone number format."""
        # Basic phone number validation
        import re
        if not re.match(r'^\+?[\d\s\-\(\)]+$', v):
            raise ValueError("Invalid phone number format")
        return v


class BusinessUpdate(BaseModel):
    """Schema for updating business information."""
    name: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    address: Optional[AddressCreate] = None
    settings: Optional[BusinessSettingsUpdate] = None
    is_online: Optional[bool] = None
    
    @validator("phone_number")
    def validate_phone_number(cls, v):
        """Validate phone number format."""
        if v is None:
            return v
        import re
        if not re.match(r'^\+?[\d\s\-\(\)]+$', v):
            raise ValueError("Invalid phone number format")
        return v


class BusinessRead(BaseModel):
    """Schema for reading business information."""
    id: str
    owner_id: str
    owner_name: str
    name: str
    business_type: str
    phone_number: str
    email: Optional[str] = None
    website: Optional[str] = None
    address_id: Optional[str] = None  # New address reference field
    address: Optional[AddressRead] = None  # Address data (populated from separate collection)
    status: str
    is_verified: bool
    is_online: bool
    settings: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime
    documents: Optional[Dict[str, str]] = None


class POSSettingsUpdate(BaseModel):
    """Schema for updating POS settings specifically."""
    enabled: Optional[bool] = None
    autoSendOrders: Optional[bool] = None
    systemType: Optional[str] = None
    apiEndpoint: Optional[str] = None
    apiKey: Optional[str] = None
    accessToken: Optional[str] = None
    locationId: Optional[str] = None
    
    @validator("systemType")
    def validate_system_type(cls, v):
        """Validate POS system type."""
        if v is None:
            return v
        valid_types = ["square", "stripe", "paypal", "clover", "toast", "shopify"]
        if v.lower() not in valid_types:
            raise ValueError(f"POS system type must be one of: {', '.join(valid_types)}")
        return v.lower()
    
    @validator("apiEndpoint")
    def validate_api_endpoint(cls, v):
        """Validate API endpoint URL."""
        if v is None or v == "":
            return v
        import re
        url_pattern = re.compile(
            r'^https?://'  # http:// or https://
            r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|'  # domain...
            r'localhost|'  # localhost...
            r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # ...or ip
            r'(?::\d+)?'  # optional port
            r'(?:/?|[/?]\S+)$', re.IGNORECASE)
        if not url_pattern.match(v):
            raise ValueError("Invalid API endpoint URL")
        return v


class BusinessStatusUpdate(BaseModel):
    """Schema for updating business status (admin only)."""
    status: BusinessStatus
    is_verified: Optional[bool] = None


# Specific business type schemas
class RestaurantCreate(BusinessCreate):
    """Schema for creating a restaurant."""
    cuisine_type: Optional[str] = None
    seating_capacity: Optional[int] = None
    delivery_available: bool = True
    takeout_available: bool = True


class StoreCreate(BusinessCreate):
    """Schema for creating a store."""
    store_category: Optional[str] = None
    has_online_catalog: bool = False


class PharmacyCreate(BusinessCreate):
    """Schema for creating a pharmacy."""
    license_number: Optional[str] = None
    has_prescription_service: bool = True
    has_delivery: bool = True


class KitchenCreate(BusinessCreate):
    """Schema for creating a kitchen."""
    specialties: List[str] = []
    delivery_only: bool = True
    kitchen_type: Optional[str] = None
