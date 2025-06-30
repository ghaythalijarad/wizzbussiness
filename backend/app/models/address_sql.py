"""
SQLAlchemy Address model for PostgreSQL.
"""
from typing import Optional
from datetime import datetime
from sqlalchemy import Column, String, Float, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from ..core.database import Base


class Address(Base):
    """Address model for PostgreSQL storage."""
    
    __tablename__ = "addresses"
    
    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Address information
    country = Column(String(100), nullable=False)
    city = Column(String(100), nullable=False)
    district = Column(String(100), nullable=False)
    neighbourhood = Column(String(100), nullable=False)
    street = Column(String(200), nullable=False)
    building_number = Column(String(20), nullable=True)
    zip_code = Column(String(20), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Foreign key to business
    business_id = Column(UUID(as_uuid=True), ForeignKey("businesses.id"), nullable=True)
    
    # Relationships
    business = relationship("Business", back_populates="addresses")
    
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
            "business_id": str(self.business_id) if self.business_id else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
