"""
Order model for the business management system.
"""
from typing import Optional, List, Dict, Any
from beanie import Document, PydanticObjectId
from pydantic import BaseModel, Field
from enum import Enum
from datetime import datetime


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


class OrderItem(BaseModel):
    """Order item model."""
    item_id: str
    item_name: str
    quantity: int = Field(..., ge=1)
    unit_price: float = Field(..., ge=0)
    total_price: float = Field(..., ge=0)
    
    # Item customizations
    variants: List[Dict[str, Any]] = Field(default_factory=list)
    special_instructions: Optional[str] = None
    
    # Item details for display
    image_url: Optional[str] = None
    category_name: Optional[str] = None


class DeliveryAddress(BaseModel):
    """Delivery address model."""
    street: str
    building_number: Optional[str] = None
    floor: Optional[str] = None
    apartment: Optional[str] = None
    district: str
    city: str
    country: str
    zip_code: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    
    # Additional delivery info
    landmark: Optional[str] = None
    delivery_instructions: Optional[str] = None


class PaymentInfo(BaseModel):
    """Payment information model."""
    payment_method: str  # "cash", "card", "knet", "wallet", etc.
    payment_status: PaymentStatus = PaymentStatus.PENDING
    transaction_id: Optional[str] = None
    
    # Amount breakdown
    subtotal: float = Field(..., ge=0)
    tax_amount: float = Field(default=0, ge=0)
    delivery_fee: float = Field(default=0, ge=0)
    service_fee: float = Field(default=0, ge=0)
    discount_amount: float = Field(default=0, ge=0)
    total_amount: float = Field(..., ge=0)
    
    # Payment timestamps
    payment_requested_at: Optional[datetime] = None
    payment_completed_at: Optional[datetime] = None


class Order(Document):
    """Order model for customer orders."""
    
    # Basic order information
    order_number: str = Field(..., description="Unique order number")
    business_id: PydanticObjectId = Field(..., description="Business receiving the order")
    
    # Customer information
    customer_id: Optional[str] = None  # From customer app
    customer_name: str
    customer_phone: str
    customer_email: Optional[str] = None
    
    # Order details
    items: List[OrderItem] = Field(..., min_items=1)
    status: OrderStatus = OrderStatus.PENDING
    delivery_type: DeliveryType = DeliveryType.DELIVERY
    
    # Delivery information
    delivery_address: Optional[DeliveryAddress] = None
    delivery_notes: Optional[str] = None
    
    # Timing
    order_date: datetime = Field(default_factory=datetime.utcnow)
    requested_delivery_time: Optional[datetime] = None
    estimated_delivery_time: Optional[datetime] = None
    confirmed_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    
    # Payment
    payment_info: PaymentInfo
    
    # Order tracking
    preparation_time_minutes: Optional[int] = None
    special_instructions: Optional[str] = None
    
    # Internal tracking
    source: str = "wizz_app"  # Source of the order
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Business response
    business_notes: Optional[str] = None
    estimated_ready_time: Optional[datetime] = None
    
    class Settings:
        name = "WB_orders"
        indexes = [
            "business_id",
            "order_number",
            "status",
            "customer_phone",
            "order_date",
            ("business_id", "status"),
            ("business_id", "order_date"),
        ]
    
    @property
    def total_amount(self) -> float:
        """Get total order amount."""
        return self.payment_info.total_amount
    
    @property
    def items_count(self) -> int:
        """Get total number of items."""
        return sum(item.quantity for item in self.items)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert order to dictionary representation."""
        return {
            "id": str(self.id),
            "order_number": self.order_number,
            "business_id": str(self.business_id),
            "customer_name": self.customer_name,
            "customer_phone": self.customer_phone,
            "customer_email": self.customer_email,
            "items": [item.dict() for item in self.items],
            "items_count": self.items_count,
            "status": self.status,
            "delivery_type": self.delivery_type,
            "delivery_address": self.delivery_address.dict() if self.delivery_address else None,
            "delivery_notes": self.delivery_notes,
            "order_date": self.order_date.isoformat(),
            "requested_delivery_time": self.requested_delivery_time.isoformat() if self.requested_delivery_time else None,
            "estimated_delivery_time": self.estimated_delivery_time.isoformat() if self.estimated_delivery_time else None,
            "payment_info": self.payment_info.dict(),
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
        self.status = new_status
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
        if self.delivery_type == DeliveryType.PICKUP:
            self.estimated_delivery_time = datetime.utcnow().replace(
                minute=datetime.utcnow().minute + preparation_minutes
            )
        elif self.delivery_type == DeliveryType.DELIVERY:
            # Add extra time for delivery
            total_minutes = preparation_minutes + 20  # 20 min for delivery
            self.estimated_delivery_time = datetime.utcnow().replace(
                minute=datetime.utcnow().minute + total_minutes
            )
        
        self.preparation_time_minutes = preparation_minutes
