"""
User model for PostgreSQL using SQLAlchemy.
"""
from datetime import datetime
from typing import Optional
from sqlalchemy import String, DateTime, Boolean, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from fastapi_users_db_sqlalchemy import SQLAlchemyBaseUserTableUUID
from ..core.database import Base


class User(SQLAlchemyBaseUserTableUUID, Base):
    """User model for authentication and profile."""
    
    __tablename__ = "users"
    
    # Profile information
    full_name: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    phone_number: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    profile_image_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    # Business information
    business_type: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    business_name: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    
    # Account settings
    language_preference: Mapped[str] = mapped_column(String(10), default="en")
    timezone: Mapped[str] = mapped_column(String(50), default="UTC")
    
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
    
    # Optional fields for business registration
    owner_name: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    owner_national_id: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    owner_date_of_birth: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    
    # Document references (stored as file paths/URLs)
    license_document: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    identity_document: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    health_certificate: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    owner_photo: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    # Relationships
    businesses = relationship("Business", back_populates="owner")
    
    def __repr__(self) -> str:
        return f"<User(id={self.id}, email={self.email}, business_name={self.business_name})>"
