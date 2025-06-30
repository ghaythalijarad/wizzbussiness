"""
SQLAlchemy Order model for PostgreSQL.
"""
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum
from sqlalchemy import Column, String, Float, Integer, DateTime, ForeignKey, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from ..core.database import Base


class OrderStatus(str, Enum):
    """Order status enumeration."""
    PENDING = "pending"
    CONFIRMED = "confirmed"
    PREPARING = "preparing"
    READY = "ready"
    OUT_FOR_DELIVERY = "out_for_delivery"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
    REFUNDED = "refunded"


class PaymentStatus(str, Enum):
    """Payment status enumeration."""
    PENDING = "pending"
    PAID = "paid"
    PARTIAL = "partial"
    FAILED = "failed"
    REFUNDED = "refunded"


class DeliveryType(str, Enum):
    """Delivery type enumeration."""
    PICKUP = "pickup"
    DELIVERY = "delivery"
    DINE_IN = "dine_in"


class Order(Base):
    """Order model for customer orders."""
    
    __tablename__ = "orders"
    
    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Basic order information
    order_number = Column(String(50), unique=True, nullable=False)
    business_id = Column(UUID(as_uuid=True), ForeignKey("businesses.id"), nullable=False)
    
    # Customer information
    customer_id = Column(String(100), nullable=True)  # From customer app
    customer_name = Column(String(200), nullable=False)
    customer_phone = Column(String(20), nullable=False)
    customer_email = Column(String(254), nullable=True)
    
    # Order details (using JSON for complex structures)
    items = Column(JSON, nullable=False)  # List of OrderItem objects
    status = Column(String(20), default=OrderStatus.PENDING.value, nullable=False)
    delivery_type = Column(String(20), default=DeliveryType.DELIVERY.value, nullable=False)
    
    # Delivery information (using JSON for complex structure)
    delivery_address = Column(JSON, nullable=True)  # DeliveryAddress object
    delivery_notes = Column(Text, nullable=True)
    
    # Timing
    order_date = Column(DateTime, default=datetime.utcnow, nullable=False)
    requested_delivery_time = Column(DateTime, nullable=True)
    estimated_delivery_time = Column(DateTime, nullable=True)
    confirmed_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    
    # Payment (using JSON for complex structure)
    payment_info = Column(JSON, nullable=False)  # PaymentInfo object
    
    # Order tracking
    preparation_time_minutes = Column(Integer, nullable=True)
    special_instructions = Column(Text, nullable=True)
    
    # Internal tracking
    source = Column(String(50), default="wizz_app", nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Business response
    business_notes = Column(Text, nullable=True)
    estimated_ready_time = Column(DateTime, nullable=True)
    
    # Driver assignment (managed by centralized platform)
    assigned_driver_info = Column(JSON, nullable=True)  # Driver info from centralized platform
    driver_assigned_at = Column(DateTime, nullable=True)
    picked_up_at = Column(DateTime, nullable=True)
    delivered_at = Column(DateTime, nullable=True)
    
    # Relationships
    business = relationship("Business", back_populates="orders")
    
    @property
    def total_amount(self) -> float:
        """Get total order amount."""
        if self.payment_info and isinstance(self.payment_info, dict):
            return self.payment_info.get("total_amount", 0.0)
        return 0.0
    
    @property
    def items_count(self) -> int:
        """Get total number of items."""
        if self.items and isinstance(self.items, list):
            return sum(item.get("quantity", 0) for item in self.items)
        return 0
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert order to dictionary representation."""
        return {
            "id": str(self.id),
            "order_number": self.order_number,
            "business_id": str(self.business_id),
            "customer_name": self.customer_name,
            "customer_phone": self.customer_phone,
            "customer_email": self.customer_email,
            "items": self.items or [],
            "items_count": self.items_count,
            "status": self.status,
            "delivery_type": self.delivery_type,
            "delivery_address": self.delivery_address,
            "delivery_notes": self.delivery_notes,
            "order_date": self.order_date.isoformat(),
            "requested_delivery_time": self.requested_delivery_time.isoformat() if self.requested_delivery_time else None,
            "estimated_delivery_time": self.estimated_delivery_time.isoformat() if self.estimated_delivery_time else None,
            "payment_info": self.payment_info or {},
            "total_amount": self.total_amount,
            "preparation_time_minutes": self.preparation_time_minutes,
            "special_instructions": self.special_instructions,
            "source": self.source,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "business_notes": self.business_notes,
            "estimated_ready_time": self.estimated_ready_time.isoformat() if self.estimated_ready_time else None,
        }
    
    def update_status(self, new_status: OrderStatus, notes: Optional[str] = None):
        """Update order status with timestamp tracking."""
        old_status = self.status
        self.status = new_status.value
        self.updated_at = datetime.utcnow()
        
        if notes:
            self.business_notes = notes
        
        # Update specific timestamps
        if new_status == OrderStatus.CONFIRMED:
            self.confirmed_at = datetime.utcnow()
        elif new_status in [OrderStatus.DELIVERED, OrderStatus.CANCELLED]:
            self.completed_at = datetime.utcnow()
    
    def calculate_estimated_time(self, preparation_minutes: int = 30):
        """Calculate estimated delivery time based on preparation time."""
        if self.delivery_type == DeliveryType.PICKUP.value:
            self.estimated_delivery_time = datetime.utcnow().replace(
                minute=datetime.utcnow().minute + preparation_minutes
            )
        elif self.delivery_type == DeliveryType.DELIVERY.value:
            # Add extra time for delivery
            total_minutes = preparation_minutes + 20  # 20 min for delivery
            self.estimated_delivery_time = datetime.utcnow().replace(
                minute=datetime.utcnow().minute + total_minutes
            )
        
        self.preparation_time_minutes = preparation_minutes
