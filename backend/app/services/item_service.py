"""
Item service layer for business logic.
"""
from typing import Optional, List, Dict, Any, Tuple
from beanie import PydanticObjectId
from beanie.operators import In, And, Or, RegEx, Exists
from datetime import datetime
import logging

from ..models.item import Item, ItemCategory, ItemStatus, ItemType
from ..models.business import Business
from ..schemas.item import (
    ItemCreateSchema, ItemUpdateSchema, ItemSearchSchema,
    ItemCategoryCreateSchema, ItemCategoryUpdateSchema,
    ItemStockUpdateSchema, ItemAvailabilityUpdateSchema
)


class ItemService:
    """Service class for item-related operations."""
    
    @staticmethod
    async def create_item(business_id: PydanticObjectId, item_data: ItemCreateSchema, user_id: PydanticObjectId) -> Item:
        """Create a new item for a business."""
        try:
            # Verify business exists
            business = await Business.get(business_id)
            if not business:
                raise ValueError("Business not found")
            
            # Get category name if category_id is provided
            category_name = None
            if item_data.category_id:
                category = await ItemCategory.find_one(
                    And(
                        ItemCategory.business_id == business_id,
                        ItemCategory.id == PydanticObjectId(item_data.category_id),
                        ItemCategory.is_active == True
                    )
                )
                if category:
                    category_name = category.name
            
            # Create item
            item_dict = item_data.dict()
            item_dict['business_id'] = business_id
            item_dict['category_name'] = category_name
            item_dict['created_by'] = user_id
            item_dict['updated_by'] = user_id
            
            item = Item(**item_dict)
            
            await item.insert()
            
            # Update category item count if category exists
            if item_data.category_id:
                await ItemService._update_category_counts(
                    business_id, PydanticObjectId(item_data.category_id)
                )
            
            logging.info(f"Created item {item.id} for business {business_id} by user {user_id}")
            return item
            
        except Exception as e:
            logging.error(f"Error creating item: {e}")
            raise
    
    @staticmethod
    async def get_item(business_id: PydanticObjectId, item_id: PydanticObjectId) -> Optional[Item]:
        """Get a specific item by ID."""
        try:
            item = await Item.find_one(
                And(
                    Item.business_id == business_id,
                    Item.id == item_id
                )
            )
            
            if item:
                # Increment view count
                item.increment_views()
                await item.save()
            
            return item
            
        except Exception as e:
            logging.error(f"Error getting item {item_id}: {e}")
            raise
    
    @staticmethod
    async def update_item(
        business_id: PydanticObjectId, 
        item_id: PydanticObjectId, 
        update_data: ItemUpdateSchema
    ) -> Optional[Item]:
        """Update an existing item."""
        try:
            item = await Item.find_one(
                And(
                    Item.business_id == business_id,
                    Item.id == item_id
                )
            )
            
            if not item:
                return None
            
            # Store old category for count updates
            old_category_id = item.category_id
            
            # Update fields
            update_dict = update_data.dict(exclude_unset=True)
            
            # Get new category name if category_id is being updated
            if "category_id" in update_dict and update_dict["category_id"]:
                category = await ItemCategory.find_one(
                    And(
                        ItemCategory.business_id == business_id,
                        ItemCategory.id == PydanticObjectId(update_dict["category_id"]),
                        ItemCategory.is_active == True
                    )
                )
                if category:
                    update_dict["category_name"] = category.name
                else:
                    update_dict["category_name"] = None
            elif "category_id" in update_dict and not update_dict["category_id"]:
                update_dict["category_name"] = None
            
            # Update item
            for field, value in update_dict.items():
                setattr(item, field, value)
            
            item.updated_at = datetime.utcnow()
            await item.save()
            
            # Update category counts
            if old_category_id and old_category_id != item.category_id:
                await ItemService._update_category_counts(
                    business_id, PydanticObjectId(old_category_id)
                )
            
            if item.category_id:
                await ItemService._update_category_counts(
                    business_id, PydanticObjectId(item.category_id)
                )
            
            logging.info(f"Updated item {item_id} for business {business_id}")
            return item
            
        except Exception as e:
            logging.error(f"Error updating item {item_id}: {e}")
            raise
    
    @staticmethod
    async def delete_item(business_id: PydanticObjectId, item_id: PydanticObjectId) -> bool:
        """Delete an item."""
        try:
            item = await Item.find_one(
                And(
                    Item.business_id == business_id,
                    Item.id == item_id
                )
            )
            
            if not item:
                return False
            
            category_id = item.category_id
            await item.delete()
            
            # Update category counts
            if category_id:
                await ItemService._update_category_counts(
                    business_id, PydanticObjectId(category_id)
                )
            
            logging.info(f"Deleted item {item_id} for business {business_id}")
            return True
            
        except Exception as e:
            logging.error(f"Error deleting item {item_id}: {e}")
            raise
    
    @staticmethod
    async def search_items(
        business_id: PydanticObjectId, 
        search_params: ItemSearchSchema
    ) -> Tuple[List[Item], int]:
        """Search and filter items with pagination."""
        try:
            # Build query
            query_conditions = [Item.business_id == business_id]
            
            # Text search
            if search_params.query:
                # Use regex-based search with case-insensitive matching
                query_text = search_params.query.strip()
                
                # Build text search conditions
                text_conditions = [
                    RegEx(Item.name, query_text, "i"),
                    In(Item.tags, [query_text.lower()]),
                    In(Item.search_keywords, [query_text.lower()])
                ]
                
                # Add description search only if the field exists and is not None
                text_conditions.append(
                    And(
                        Exists(Item.description, True),
                        RegEx(Item.description, query_text, "i")
                    )
                )
                
                query_conditions.append(Or(*text_conditions))
            
            # Category filter
            if search_params.category_id:
                query_conditions.append(Item.category_id == search_params.category_id)
            
            # Type filter
            if search_params.item_type:
                query_conditions.append(Item.item_type == search_params.item_type)
            
            # Status filter
            if search_params.status:
                query_conditions.append(Item.status == search_params.status)
            
            # Availability filter
            if search_params.is_available is not None:
                query_conditions.append(Item.is_available == search_params.is_available)
            
            # Price range filter
            if search_params.min_price is not None:
                query_conditions.append(Item.price >= search_params.min_price)
            if search_params.max_price is not None:
                query_conditions.append(Item.price <= search_params.max_price)
            
            # In stock filter
            if search_params.in_stock_only:
                query_conditions.append(
                    Or(
                        Item.track_inventory == False,
                        And(
                            Item.track_inventory == True,
                            Item.stock_quantity > 0
                        )
                    )
                )
            
            # Tags filter
            if search_params.tags:
                for tag in search_params.tags:
                    query_conditions.append(In(Item.tags, [tag.lower()]))
            
            # Combine all conditions
            query = And(*query_conditions) if len(query_conditions) > 1 else query_conditions[0]
            
            # Get total count
            total = await Item.find(query).count()
            
            # Apply sorting
            sort_by = search_params.sort_by or "name"
            if search_params.sort_order == "desc":
                sort_key = f"-{sort_by}"
            else:
                sort_key = sort_by
            
            # Apply pagination
            skip = (search_params.page - 1) * search_params.page_size
            items = await Item.find(query)\
                .sort(sort_key)\
                .skip(skip)\
                .limit(search_params.page_size)\
                .to_list()
            
            return items, total
            
        except Exception as e:
            logging.error(f"Error searching items: {e}")
            raise
    
    @staticmethod
    async def update_item_stock(
        business_id: PydanticObjectId, 
        item_id: PydanticObjectId, 
        stock_data: ItemStockUpdateSchema
    ) -> Optional[Item]:
        """Update item stock quantity."""
        try:
            item = await Item.find_one(
                And(
                    Item.business_id == business_id,
                    Item.id == item_id
                )
            )
            
            if not item:
                return None
            
            # Update stock-related fields
            if stock_data.track_inventory is not None:
                item.track_inventory = stock_data.track_inventory
            
            if stock_data.low_stock_threshold is not None:
                item.low_stock_threshold = stock_data.low_stock_threshold
            
            # Update stock quantity
            item.update_stock(stock_data.quantity)
            await item.save()
            
            logging.info(f"Updated stock for item {item_id}: {stock_data.quantity}")
            return item
            
        except Exception as e:
            logging.error(f"Error updating item stock: {e}")
            raise
    
    @staticmethod
    async def update_item_availability(
        business_id: PydanticObjectId, 
        item_id: PydanticObjectId, 
        availability_data: ItemAvailabilityUpdateSchema
    ) -> Optional[Item]:
        """Update item availability."""
        try:
            item = await Item.find_one(
                And(
                    Item.business_id == business_id,
                    Item.id == item_id
                )
            )
            
            if not item:
                return None
            
            item.update_availability(availability_data.is_available)
            await item.save()
            
            # Update category counts
            if item.category_id:
                await ItemService._update_category_counts(
                    business_id, PydanticObjectId(item.category_id)
                )
            
            logging.info(f"Updated availability for item {item_id}: {availability_data.is_available}")
            return item
            
        except Exception as e:
            logging.error(f"Error updating item availability: {e}")
            raise
    
    @staticmethod
    async def get_items_by_category(
        business_id: PydanticObjectId, 
        category_id: Optional[PydanticObjectId] = None
    ) -> List[Item]:
        """Get items by category."""
        try:
            if category_id:
                query = And(
                    Item.business_id == business_id,
                    Item.category_id == str(category_id)
                )
            else:
                query = And(
                    Item.business_id == business_id,
                    Item.category_id == None
                )
            
            items = await Item.find(query).sort(Item.name).to_list()
            return items
            
        except Exception as e:
            logging.error(f"Error getting items by category: {e}")
            raise
    
    @staticmethod
    async def create_category(
        business_id: PydanticObjectId, 
        category_data: ItemCategoryCreateSchema
    ) -> ItemCategory:
        """Create a new item category."""
        try:
            # Verify business exists
            business = await Business.get(business_id)
            if not business:
                raise ValueError("Business not found")
            
            category = ItemCategory(
                business_id=business_id,
                **category_data.dict()
            )
            
            await category.insert()
            logging.info(f"Created category {category.id} for business {business_id}")
            return category
            
        except Exception as e:
            logging.error(f"Error creating category: {e}")
            raise
    
    @staticmethod
    async def get_categories(business_id: PydanticObjectId) -> List[ItemCategory]:
        """Get all categories for a business."""
        try:
            categories = await ItemCategory.find(
                ItemCategory.business_id == business_id
            ).sort(ItemCategory.display_order, ItemCategory.name).to_list()
            
            return categories
            
        except Exception as e:
            logging.error(f"Error getting categories: {e}")
            raise
    
    @staticmethod
    async def update_category(
        business_id: PydanticObjectId, 
        category_id: PydanticObjectId, 
        update_data: ItemCategoryUpdateSchema
    ) -> Optional[ItemCategory]:
        """Update an existing category."""
        try:
            category = await ItemCategory.find_one(
                And(
                    ItemCategory.business_id == business_id,
                    ItemCategory.id == category_id
                )
            )
            
            if not category:
                return None
            
            # Update fields
            update_dict = update_data.dict(exclude_unset=True)
            for field, value in update_dict.items():
                setattr(category, field, value)
            
            category.updated_at = datetime.utcnow()
            await category.save()
            
            # Update category name in items if name changed
            if "name" in update_dict:
                await Item.find(
                    And(
                        Item.business_id == business_id,
                        Item.category_id == str(category_id)
                    )
                ).update({"$set": {"category_name": update_dict["name"]}})
            
            logging.info(f"Updated category {category_id} for business {business_id}")
            return category
            
        except Exception as e:
            logging.error(f"Error updating category: {e}")
            raise
    
    @staticmethod
    async def delete_category(business_id: PydanticObjectId, category_id: PydanticObjectId) -> bool:
        """Delete a category and move items to uncategorized."""
        try:
            category = await ItemCategory.find_one(
                And(
                    ItemCategory.business_id == business_id,
                    ItemCategory.id == category_id
                )
            )
            
            if not category:
                return False
            
            # Move items to uncategorized
            await Item.find(
                And(
                    Item.business_id == business_id,
                    Item.category_id == str(category_id)
                )
            ).update({
                "$set": {
                    "category_id": None,
                    "category_name": None,
                    "updated_at": datetime.utcnow()
                }
            })
            
            await category.delete()
            logging.info(f"Deleted category {category_id} for business {business_id}")
            return True
            
        except Exception as e:
            logging.error(f"Error deleting category: {e}")
            raise
    
    @staticmethod
    async def _update_category_counts(business_id: PydanticObjectId, category_id: PydanticObjectId):
        """Update item counts for a category."""
        try:
            category = await ItemCategory.get(category_id)
            if not category:
                return
            
            # Count total items in category
            total_items = await Item.find(
                And(
                    Item.business_id == business_id,
                    Item.category_id == str(category_id)
                )
            ).count()
            
            # Count active items in category
            active_items = await Item.find(
                And(
                    Item.business_id == business_id,
                    Item.category_id == str(category_id),
                    Item.is_available == True,
                    Item.status == ItemStatus.ACTIVE
                )
            ).count()
            
            category.update_item_counts(total_items, active_items)
            await category.save()
            
        except Exception as e:
            logging.error(f"Error updating category counts: {e}")
    
    @staticmethod
    async def get_low_stock_items(business_id: PydanticObjectId) -> List[Item]:
        """Get items that are low on stock."""
        try:
            items = await Item.find(
                And(
                    Item.business_id == business_id,
                    Item.track_inventory == True,
                    Item.low_stock_threshold != None,
                    Item.stock_quantity != None
                )
            ).to_list()
            
            # Filter for low stock items
            low_stock_items = [item for item in items if item.is_low_stock()]
            return low_stock_items
            
        except Exception as e:
            logging.error(f"Error getting low stock items: {e}")
            raise
    
    @staticmethod
    async def get_item_analytics(
        business_id: PydanticObjectId, 
        days: int = 30
    ) -> Dict[str, Any]:
        """Get item analytics for a business."""
        try:
            # Get all items for the business
            items = await Item.find(Item.business_id == business_id).to_list()
            
            total_items = len(items)
            active_items = len([item for item in items if item.is_available and item.status == ItemStatus.ACTIVE])
            total_views = sum(item.views_count for item in items)
            total_orders = sum(item.orders_count for item in items)
            
            # Calculate average rating
            rated_items = [item for item in items if item.reviews_count > 0]
            avg_rating = sum(item.rating for item in rated_items) / len(rated_items) if rated_items else 0
            
            # Top performing items
            top_items = sorted(items, key=lambda x: x.orders_count, reverse=True)[:10]
            
            return {
                "total_items": total_items,
                "active_items": active_items,
                "inactive_items": total_items - active_items,
                "total_views": total_views,
                "total_orders": total_orders,
                "average_rating": round(avg_rating, 2),
                "top_items": [item.to_dict() for item in top_items],
                "low_stock_items": len(await ItemService.get_low_stock_items(business_id))
            }
            
        except Exception as e:
            logging.error(f"Error getting item analytics: {e}")
            raise

    @staticmethod
    async def get_item_by_id(item_id: PydanticObjectId) -> Optional[Item]:
        """Get a specific item by ID for internal service use."""
        try:
            return await Item.get(item_id)
        except Exception as e:
            logging.error(f"Error getting item by id {item_id}: {e}")
            return None

    @staticmethod
    async def update_item_image(item_id: PydanticObjectId, image_url: str) -> Optional[Item]:
        """Update the image URL for an item."""
        try:
            item = await Item.get(item_id)
            if not item:
                return None
            
            item.image_url = image_url
            item.updated_at = datetime.utcnow()
            await item.save()
            
            logging.info(f"Updated image URL for item {item_id}")
            return item
        except Exception as e:
            logging.error(f"Error updating item image for {item_id}: {e}")
            raise

item_service = ItemService()
