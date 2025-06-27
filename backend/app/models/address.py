"""
Address model for separate collection storage.
"""
from typing import Optional
from beanie import Document, PydanticObjectId
from pydantic import Field
from datetime import datetime


class Address(Document):
    """Address document model for separate storage."""
    
    # Address information
    country: str
    city: str
    district: str
    neighbourhood: str
    street: str
    building_number: Optional[str] = None
    zip_code: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    
    # Metadata
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Reference tracking (optional - to know which business this address belongs to)
    business_id: Optional[PydanticObjectId] = None
    
    class Settings:
        name = "WB_addresses"
        indexes = [
            "business_id",
            "city",
            "district",
            ("city", "district"),
            ("latitude", "longitude"),
        ]
    
    def __str__(self) -> str:
        return f"Address(id={self.id}, city={self.city}, district={self.district})"
    
    def __repr__(self) -> str:
        return self.__str__()
    
    def to_dict(self) -> dict:
        """Convert address to dictionary representation."""
        return {
            "id": str(self.id),
            "country": self.country,
            "city": self.city,
            "district": self.district,
            "neighbourhood": self.neighbourhood,
            "street": self.street,
            "building_number": self.building_number,
            "zip_code": self.zip_code,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "business_id": str(self.business_id) if self.business_id else None,
        }
    
    def format_full_address(self) -> str:
        """Format the complete address as a readable string."""
        parts = []
        
        if self.building_number:
            parts.append(f"Building {self.building_number}")
        if self.street:
            parts.append(self.street)
        if self.neighbourhood:
            parts.append(self.neighbourhood)
        if self.district:
            parts.append(self.district)
        if self.city:
            parts.append(self.city)
        if self.country:
            parts.append(self.country)
        if self.zip_code:
            parts.append(self.zip_code)
            
        return ", ".join(parts)
