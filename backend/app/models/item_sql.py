"""
SQLAlchemy Item and ItemCategory models for PostgreSQL.
"""
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum
from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, ForeignKey, Text, JSON, ARRAY
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from ..core.database import Base


class ItemStatus(str, Enum):
    """Item status enumeration."""
    ACTIVE = "active"
    INACTIVE = "inactive"
    OUT_OF_STOCK = "out_of_stock"
    DISCONTINUED = "discontinued"


class ItemType(str, Enum):
    """Item type enumeration based on business type."""
    DISH = "dish"           # Restaurant/Kitchen
    PRODUCT = "product"     # Store
    MEDICINE = "medicine"   # Pharmacy
    BEVERAGE = "beverage"   # All types
    INGREDIENT = "ingredient"  # Kitchen


class ItemCategory(Base):
    """Item category model for organizing items."""
    
    __tablename__ = "item_categories"
    
    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Foreign key to business
    business_id = Column(UUID(as_uuid=True), ForeignKey("businesses.id"), nullable=False)
    
    # Category information
    name = Column(String(100), nullable=False)
    description = Column(String(500), nullable=True)
    display_order = Column(Integer, default=0, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Category customization
    color = Column(String(7), nullable=True)  # Hex color code
    icon = Column(String(200), nullable=True)  # Icon name or URL
    
    # Item counts (for analytics)
    items_count = Column(Integer, default=0, nullable=False)
    active_items_count = Column(Integer, default=0, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    business = relationship("Business", back_populates="item_categories")
    items = relationship("Item", back_populates="category")
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert category to dictionary representation."""
        return {
            "id": str(self.id),
            "business_id": str(self.business_id),
            "name": self.name,
            "description": self.description,
            "display_order": self.display_order,
            "is_active": self.is_active,
            "color": self.color,
            "icon": self.icon,
            "items_count": self.items_count,
            "active_items_count": self.active_items_count,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }
    
    def update_item_counts(self, items_count: int, active_items_count: int) -> None:
        """Update item counts for this category."""
        self.items_count = max(0, items_count)
        self.active_items_count = max(0, active_items_count)
        self.updated_at = datetime.utcnow()


class Item(Base):
    """Item model for all business types."""
    
    __tablename__ = "items"
    
    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Foreign keys
    business_id = Column(UUID(as_uuid=True), ForeignKey("businesses.id"), nullable=False)
    category_id = Column(UUID(as_uuid=True), ForeignKey("item_categories.id"), nullable=True)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    updated_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    
    # Basic information
    name = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    
    # Pricing
    price = Column(Float, nullable=False)
    cost = Column(Float, nullable=True)  # Cost price for profit calculation
    
    # Categorization
    category_name = Column(String(100), nullable=True)
    item_type = Column(String(20), default=ItemType.PRODUCT.value, nullable=False)
    
    # Availability and status
    status = Column(String(20), default=ItemStatus.ACTIVE.value, nullable=False)
    is_available = Column(Boolean, default=True, nullable=False)
    
    # Inventory management
    stock_quantity = Column(Integer, nullable=True)
    low_stock_threshold = Column(Integer, nullable=True)
    track_inventory = Column(Boolean, default=False, nullable=False)
    
    # Media (using JSON for arrays)
    image_url = Column(String(500), nullable=True)
    images = Column(JSON, nullable=True)  # List of URLs or file paths
    thumbnail = Column(String(500), nullable=True)
    
    # Variants and options (using JSON)
    variants = Column(JSON, nullable=True)  # List of ItemVariant objects
    customizable = Column(Boolean, default=False, nullable=False)
    
    # Business-specific fields
    preparation_time = Column(Integer, nullable=True)  # In minutes
    nutritional_info = Column(JSON, nullable=True)  # NutritionalInfo object
    allergens = Column(JSON, nullable=True)  # List of strings
    ingredients = Column(JSON, nullable=True)  # List of strings
    
    # Pharmacy-specific fields
    prescription_required = Column(Boolean, nullable=True)
    medicine_type = Column(String(50), nullable=True)  # tablet, syrup, injection, etc.
    dosage = Column(String(100), nullable=True)
    manufacturer = Column(String(200), nullable=True)
    expiry_date = Column(DateTime, nullable=True)
    
    # Store-specific fields
    brand = Column(String(100), nullable=True)
    model = Column(String(100), nullable=True)
    sku = Column(String(100), nullable=True)
    barcode = Column(String(100), nullable=True)
    
    # Analytics and metadata
    views_count = Column(Integer, default=0, nullable=False)
    orders_count = Column(Integer, default=0, nullable=False)
    rating = Column(Float, default=0.0, nullable=False)
    reviews_count = Column(Integer, default=0, nullable=False)
    
    # SEO and search (using JSON for arrays)
    tags = Column(JSON, nullable=True)  # List of strings
    search_keywords = Column(JSON, nullable=True)  # List of strings
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    business = relationship("Business", back_populates="items")
    category = relationship("ItemCategory", back_populates="items")
    creator = relationship("User", foreign_keys=[created_by])
    updater = relationship("User", foreign_keys=[updated_by])
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert item to dictionary representation."""
        return {
            "id": str(self.id),
            "business_id": str(self.business_id),
            "name": self.name,
            "description": self.description,
            "price": self.price,
            "cost": self.cost,
            "category_id": str(self.category_id) if self.category_id else None,
            "category_name": self.category_name,
            "item_type": self.item_type,
            "status": self.status,
            "is_available": self.is_available,
            "stock_quantity": self.stock_quantity,
            "low_stock_threshold": self.low_stock_threshold,
            "track_inventory": self.track_inventory,
            "image_url": self.image_url,
            "images": self.images or [],
            "thumbnail": self.thumbnail,
            "variants": self.variants or [],
            "customizable": self.customizable,
            "preparation_time": self.preparation_time,
            "nutritional_info": self.nutritional_info,
            "allergens": self.allergens or [],
            "ingredients": self.ingredients or [],
            "prescription_required": self.prescription_required,
            "medicine_type": self.medicine_type,
            "dosage": self.dosage,
            "manufacturer": self.manufacturer,
            "expiry_date": self.expiry_date.isoformat() if self.expiry_date else None,
            "brand": self.brand,
            "model": self.model,
            "sku": self.sku,
            "barcode": self.barcode,
            "views_count": self.views_count,
            "orders_count": self.orders_count,
            "rating": self.rating,
            "reviews_count": self.reviews_count,
            "tags": self.tags or [],
            "search_keywords": self.search_keywords or [],
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }
    
    def update_availability(self, is_available: bool) -> None:
        """Update item availability."""
        self.is_available = is_available
        if not is_available:
            self.status = ItemStatus.INACTIVE.value
        else:
            self.status = ItemStatus.ACTIVE.value
        self.updated_at = datetime.utcnow()
    
    def update_stock(self, quantity: int) -> None:
        """Update stock quantity."""
        if self.track_inventory:
            self.stock_quantity = max(0, quantity)
            if self.stock_quantity == 0:
                self.status = ItemStatus.OUT_OF_STOCK.value
                self.is_available = False
            elif self.low_stock_threshold and self.stock_quantity <= self.low_stock_threshold:
                # Could trigger low stock notification
                pass
            else:
                if self.status == ItemStatus.OUT_OF_STOCK.value:
                    self.status = ItemStatus.ACTIVE.value
                    self.is_available = True
        self.updated_at = datetime.utcnow()
    
    def increment_views(self) -> None:
        """Increment view count."""
        self.views_count += 1
        self.updated_at = datetime.utcnow()
    
    def increment_orders(self) -> None:
        """Increment order count."""
        self.orders_count += 1
        self.updated_at = datetime.utcnow()
    
    def is_low_stock(self) -> bool:
        """Check if item is low on stock."""
        if not self.track_inventory or self.low_stock_threshold is None:
            return False
        return self.stock_quantity is not None and self.stock_quantity <= self.low_stock_threshold
