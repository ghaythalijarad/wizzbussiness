"""
Business model using OOP principles for different business types.
"""
from typing import Optional, Dict, Any, List
from beanie import Document, PydanticObjectId
from pydantic import BaseModel, Field, validator
from enum import Enum
from datetime import datetime


class BusinessType(str, Enum):
    """Business type enumeration."""
    RESTAURANT = "restaurant"
    STORE = "store"
    PHARMACY = "pharmacy"
    KITCHEN = "kitchen"


class BusinessStatus(str, Enum):
    """Business status enumeration."""
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    SUSPENDED = "suspended"


# Legacy Address model for backward compatibility
class Address(BaseModel):
    """Legacy address model with OOP structure - for backward compatibility."""
    country: str
    city: str
    district: str
    neighbourhood: str
    street: str
    building_number: Optional[str] = None
    zip_code: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class BusinessSettings(BaseModel):
    """Business settings model with POS configuration."""
    # POS Settings
    pos: Dict[str, Any] = Field(default_factory=lambda: {
        "enabled": False,
        "autoSendOrders": False,
        "systemType": "square",
        "apiEndpoint": "",
        "apiKey": "",
        "accessToken": "",
        "locationId": ""
    })
    
    # Other business settings
    notifications: Dict[str, bool] = Field(default_factory=lambda: {
        "email": True,
        "push": True,
        "sms": False
    })
    
    operating_hours: Dict[str, Dict[str, Any]] = Field(default_factory=lambda: {
        "monday": {"open": "09:00", "close": "17:00", "closed": False},
        "tuesday": {"open": "09:00", "close": "17:00", "closed": False},
        "wednesday": {"open": "09:00", "close": "17:00", "closed": False},
        "thursday": {"open": "09:00", "close": "17:00", "closed": False},
        "friday": {"open": "09:00", "close": "17:00", "closed": False},
        "saturday": {"open": "09:00", "close": "17:00", "closed": False},
        "sunday": {"open": "09:00", "close": "17:00", "closed": True}
    })


class Business(Document):
    """Base business model using OOP principles."""
    
    # Owner information
    owner_id: PydanticObjectId = Field(..., description="Owner user ID")
    owner_name: str
    owner_national_id: str
    owner_date_of_birth: datetime
    
    # Business information
    name: str
    business_type: BusinessType
    phone_number: str
    email: Optional[str] = None
    website: Optional[str] = None
    
    # Address information - now references separate address collection
    address_id: PydanticObjectId = Field(..., description="Address ID reference")
    
    # Legacy embedded address for backward compatibility (will be None for new businesses)
    address: Optional[Address] = Field(None, description="Legacy embedded address")
    
    # Business status and verification
    status: BusinessStatus = BusinessStatus.PENDING
    is_verified: bool = False
    is_online: bool = True
    
    # Business settings
    settings: BusinessSettings = Field(default_factory=BusinessSettings)
    
    # Metadata
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Documents (file paths or URLs)
    documents: Dict[str, str] = Field(default_factory=dict)  # e.g., {"commercial_license": "path/to/file"}
    
    class Settings:
        name = "WB_businesses"
        indexes = [
            "owner_id",
            "business_type",
            "status",
            ("name", "business_type"),
        ]
    
    @validator("business_type", pre=True)
    def validate_business_type(cls, v):
        """Validate business type."""
        if isinstance(v, str):
            try:
                return BusinessType(v.lower())
            except ValueError:
                raise ValueError(f"Invalid business type: {v}")
        return v
    
    def __str__(self) -> str:
        return f"Business(id={self.id}, name={self.name}, type={self.business_type})"
    
    def __repr__(self) -> str:
        return self.__str__()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert business to dictionary representation."""
        return {
            "id": str(self.id),
            "owner_id": str(self.owner_id),
            "owner_name": self.owner_name,
            "name": self.name,
            "business_type": self.business_type.value,
            "phone_number": self.phone_number,
            "email": self.email,
            "website": self.website,
            "address_id": str(self.address_id),
            "address": self.address.dict() if self.address else None,  # Legacy field
            "status": self.status.value,
            "is_verified": self.is_verified,
            "is_online": self.is_online,
            "settings": self.settings.dict() if self.settings else None,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "documents": self.documents,
        }
    
    async def get_address(self):
        """Get the address document from the separate address collection."""
        from .address import Address as AddressDocument
        try:
            address_doc = await AddressDocument.get(self.address_id)
            return address_doc
        except Exception:
            # Fallback to legacy embedded address if separate address not found
            return self.address
    
    async def get_address_dict(self) -> Optional[Dict[str, Any]]:
        """Get address as dictionary for API responses."""
        address = await self.get_address()
        if address:
            if hasattr(address, 'to_dict'):
                return address.to_dict()
            elif hasattr(address, 'dict'):
                return address.dict()
        return None
    
    def update_pos_settings(self, pos_settings: Dict[str, Any]) -> None:
        """Update POS settings."""
        if self.settings and self.settings.pos:
            self.settings.pos.update(pos_settings)
        else:
            if not self.settings:
                self.settings = BusinessSettings()
            self.settings.pos = {**BusinessSettings().pos, **pos_settings}
        self.updated_at = datetime.utcnow()
    
    def get_pos_settings(self) -> Dict[str, Any]:
        """Get current POS settings."""
        if self.settings and self.settings.pos:
            return self.settings.pos
        return BusinessSettings().pos
    
    def set_online_status(self, is_online: bool) -> None:
        """Set business online/offline status."""
        self.is_online = is_online
        self.updated_at = datetime.utcnow()


class Restaurant(Business):
    """Restaurant-specific business model."""
    
    # Restaurant-specific fields
    cuisine_type: Optional[str] = None
    seating_capacity: Optional[int] = None
    delivery_available: bool = True
    takeout_available: bool = True
    
    class Settings:
        name = "WB_restaurants"


class Store(Business):
    """Store-specific business model."""
    
    # Store-specific fields
    store_category: Optional[str] = None  # grocery, electronics, clothing, etc.
    has_online_catalog: bool = False
    
    class Settings:
        name = "WB_stores"


class Pharmacy(Business):
    """Pharmacy-specific business model."""
    
    # Pharmacy-specific fields
    license_number: Optional[str] = None
    has_prescription_service: bool = True
    has_delivery: bool = True
    
    class Settings:
        name = "WB_pharmacies"


class Kitchen(Business):
    """Cloud Kitchen-specific business model."""
    
    # Kitchen-specific fields
    specialties: List[str] = Field(default_factory=list)
    delivery_only: bool = True
    kitchen_type: Optional[str] = None  # cloud, ghost, virtual
    
    class Settings:
        name = "WB_kitchens"
