"""
Item management controller with comprehensive CRUD operations.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Path, UploadFile, File
from beanie import PydanticObjectId
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
from ..models.user import User


# Create router
item_controller = APIRouter(prefix="/api/items", tags=["Items"])
category_controller = APIRouter(prefix="/api/categories", tags=["Item Categories"])

UPLOAD_DIR = "uploads/items"


@item_controller.post("/", response_model=ItemResponseSchema)
async def create_item(
    business_id: str = Query(..., description="Business ID"),
    item_data: ItemCreateSchema = ...,
    current_user: User = Depends(current_active_user)
):
    """Create a new item for a business."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        
        # Verify user owns the business (you might want to add this check)
        # This would require a method to check business ownership
        
        item = await ItemService.create_item(business_obj_id, item_data)
        return ItemResponseSchema(**item.to_dict())
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logging.error(f"Error creating item: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.get("/", response_model=ItemListResponseSchema)
async def get_items(
    business_id: str = Query(..., description="Business ID"),
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
    current_user: User = Depends(current_active_user)
):
    """Get items for a business with search and filtering."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        
        search_params = ItemSearchSchema(
            query=query,
            category_id=category_id,
            item_type=item_type,
            status=status,
            is_available=is_available,
            min_price=min_price,
            max_price=max_price,
            in_stock_only=in_stock_only,
            sort_by=sort_by,
            sort_order=sort_order,
            page=page,
            page_size=page_size
        )
        
        items, total = await ItemService.search_items(business_obj_id, search_params)
        
        total_pages = (total + page_size - 1) // page_size
        
        return ItemListResponseSchema(
            items=[ItemResponseSchema(**item.to_dict()) for item in items],
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
    item_id: str = Path(..., description="Item ID"),
    business_id: str = Query(..., description="Business ID"),
    current_user: User = Depends(current_active_user)
):
    """Get a specific item by ID."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        item_obj_id = PydanticObjectId(item_id)
        
        item = await ItemService.get_item(business_obj_id, item_obj_id)
        if not item:
            raise HTTPException(status_code=404, detail="Item not found")
        
        return ItemResponseSchema(**item.to_dict())
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error getting item: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.put("/{item_id}", response_model=ItemResponseSchema)
async def update_item(
    item_id: str = Path(..., description="Item ID"),
    business_id: str = Query(..., description="Business ID"),
    update_data: ItemUpdateSchema = ...,
    current_user: User = Depends(current_active_user)
):
    """Update an existing item."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        item_obj_id = PydanticObjectId(item_id)
        
        item = await ItemService.update_item(business_obj_id, item_obj_id, update_data)
        if not item:
            raise HTTPException(status_code=404, detail="Item not found")
        
        return ItemResponseSchema(**item.to_dict())
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error updating item: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.delete("/{item_id}")
async def delete_item(
    item_id: str = Path(..., description="Item ID"),
    business_id: str = Query(..., description="Business ID"),
    current_user: User = Depends(current_active_user)
):
    """Delete an item."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        item_obj_id = PydanticObjectId(item_id)
        
        success = await ItemService.delete_item(business_obj_id, item_obj_id)
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
    item_id: str = Path(..., description="Item ID"),
    business_id: str = Query(..., description="Business ID"),
    stock_data: ItemStockUpdateSchema = ...,
    current_user: User = Depends(current_active_user)
):
    """Update item stock quantity."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        item_obj_id = PydanticObjectId(item_id)
        
        item = await ItemService.update_item_stock(business_obj_id, item_obj_id, stock_data)
        if not item:
            raise HTTPException(status_code=404, detail="Item not found")
        
        return ItemResponseSchema(**item.to_dict())
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error updating item stock: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.put("/{item_id}/availability", response_model=ItemResponseSchema)
async def update_item_availability(
    item_id: str = Path(..., description="Item ID"),
    business_id: str = Query(..., description="Business ID"),
    availability_data: ItemAvailabilityUpdateSchema = ...,
    current_user: User = Depends(current_active_user)
):
    """Update item availability status."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        item_obj_id = PydanticObjectId(item_id)
        
        item = await ItemService.update_item_availability(business_obj_id, item_obj_id, availability_data)
        if not item:
            raise HTTPException(status_code=404, detail="Item not found")
        
        return ItemResponseSchema(**item.to_dict())
        
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
    business_id: str = Query(..., description="Business ID"),
    current_user: User = Depends(current_active_user)
):
    """Get all items in a specific category."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        category_obj_id = PydanticObjectId(category_id) if category_id != "uncategorized" else None
        
        items = await ItemService.get_items_by_category(business_obj_id, category_obj_id)
        return [ItemResponseSchema(**item.to_dict()) for item in items]
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logging.error(f"Error getting items by category: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.get("/analytics/summary")
async def get_item_analytics(
    business_id: str = Query(..., description="Business ID"),
    days: int = Query(30, ge=1, le=365, description="Number of days for analytics"),
    current_user: User = Depends(current_active_user)
):
    """Get item analytics for a business."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        
        analytics = await ItemService.get_item_analytics(business_obj_id, days)
        return analytics
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logging.error(f"Error getting item analytics: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.get("/low-stock/list", response_model=List[ItemResponseSchema])
async def get_low_stock_items(
    business_id: str = Query(..., description="Business ID"),
    current_user: User = Depends(current_active_user)
):
    """Get items that are low on stock."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        
        items = await ItemService.get_low_stock_items(business_obj_id)
        return [ItemResponseSchema(**item.to_dict()) for item in items]
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logging.error(f"Error getting low stock items: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@item_controller.post("/{item_id}/upload-image")
async def upload_item_image(
    item_id: str,
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
    business_id: str = Query(..., description="Business ID"),
    category_data: ItemCategoryCreateSchema = ...,
    current_user: User = Depends(current_active_user)
):
    """Create a new item category."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        
        category = await ItemService.create_category(business_obj_id, category_data)
        return ItemCategoryResponseSchema(**category.to_dict())
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logging.error(f"Error creating category: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@category_controller.get("/", response_model=List[ItemCategoryResponseSchema])
async def get_categories(
    business_id: str = Query(..., description="Business ID"),
    current_user: User = Depends(current_active_user)
):
    """Get all categories for a business."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        
        categories = await ItemService.get_categories(business_obj_id)
        return [ItemCategoryResponseSchema(**category.to_dict()) for category in categories]
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logging.error(f"Error getting categories: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@category_controller.put("/{category_id}", response_model=ItemCategoryResponseSchema)
async def update_category(
    category_id: str = Path(..., description="Category ID"),
    business_id: str = Query(..., description="Business ID"),
    update_data: ItemCategoryUpdateSchema = ...,
    current_user: User = Depends(current_active_user)
):
    """Update an existing category."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        category_obj_id = PydanticObjectId(category_id)
        
        category = await ItemService.update_category(business_obj_id, category_obj_id, update_data)
        if not category:
            raise HTTPException(status_code=404, detail="Category not found")
        
        return ItemCategoryResponseSchema(**category.to_dict())
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Error updating category: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


@category_controller.delete("/{category_id}")
async def delete_category(
    category_id: str = Path(..., description="Category ID"),
    business_id: str = Query(..., description="Business ID"),
    current_user: User = Depends(current_active_user)
):
    """Delete a category and move items to uncategorized."""
    try:
        business_obj_id = PydanticObjectId(business_id)
        category_obj_id = PydanticObjectId(category_id)
        
        success = await ItemService.delete_category(business_obj_id, category_obj_id)
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
