"""
Item model for all business types using OOP principles.
"""
from typing import Optional, List, Dict, Any
from beanie import Document, PydanticObjectId
from pydantic import BaseModel, Field, validator
from enum import Enum
from datetime import datetime


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


class NutritionalInfo(BaseModel):
    """Nutritional information model."""
    calories: Optional[int] = None
    protein: Optional[float] = None
    carbs: Optional[float] = None
    fat: Optional[float] = None
    fiber: Optional[float] = None
    sugar: Optional[float] = None
    sodium: Optional[float] = None


class ItemVariant(BaseModel):
    """Item variant model for size/options."""
    name: str
    price_modifier: float = 0.0  # Additional price
    description: Optional[str] = None
    available: bool = True


class Item(Document):
    """Base item model for all business types."""
    
    # Basic information
    business_id: PydanticObjectId = Field(..., description="Business ID this item belongs to")
    name: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    
    # Pricing
    price: float = Field(..., ge=0)
    cost: Optional[float] = Field(None, ge=0)  # Cost price for profit calculation
    
    # Categorization
    category_id: Optional[str] = None
    category_name: Optional[str] = None
    item_type: ItemType = ItemType.PRODUCT
    
    # Availability and status
    status: ItemStatus = ItemStatus.ACTIVE
    is_available: bool = True
    
    # Inventory management
    stock_quantity: Optional[int] = Field(None, ge=0)
    low_stock_threshold: Optional[int] = Field(None, ge=0)
    track_inventory: bool = False
    
    # Media
    image_url: Optional[str] = None
    images: List[str] = Field(default_factory=list)  # URLs or file paths
    thumbnail: Optional[str] = None
    
    # Variants and options
    variants: List[ItemVariant] = Field(default_factory=list)
    customizable: bool = False
    
    # Business-specific fields
    preparation_time: Optional[int] = None  # In minutes
    nutritional_info: Optional[NutritionalInfo] = None
    allergens: List[str] = Field(default_factory=list)
    ingredients: List[str] = Field(default_factory=list)
    
    # Pharmacy-specific fields
    prescription_required: Optional[bool] = None
    medicine_type: Optional[str] = None  # tablet, syrup, injection, etc.
    dosage: Optional[str] = None
    manufacturer: Optional[str] = None
    expiry_date: Optional[datetime] = None
    
    # Store-specific fields
    brand: Optional[str] = None
    model: Optional[str] = None
    sku: Optional[str] = None
    barcode: Optional[str] = None
    
    # Analytics and metadata
    views_count: int = 0
    orders_count: int = 0
    rating: float = 0.0
    reviews_count: int = 0
    
    # SEO and search
    tags: List[str] = Field(default_factory=list)
    search_keywords: List[str] = Field(default_factory=list)
    
    # User tracking
    created_by: Optional[PydanticObjectId] = None
    updated_by: Optional[PydanticObjectId] = None
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "WB_items"
        indexes = [
            "business_id",
            "category_id",
            "item_type",
            "status",
            "is_available",
            ("business_id", "category_id"),
            ("business_id", "status"),
            ("business_id", "is_available"),
            ("name", "text"),
            ("description", "text"),
            ("tags", "text"),
        ]
    
    @validator("item_type", pre=True)
    def validate_item_type(cls, v):
        """Validate item type."""
        if isinstance(v, str):
            try:
                return ItemType(v.lower())
            except ValueError:
                raise ValueError(f"Invalid item type: {v}")
        return v
    
    @validator("status", pre=True)
    def validate_status(cls, v):
        """Validate item status."""
        if isinstance(v, str):
            try:
                return ItemStatus(v.lower())
            except ValueError:
                raise ValueError(f"Invalid item status: {v}")
        return v
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert item to dictionary representation."""
        return {
            "id": str(self.id),
            "business_id": str(self.business_id),
            "name": self.name,
            "description": self.description,
            "price": self.price,
            "cost": self.cost,
            "category_id": self.category_id,
            "category_name": self.category_name,
            "item_type": self.item_type.value,
            "status": self.status.value,
            "is_available": self.is_available,
            "stock_quantity": self.stock_quantity,
            "low_stock_threshold": self.low_stock_threshold,
            "track_inventory": self.track_inventory,
            "image_url": self.image_url,
            "images": self.images,
            "thumbnail": self.thumbnail,
            "variants": [variant.dict() for variant in self.variants],
            "customizable": self.customizable,
            "preparation_time": self.preparation_time,
            "nutritional_info": self.nutritional_info.dict() if self.nutritional_info else None,
            "allergens": self.allergens,
            "ingredients": self.ingredients,
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
            "tags": self.tags,
            "search_keywords": self.search_keywords,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }
    
    def update_availability(self, is_available: bool) -> None:
        """Update item availability."""
        self.is_available = is_available
        if not is_available:
            self.status = ItemStatus.INACTIVE
        else:
            self.status = ItemStatus.ACTIVE
        self.updated_at = datetime.utcnow()
    
    def update_stock(self, quantity: int) -> None:
        """Update stock quantity."""
        if self.track_inventory:
            self.stock_quantity = max(0, quantity)
            if self.stock_quantity == 0:
                self.status = ItemStatus.OUT_OF_STOCK
                self.is_available = False
            elif self.low_stock_threshold and self.stock_quantity <= self.low_stock_threshold:
                # Could trigger low stock notification
                pass
            else:
                if self.status == ItemStatus.OUT_OF_STOCK:
                    self.status = ItemStatus.ACTIVE
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


class ItemCategory(Document):
    """Item category model for organizing items."""
    
    business_id: PydanticObjectId = Field(..., description="Business ID this category belongs to")
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    display_order: int = 0
    is_active: bool = True
    
    # Category customization
    color: Optional[str] = None  # Hex color code
    icon: Optional[str] = None   # Icon name or URL
    
    # Item counts (for analytics)
    items_count: int = 0
    active_items_count: int = 0
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "WB_item_categories"
        indexes = [
            "business_id",
            "is_active",
            ("business_id", "name"),
            ("business_id", "display_order"),
        ]
    
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
