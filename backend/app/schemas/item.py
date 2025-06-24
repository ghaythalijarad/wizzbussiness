"""
Item API schemas for request/response validation.
"""
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, validator
from datetime import datetime
from enum import Enum

from ..models.item import ItemStatus, ItemType


class ItemVariantSchema(BaseModel):
    """Schema for item variant."""
    name: str = Field(..., min_length=1, max_length=100)
    price_modifier: float = Field(0.0, description="Additional price for this variant")
    description: Optional[str] = Field(None, max_length=200)
    available: bool = True


class NutritionalInfoSchema(BaseModel):
    """Schema for nutritional information."""
    calories: Optional[int] = Field(None, ge=0)
    protein: Optional[float] = Field(None, ge=0)
    carbs: Optional[float] = Field(None, ge=0)
    fat: Optional[float] = Field(None, ge=0)
    fiber: Optional[float] = Field(None, ge=0)
    sugar: Optional[float] = Field(None, ge=0)
    sodium: Optional[float] = Field(None, ge=0)


class ItemCreateSchema(BaseModel):
    """Schema for creating a new item."""
    name: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    price: float = Field(..., ge=0, description="Item price")
    cost: Optional[float] = Field(None, ge=0, description="Cost price for profit calculation")
    
    category_id: Optional[str] = None
    item_type: ItemType = ItemType.PRODUCT
    
    is_available: bool = True
    stock_quantity: Optional[int] = Field(None, ge=0)
    low_stock_threshold: Optional[int] = Field(None, ge=0)
    track_inventory: bool = False
    
    images: List[str] = Field(default_factory=list)
    thumbnail: Optional[str] = None
    
    variants: List[ItemVariantSchema] = Field(default_factory=list)
    customizable: bool = False
    
    preparation_time: Optional[int] = Field(None, ge=0, description="Preparation time in minutes")
    nutritional_info: Optional[NutritionalInfoSchema] = None
    allergens: List[str] = Field(default_factory=list)
    ingredients: List[str] = Field(default_factory=list)
    
    # Pharmacy-specific fields
    prescription_required: Optional[bool] = None
    medicine_type: Optional[str] = Field(None, max_length=100)
    dosage: Optional[str] = Field(None, max_length=100)
    manufacturer: Optional[str] = Field(None, max_length=200)
    expiry_date: Optional[datetime] = None
    
    # Store-specific fields
    brand: Optional[str] = Field(None, max_length=100)
    model: Optional[str] = Field(None, max_length=100)
    sku: Optional[str] = Field(None, max_length=100)
    barcode: Optional[str] = Field(None, max_length=100)
    
    tags: List[str] = Field(default_factory=list)
    search_keywords: List[str] = Field(default_factory=list)


class ItemUpdateSchema(BaseModel):
    """Schema for updating an existing item."""
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    price: Optional[float] = Field(None, ge=0)
    cost: Optional[float] = Field(None, ge=0)
    
    category_id: Optional[str] = None
    item_type: Optional[ItemType] = None
    status: Optional[ItemStatus] = None
    
    is_available: Optional[bool] = None
    stock_quantity: Optional[int] = Field(None, ge=0)
    low_stock_threshold: Optional[int] = Field(None, ge=0)
    track_inventory: Optional[bool] = None
    
    images: Optional[List[str]] = None
    thumbnail: Optional[str] = None
    
    variants: Optional[List[ItemVariantSchema]] = None
    customizable: Optional[bool] = None
    
    preparation_time: Optional[int] = Field(None, ge=0)
    nutritional_info: Optional[NutritionalInfoSchema] = None
    allergens: Optional[List[str]] = None
    ingredients: Optional[List[str]] = None
    
    # Pharmacy-specific fields
    prescription_required: Optional[bool] = None
    medicine_type: Optional[str] = Field(None, max_length=100)
    dosage: Optional[str] = Field(None, max_length=100)
    manufacturer: Optional[str] = Field(None, max_length=200)
    expiry_date: Optional[datetime] = None
    
    # Store-specific fields
    brand: Optional[str] = Field(None, max_length=100)
    model: Optional[str] = Field(None, max_length=100)
    sku: Optional[str] = Field(None, max_length=100)
    barcode: Optional[str] = Field(None, max_length=100)
    
    tags: Optional[List[str]] = None
    search_keywords: Optional[List[str]] = None


class ItemResponseSchema(BaseModel):
    """Schema for item response."""
    id: str
    business_id: str
    name: str
    description: Optional[str]
    price: float
    cost: Optional[float]
    
    category_id: Optional[str]
    category_name: Optional[str]
    item_type: str
    status: str
    
    is_available: bool
    stock_quantity: Optional[int]
    low_stock_threshold: Optional[int]
    track_inventory: bool
    
    images: List[str]
    thumbnail: Optional[str]
    
    variants: List[Dict[str, Any]]
    customizable: bool
    
    preparation_time: Optional[int]
    nutritional_info: Optional[Dict[str, Any]]
    allergens: List[str]
    ingredients: List[str]
    
    # Pharmacy-specific fields
    prescription_required: Optional[bool]
    medicine_type: Optional[str]
    dosage: Optional[str]
    manufacturer: Optional[str]
    expiry_date: Optional[str]
    
    # Store-specific fields
    brand: Optional[str]
    model: Optional[str]
    sku: Optional[str]
    barcode: Optional[str]
    
    # Analytics
    views_count: int
    orders_count: int
    rating: float
    reviews_count: int
    
    tags: List[str]
    search_keywords: List[str]
    
    created_at: str
    updated_at: str


class ItemListResponseSchema(BaseModel):
    """Schema for paginated item list response."""
    items: List[ItemResponseSchema]
    total: int
    page: int
    page_size: int
    total_pages: int


class ItemSearchSchema(BaseModel):
    """Schema for item search parameters."""
    query: Optional[str] = Field(None, description="Search query")
    category_id: Optional[str] = None
    item_type: Optional[ItemType] = None
    status: Optional[ItemStatus] = None
    is_available: Optional[bool] = None
    min_price: Optional[float] = Field(None, ge=0)
    max_price: Optional[float] = Field(None, ge=0)
    tags: Optional[List[str]] = None
    in_stock_only: Optional[bool] = None
    
    # Sorting
    sort_by: Optional[str] = Field("name", description="Field to sort by")
    sort_order: Optional[str] = Field("asc", pattern="^(asc|desc)$")
    
    # Pagination
    page: int = Field(1, ge=1)
    page_size: int = Field(20, ge=1, le=100)


class ItemCategoryCreateSchema(BaseModel):
    """Schema for creating a new item category."""
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    display_order: int = Field(0, ge=0)
    color: Optional[str] = Field(None, pattern="^#[0-9A-Fa-f]{6}$")
    icon: Optional[str] = Field(None, max_length=100)


class ItemCategoryUpdateSchema(BaseModel):
    """Schema for updating an existing item category."""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    display_order: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = None
    color: Optional[str] = Field(None, pattern="^#[0-9A-Fa-f]{6}$")
    icon: Optional[str] = Field(None, max_length=100)


class ItemCategoryResponseSchema(BaseModel):
    """Schema for item category response."""
    id: str
    business_id: str
    name: str
    description: Optional[str]
    display_order: int
    is_active: bool
    color: Optional[str]
    icon: Optional[str]
    items_count: int
    active_items_count: int
    created_at: str
    updated_at: str


class ItemStockUpdateSchema(BaseModel):
    """Schema for updating item stock."""
    quantity: int = Field(..., ge=0, description="New stock quantity")
    track_inventory: Optional[bool] = None
    low_stock_threshold: Optional[int] = Field(None, ge=0)


class ItemAvailabilityUpdateSchema(BaseModel):
    """Schema for updating item availability."""
    is_available: bool = Field(..., description="Item availability status")


class ItemBulkOperationSchema(BaseModel):
    """Schema for bulk operations on items."""
    item_ids: List[str] = Field(..., min_items=1, description="List of item IDs")
    operation: str = Field(..., pattern="^(delete|activate|deactivate|update_category)$")
    data: Optional[Dict[str, Any]] = Field(None, description="Additional data for the operation")


class ItemAnalyticsSchema(BaseModel):
    """Schema for item analytics data."""
    item_id: str
    views_count: int
    orders_count: int
    rating: float
    reviews_count: int
    revenue: float
    profit: Optional[float]
    last_ordered: Optional[str]
    popularity_rank: Optional[int]


class ItemAnalyticsResponseSchema(BaseModel):
    """Schema for item analytics response."""
    analytics: List[ItemAnalyticsSchema]
    summary: Dict[str, Any]
    period: str
    total_items: int
