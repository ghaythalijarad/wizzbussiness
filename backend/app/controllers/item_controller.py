"""
Item management controller with comprehensive CRUD operations.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Path, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
import logging
import shutil
import os

from ..schemas.item import (
    ItemCreateSchema, ItemUpdateSchema, ItemResponseSchema, ItemListResponseSchema,
    ItemSearchSchema, ItemCategoryCreateSchema, ItemCategoryUpdateSchema,
    ItemCategoryResponseSchema, ItemStockUpdateSchema, ItemAvailabilityUpdateSchema,
    ItemBulkOperationSchema, ItemAnalyticsResponseSchema
)
from ..services.item_service import ItemService
from ..services.auth_service import current_active_user
from ..models.user_sql import User
from ..core.db_manager import get_async_session


# Create router
item_controller = APIRouter(prefix="/api/items", tags=["Items"])
category_controller = APIRouter(prefix="/api/categories", tags=["Item Categories"])

UPLOAD_DIR = "uploads/items"


@item_controller.post("/", response_model=ItemResponseSchema)
async def create_item(
    business_id: int = Query(..., description="Business ID"),
    item_data: ItemCreateSchema = ...,
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Create a new item for a business."""
    try:
        # Verify user owns the business
        from ..models.business import Business
        business = await Business.get(business_id, session=session)
        if not business:
            raise HTTPException(status_code=404, detail="Business not found")
        
        if business.owner_id != current_user.id:
            raise HTTPException(status_code=403, detail="You can only create items for your own business")
        
        # Ensure user has an ID
        if not current_user.id:
            raise HTTPException(status_code=401, detail="User authentication required")
        
        item = await ItemService.create_item(business_id, item_data, current_user, session)
        return ItemResponseSchema.from_orm(item)
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error creating item: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.get("/", response_model=ItemListResponseSchema)
async def get_items(
    business_id: int = Query(..., description="Business ID"),
    query: Optional[str] = Query(None, description="Search query"),
    category_id: Optional[str] = Query(None, description="Category ID filter"),
    item_type: Optional[str] = Query(None, description="Item type filter"),
    status: Optional[str] = Query(None, description="Status filter"),
    is_available: Optional[bool] = Query(None, description="Availability filter"),
    min_price: Optional[float] = Query(None, ge=0, description="Minimum price filter"),
    max_price: Optional[float] = Query(None, ge=0, description="Maximum price filter"),
    in_stock_only: Optional[bool] = Query(None, description="Show only in-stock items"),
    sort_by: str = Query("name", description="Sort field"),
    sort_order: str = Query("asc", regex="^(asc|desc)$", description="Sort order"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Page size"),
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Get items for a business with search and filtering."""
    try:
        # Convert string enums to proper types
        item_type_enum = None
        if item_type:
            try:
                from ..models.item import ItemType
                item_type_enum = ItemType(item_type.lower())
            except ValueError:
                raise HTTPException(status_code=400, detail=f"Invalid item type: {item_type}")
        
        status_enum = None
        if status:
            try:
                from ..models.item import ItemStatus
                status_enum = ItemStatus(status.lower())
            except ValueError:
                raise HTTPException(status_code=400, detail=f"Invalid status: {status}")
        
        search_params = ItemSearchSchema(
            query=query,
            category_id=category_id,
            item_type=item_type_enum,
            status=status_enum,
            is_available=is_available,
            min_price=min_price,
            max_price=max_price,
            in_stock_only=in_stock_only,
            sort_by=sort_by,
            sort_order=sort_order,
            page=page,
            page_size=page_size
        )
        
        items, total = await ItemService.search_items(business_id, search_params, session)
        
        total_pages = (total + page_size - 1) // page_size
        
        return ItemListResponseSchema(
            items=[ItemResponseSchema.from_orm(item) for item in items],
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logging.error(f"Error getting items: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.get("/{item_id}", response_model=ItemResponseSchema)
async def get_item(
    item_id: int = Path(..., description="Item ID"),
    business_id: int = Query(..., description="Business ID"),
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Get a specific item by ID."""
    try:
        item = await ItemService.get_item(business_id, item_id, session)
        if not item:
            raise HTTPException(status_code=404, detail="Item not found")
        
        return ItemResponseSchema.from_orm(item)
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error getting item: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.put("/{item_id}", response_model=ItemResponseSchema)
async def update_item(
    item_id: int = Path(..., description="Item ID"),
    business_id: int = Query(..., description="Business ID"),
    update_data: ItemUpdateSchema = ...,
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Update an existing item."""
    try:
        item = await ItemService.update_item(business_id, item_id, update_data, session)
        if not item:
            raise HTTPException(status_code=404, detail="Item not found")
        
        return ItemResponseSchema.from_orm(item)
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error updating item: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.delete("/{item_id}")
async def delete_item(
    item_id: int = Path(..., description="Item ID"),
    business_id: int = Query(..., description="Business ID"),
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Delete an item."""
    try:
        success = await ItemService.delete_item(business_id, item_id, session)
        if not success:
            raise HTTPException(status_code=404, detail="Item not found")
        
        return {"message": "Item deleted successfully"}
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error deleting item: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.put("/{item_id}/stock", response_model=ItemResponseSchema)
async def update_item_stock(
    item_id: int = Path(..., description="Item ID"),
    business_id: int = Query(..., description="Business ID"),
    stock_data: ItemStockUpdateSchema = ...,
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Update item stock quantity."""
    try:
        item = await ItemService.update_item_stock(business_id, item_id, stock_data, session)
        if not item:
            raise HTTPException(status_code=404, detail="Item not found")
        
        return ItemResponseSchema.from_orm(item)
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error updating item stock: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.put("/{item_id}/availability", response_model=ItemResponseSchema)
async def update_item_availability(
    item_id: int = Path(..., description="Item ID"),
    business_id: int = Query(..., description="Business ID"),
    availability_data: ItemAvailabilityUpdateSchema = ...,
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Update item availability status."""
    try:
        item = await ItemService.update_item_availability(business_id, item_id, availability_data, session)
        if not item:
            raise HTTPException(status_code=404, detail="Item not found")
        
        return ItemResponseSchema.from_orm(item)
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error updating item availability: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.get("/category/{category_id}", response_model=List[ItemResponseSchema])
async def get_items_by_category(
    category_id: str = Path(..., description="Category ID"),
    business_id: int = Query(..., description="Business ID"),
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Get all items in a specific category."""
    try:
        category_obj_id = PydanticObjectId(category_id) if category_id != "uncategorized" else None
        
        items = await ItemService.get_items_by_category(business_id, category_obj_id, session)
        return [ItemResponseSchema.from_orm(item) for item in items]
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logging.error(f"Error getting items by category: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.get("/analytics/summary")
async def get_item_analytics(
    business_id: int = Query(..., description="Business ID"),
    days: int = Query(30, ge=1, le=365, description="Number of days for analytics"),
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Get item analytics for a business."""
    try:
        analytics = await ItemService.get_item_analytics(business_id, days, session)
        return analytics
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logging.error(f"Error getting item analytics: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.get("/low-stock/list", response_model=List[ItemResponseSchema])
async def get_low_stock_items(
    business_id: int = Query(..., description="Business ID"),
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Get items that are low on stock."""
    try:
        items = await ItemService.get_low_stock_items(business_id, session)
        return [ItemResponseSchema.from_orm(item) for item in items]
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logging.error(f"Error getting low stock items: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.post("/{item_id}/upload-image")
async def upload_item_image(
    item_id: int,
    file: UploadFile = File(...),
    item_service: ItemService = Depends(),
    current_user: User = Depends(current_active_user)
):
    if not os.path.exists(UPLOAD_DIR):
        os.makedirs(UPLOAD_DIR)

    if not file.filename:
        raise HTTPException(status_code=400, detail="No file name provided.")

    file_path = os.path.join(UPLOAD_DIR, file.filename)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    image_url = f"/uploads/items/{file.filename}"
    
    try:
        item_obj_id = PydanticObjectId(item_id)
        await item_service.update_item_image(item_obj_id, image_url)
    except Exception as e:
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(status_code=500, detail=f"Failed to update item image: {e}")
        
    return {"image_url": image_url}


# Category management endpoints
@category_controller.post("/", response_model=ItemCategoryResponseSchema)
async def create_category(
    business_id: int = Query(..., description="Business ID"),
    category_data: ItemCategoryCreateSchema = ...,
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Create a new item category."""
    try:
        category = await ItemService.create_category(business_id, category_data, session)
        return ItemCategoryResponseSchema.from_orm(category)
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logging.error(f"Error creating category: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@category_controller.get("/", response_model=List[ItemCategoryResponseSchema])
async def get_categories(
    business_id: int = Query(..., description="Business ID"),
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Get all categories for a business."""
    try:
        categories = await ItemService.get_categories(business_id, session)
        return [ItemCategoryResponseSchema.from_orm(category) for category in categories]
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logging.error(f"Error getting categories: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@category_controller.put("/{category_id}", response_model=ItemCategoryResponseSchema)
async def update_category(
    category_id: int = Path(..., description="Category ID"),
    business_id: int = Query(..., description="Business ID"),
    update_data: ItemCategoryUpdateSchema = ...,
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Update an existing category."""
    try:
        category = await ItemService.update_category(business_id, category_id, update_data, session)
        if not category:
            raise HTTPException(status_code=404, detail="Category not found")
        
        return ItemCategoryResponseSchema.from_orm(category)
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error updating category: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@category_controller.delete("/{category_id}")
async def delete_category(
    category_id: int = Path(..., description="Category ID"),
    business_id: int = Query(..., description="Business ID"),
    current_user: User = Depends(current_active_user),
    session: AsyncSession = Depends(get_async_session)
):
    """Delete a category and move items to uncategorized."""
    try:
        success = await ItemService.delete_category(business_id, category_id, session)
        if not success:
            raise HTTPException(status_code=404, detail="Category not found")
        
        return {"message": "Category deleted successfully"}
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error deleting category: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")
