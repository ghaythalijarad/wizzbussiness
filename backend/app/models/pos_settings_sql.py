"""
SQLAlchemy POS Settings models for PostgreSQL.
"""
from typing import Optional, Dict, Any
from datetime import datetime
from enum import Enum
from sqlalchemy import Column, String, Boolean, Integer, DateTime, ForeignKey, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from ..core.database import Base


class PosSystemType(str, Enum):
    """Supported POS system types"""
    SQUARE = "square"
    TOAST = "toast" 
    CLOVER = "clover"
    SHOPIFY_POS = "shopifyPos"
    GENERIC_API = "genericApi"


class BusinessPosSettings(Base):
    """PostgreSQL table for storing business POS settings"""
    
    __tablename__ = "business_pos_settings"
    
    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Foreign key
    business_id = Column(UUID(as_uuid=True), ForeignKey("businesses.id"), nullable=False, unique=True)
    
    # POS Settings (stored as JSON)
    enabled = Column(Boolean, default=False, nullable=False)
    auto_send_orders = Column(Boolean, default=False, nullable=False)
    system_type = Column(String(50), default=PosSystemType.GENERIC_API.value, nullable=False)
    api_endpoint = Column(String(500), nullable=True)
    api_key = Column(String(500), nullable=True)
    access_token = Column(String(1000), nullable=True)
    location_id = Column(String(100), nullable=True)
    
    # Additional configuration options
    timeout_seconds = Column(Integer, default=30, nullable=False)
    retry_attempts = Column(Integer, default=3, nullable=False)
    test_mode = Column(Boolean, default=False, nullable=False)
    
    # Connection status tracking
    last_connection_test = Column(DateTime, nullable=True)
    last_connection_status = Column(Boolean, default=False, nullable=False)
    last_error_message = Column(Text, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    business = relationship("Business", back_populates="pos_settings")
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for storage"""
        return {
            "id": str(self.id),
            "business_id": str(self.business_id),
            "enabled": self.enabled,
            "auto_send_orders": self.auto_send_orders,
            "system_type": self.system_type,
            "api_endpoint": self.api_endpoint,
            "api_key": self.api_key,
            "access_token": self.access_token,
            "location_id": self.location_id,
            "timeout_seconds": self.timeout_seconds,
            "retry_attempts": self.retry_attempts,
            "test_mode": self.test_mode,
            "last_connection_test": self.last_connection_test.isoformat() if self.last_connection_test else None,
            "last_connection_status": self.last_connection_status,
            "last_error_message": self.last_error_message,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }
    
    def update_connection_status(self, status: bool, error_message: Optional[str] = None):
        """Update connection status and timestamp"""
        self.last_connection_test = datetime.utcnow()
        self.last_connection_status = status
        self.last_error_message = error_message
        self.updated_at = datetime.utcnow()


class PosOrderSyncLog(Base):
    """Log of orders sent to POS systems"""
    
    __tablename__ = "pos_order_sync_logs"
    
    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Foreign keys
    business_id = Column(UUID(as_uuid=True), ForeignKey("businesses.id"), nullable=False)
    order_id = Column(UUID(as_uuid=True), ForeignKey("orders.id"), nullable=False)
    
    # Sync information
    pos_system_type = Column(String(50), nullable=False)
    sync_status = Column(String(20), nullable=False)  # success, failed, pending
    sync_timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)
    pos_order_id = Column(String(100), nullable=True)
    error_message = Column(Text, nullable=True)
    retry_count = Column(Integer, default=0, nullable=False)
    
    # Relationships
    business = relationship("Business")
    order = relationship("Order")
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary representation"""
        return {
            "id": str(self.id),
            "business_id": str(self.business_id),
            "order_id": str(self.order_id),
            "pos_system_type": self.pos_system_type,
            "sync_status": self.sync_status,
            "sync_timestamp": self.sync_timestamp.isoformat(),
            "pos_order_id": self.pos_order_id,
            "error_message": self.error_message,
            "retry_count": self.retry_count,
        }
