"""
Business model for PostgreSQL using SQLAlchemy.
"""
from datetime import datetime
from typing import Optional, List
from sqlalchemy import String, DateTime, Boolean, Text, Integer, Float, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import UUID, ARRAY
import uuid
from ..core.database import Base


class Business(Base):
    """Business model for storing business information."""
    
    __tablename__ = "businesses"
    
    # Primary key
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Basic business information
    name: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    business_type: Mapped[str] = mapped_column(String(50), nullable=False)  # restaurant, store, pharmacy, kitchen
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    phone: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    email: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    website: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    
    # Business status and settings
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_online: Mapped[bool] = mapped_column(Boolean, default=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    
    # Operating hours (stored as JSON string)
    operating_hours: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    # Address information
    street_address: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    city: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    district: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    country: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    postal_code: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    neighborhood: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    building_number: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    
    # Location coordinates
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    
    # Business images
    logo_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    cover_image_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    gallery_images: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON array of URLs
    
    # Business metrics
    average_rating: Mapped[float] = mapped_column(Float, default=0.0)
    total_reviews: Mapped[int] = mapped_column(Integer, default=0)
    total_orders: Mapped[int] = mapped_column(Integer, default=0)
    
    # Financial information
    delivery_fee: Mapped[float] = mapped_column(Float, default=0.0)
    minimum_order: Mapped[float] = mapped_column(Float, default=0.0)
    tax_rate: Mapped[float] = mapped_column(Float, default=0.0)
    
    # Owner/User relationship
    owner_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        server_default=func.now(),
        onupdate=func.now()
    )
    
    # Platform integration
    platform_business_id: Mapped[Optional[str]] = mapped_column(String(100), nullable=True, index=True)
    sync_status: Mapped[str] = mapped_column(String(20), default="pending")  # pending, synced, failed
    last_sync_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    owner = relationship("User", back_populates="businesses")
    addresses = relationship("Address", back_populates="business")
    items = relationship("Item", back_populates="business")
    item_categories = relationship("ItemCategory", back_populates="business")
    orders = relationship("Order", back_populates="business")
    pos_settings = relationship("BusinessPosSettings", back_populates="business", uselist=False)
    
    def __repr__(self) -> str:
        return f"<Business(id={self.id}, name={self.name}, type={self.business_type})>"
