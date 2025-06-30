"""
Item service layer for business logic using SQLAlchemy and PostgreSQL.
"""
from typing import Optional, List, Dict, Any, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from datetime import datetime
import logging

from ..models.item_sql import Item, ItemCategory, ItemStatus, ItemType
from ..models.business_sql import Business
from ..schemas.item import (
    ItemCreateSchema, ItemUpdateSchema, ItemSearchSchema,
    ItemCategoryCreateSchema, ItemCategoryUpdateSchema,
    ItemStockUpdateSchema, ItemAvailabilityUpdateSchema
)


class ItemService:
    """Service class for item-related operations using SQLAlchemy."""
    
    @staticmethod
    async def create_item(business_id: int, item_data: ItemCreateSchema, user, session: AsyncSession) -> Item:
        """Create a new item for a business."""
        try:
            # Verify business exists
            business = await session.get(Business, business_id)
            if not business:
                raise ValueError("Business not found")

            # Get category name if category_id is provided
            category_name = None
            if item_data.category_id:
                category = await session.get(ItemCategory, item_data.category_id)
                if category and category.business_id == business_id and category.is_active:
                    category_name = category.name

            # Create item
            item = Item(
                **item_data.dict(),
                business_id=business_id,
                category_name=category_name,
                created_by=user.id,
                updated_by=user.id,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            session.add(item)
            await session.commit()
            await session.refresh(item)
            logging.info(f"Created item {item.id} for business {business_id} by user {user.id}")
            return item
        except Exception as e:
            await session.rollback()
            logging.error(f"Error creating item: {e}")
            raise
    
    @staticmethod
    async def get_item(business_id: int, item_id: int, session: AsyncSession) -> Optional[Item]:
        """Get a specific item by ID."""
        try:
            result = await session.execute(
                select(Item).where(
                    Item.business_id == business_id,
                    Item.id == item_id
                )
            )
            item = result.scalars().first()
            
            if item:
                # Increment view count
                item.increment_views()
                session.add(item)
                await session.commit()
            
            return item
            
        except Exception as e:
            logging.error(f"Error getting item {item_id}: {e}")
            raise
    
    @staticmethod
    async def update_item(
        business_id: int, 
        item_id: int, 
        update_data: ItemUpdateSchema,
        session: AsyncSession
    ) -> Optional[Item]:
        """Update an existing item."""
        try:
            result = await session.execute(
                select(Item).where(
                    Item.business_id == business_id,
                    Item.id == item_id
                )
            )
            item = result.scalars().first()
            
            if not item:
                return None
            
            # Store old category for count updates
            old_category_id = item.category_id
            
            # Update fields
            update_dict = update_data.dict(exclude_unset=True)
            
            # Get new category name if category_id is being updated
            if "category_id" in update_dict and update_dict["category_id"]:
                category = await session.get(ItemCategory, update_dict["category_id"])
                if category and category.business_id == business_id and category.is_active:
                    update_dict["category_name"] = category.name
                else:
                    update_dict["category_name"] = None
            elif "category_id" in update_dict and not update_dict["category_id"]:
                update_dict["category_name"] = None
            
            # Update item
            for field, value in update_dict.items():
                setattr(item, field, value)
            
            item.updated_at = datetime.utcnow()
            session.add(item)
            await session.commit()
            
            # Update category counts
            if old_category_id and old_category_id != item.category_id:
                await ItemService._update_category_counts(
                    business_id, old_category_id, session
                )
            
            if item.category_id:
                await ItemService._update_category_counts(
                    business_id, item.category_id, session
                )
            
            logging.info(f"Updated item {item_id} for business {business_id}")
            return item
            
        except Exception as e:
            logging.error(f"Error updating item {item_id}: {e}")
            raise
    
    @staticmethod
    async def delete_item(business_id: int, item_id: int, session: AsyncSession) -> bool:
        """Delete an item."""
        try:
            result = await session.execute(
                select(Item).where(
                    Item.business_id == business_id,
                    Item.id == item_id
                )
            )
            item = result.scalars().first()
            
            if not item:
                return False
            
            category_id = item.category_id
            await session.delete(item)
            await session.commit()
            
            # Update category counts
            if category_id:
                await ItemService._update_category_counts(
                    business_id, category_id, session
                )
            
            logging.info(f"Deleted item {item_id} for business {business_id}")
            return True
            
        except Exception as e:
            logging.error(f"Error deleting item {item_id}: {e}")
            raise
    
    @staticmethod
    async def search_items(
        business_id: int, 
        search_params: ItemSearchSchema,
        session: AsyncSession
    ) -> Tuple[List[Item], int]:
        """Search and filter items with pagination."""
        try:
            # Build query
            query = select(Item).where(Item.business_id == business_id)
            
            # Text search
            if search_params.query:
                # Use regex-based search with case-insensitive matching
                query_text = search_params.query.strip()
                
                # Build text search conditions
                text_conditions = [
                    Item.name.ilike(f"%{query_text}%"),
                    Item.tags.any(query_text.lower()),
                    Item.search_keywords.any(query_text.lower())
                ]
                
                # Add description search only if the field exists and is not None
                text_conditions.append(
                    And(
                        Item.description != None,
                        Item.description.ilike(f"%{query_text}%")
                    )
                )
                
                query = query.where(Or(*text_conditions))
            
            # Category filter
            if search_params.category_id:
                query = query.where(Item.category_id == search_params.category_id)
            
            # Type filter
            if search_params.item_type:
                query = query.where(Item.item_type == search_params.item_type)
            
            # Status filter
            if search_params.status:
                query = query.where(Item.status == search_params.status)
            
            # Availability filter
            if search_params.is_available is not None:
                query = query.where(Item.is_available == search_params.is_available)
            
            # Price range filter
            if search_params.min_price is not None:
                query = query.where(Item.price >= search_params.min_price)
            if search_params.max_price is not None:
                query = query.where(Item.price <= search_params.max_price)
            
            # In stock filter
            if search_params.in_stock_only:
                query = query.where(
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
                    query = query.where(Item.tags.any(tag.lower()))
            
            # Get total count
            total = (await session.execute(query)).scalars().count()
            
            # Apply sorting
            sort_by = search_params.sort_by or "name"
            if search_params.sort_order == "desc":
                sort_key = f"-{sort_by}"
            else:
                sort_key = sort_by
            
            # Apply pagination
            skip = (search_params.page - 1) * search_params.page_size
            query = query.offset(skip).limit(search_params.page_size)
            items = (await session.execute(query)).scalars().all()
            
            return items, total
            
        except Exception as e:
            logging.error(f"Error searching items: {e}")
            raise
    
    @staticmethod
    async def update_item_stock(
        business_id: int, 
        item_id: int, 
        stock_data: ItemStockUpdateSchema,
        session: AsyncSession
    ) -> Optional[Item]:
        """Update item stock quantity."""
        try:
            result = await session.execute(
                select(Item).where(
                    Item.business_id == business_id,
                    Item.id == item_id
                )
            )
            item = result.scalars().first()
            
            if not item:
                return None
            
            # Update stock-related fields
            if stock_data.track_inventory is not None:
                item.track_inventory = stock_data.track_inventory
            
            if stock_data.low_stock_threshold is not None:
                item.low_stock_threshold = stock_data.low_stock_threshold
            
            # Update stock quantity
            item.update_stock(stock_data.quantity)
            session.add(item)
            await session.commit()
            
            logging.info(f"Updated stock for item {item_id}: {stock_data.quantity}")
            return item
            
        except Exception as e:
            logging.error(f"Error updating item stock: {e}")
            raise
    
    @staticmethod
    async def update_item_availability(
        business_id: int, 
        item_id: int, 
        availability_data: ItemAvailabilityUpdateSchema,
        session: AsyncSession
    ) -> Optional[Item]:
        """Update item availability."""
        try:
            result = await session.execute(
                select(Item).where(
                    Item.business_id == business_id,
                    Item.id == item_id
                )
            )
            item = result.scalars().first()
            
            if not item:
                return None
            
            item.update_availability(availability_data.is_available)
            session.add(item)
            await session.commit()
            
            # Update category counts
            if item.category_id:
                await ItemService._update_category_counts(
                    business_id, item.category_id, session
                )
            
            logging.info(f"Updated availability for item {item_id}: {availability_data.is_available}")
            return item
            
        except Exception as e:
            logging.error(f"Error updating item availability: {e}")
            raise
    
    @staticmethod
    async def get_items_by_category(
        business_id: int, 
        category_id: Optional[int] = None,
        session: AsyncSession
    ) -> List[Item]:
        """Get items by category."""
        try:
            if category_id:
                query = select(Item).where(
                    Item.business_id == business_id,
                    Item.category_id == category_id
                )
            else:
                query = select(Item).where(
                    Item.business_id == business_id,
                    Item.category_id == None
                )
            
            items = (await session.execute(query)).scalars().all()
            return items
            
        except Exception as e:
            logging.error(f"Error getting items by category: {e}")
            raise
    
    @staticmethod
    async def create_category(
        business_id: int, 
        category_data: ItemCategoryCreateSchema,
        session: AsyncSession
    ) -> ItemCategory:
        """Create a new item category."""
        try:
            # Verify business exists
            business = await session.get(Business, business_id)
            if not business:
                raise ValueError("Business not found")
            
            category = ItemCategory(
                business_id=business_id,
                **category_data.dict()
            )
            
            session.add(category)
            await session.commit()
            await session.refresh(category)
            logging.info(f"Created category {category.id} for business {business_id}")
            return category
            
        except Exception as e:
            logging.error(f"Error creating category: {e}")
            raise
    
    @staticmethod
    async def get_categories(business_id: int, session: AsyncSession) -> List[ItemCategory]:
        """Get all categories for a business."""
        try:
            result = await session.execute(
                select(ItemCategory).where(
                    ItemCategory.business_id == business_id
                ).order_by(ItemCategory.display_order, ItemCategory.name)
            )
            categories = result.scalars().all()
            
            return categories
            
        except Exception as e:
            logging.error(f"Error getting categories: {e}")
            raise
    
    @staticmethod
    async def update_category(
        business_id: int, 
        category_id: int, 
        update_data: ItemCategoryUpdateSchema,
        session: AsyncSession
    ) -> Optional[ItemCategory]:
        """Update an existing category."""
        try:
            result = await session.execute(
                select(ItemCategory).where(
                    ItemCategory.business_id == business_id,
                    ItemCategory.id == category_id
                )
            )
            category = result.scalars().first()
            
            if not category:
                return None
            
            # Update fields
            update_dict = update_data.dict(exclude_unset=True)
            for field, value in update_dict.items():
                setattr(category, field, value)
            
            category.updated_at = datetime.utcnow()
            session.add(category)
            await session.commit()
            
            # Update category name in items if name changed
            if "name" in update_dict:
                await session.execute(
                    select(Item).where(
                        Item.business_id == business_id,
                        Item.category_id == category_id
                    ).update({"category_name": update_dict["name"]})
                )
            
            logging.info(f"Updated category {category_id} for business {business_id}")
            return category
            
        except Exception as e:
            logging.error(f"Error updating category: {e}")
            raise
    
    @staticmethod
    async def delete_category(business_id: int, category_id: int, session: AsyncSession) -> bool:
        """Delete a category and move items to uncategorized."""
        try:
            result = await session.execute(
                select(ItemCategory).where(
                    ItemCategory.business_id == business_id,
                    ItemCategory.id == category_id
                )
            )
            category = result.scalars().first()
            
            if not category:
                return False
            
            # Move items to uncategorized
            await session.execute(
                select(Item).where(
                    Item.business_id == business_id,
                    Item.category_id == category_id
                ).update({
                    "category_id": None,
                    "category_name": None,
                    "updated_at": datetime.utcnow()
                })
            )
            
            await session.delete(category)
            await session.commit()
            logging.info(f"Deleted category {category_id} for business {business_id}")
            return True
            
        except Exception as e:
            logging.error(f"Error deleting category: {e}")
            raise
    
    @staticmethod
    async def _update_category_counts(business_id: int, category_id: int, session: AsyncSession):
        """Update item counts for a category."""
        try:
            category = await session.get(ItemCategory, category_id)
            if not category:
                return
            
            # Count total items in category
            total_items = (await session.execute(
                select(Item).where(
                    Item.business_id == business_id,
                    Item.category_id == category_id
                )
            )).scalars().count()
            
            # Count active items in category
            active_items = (await session.execute(
                select(Item).where(
                    Item.business_id == business_id,
                    Item.category_id == category_id,
                    Item.is_available == True,
                    Item.status == ItemStatus.ACTIVE
                )
            )).scalars().count()
            
            category.update_item_counts(total_items, active_items)
            session.add(category)
            await session.commit()
            
        except Exception as e:
            logging.error(f"Error updating category counts: {e}")
    
    @staticmethod
    async def get_low_stock_items(business_id: int, session: AsyncSession) -> List[Item]:
        """Get items that are low on stock."""
        try:
            result = await session.execute(
                select(Item).where(
                    Item.business_id == business_id,
                    Item.track_inventory == True,
                    Item.low_stock_threshold != None,
                    Item.stock_quantity != None
                )
            )
            items = result.scalars().all()
            
            # Filter for low stock items
            low_stock_items = [item for item in items if item.is_low_stock()]
            return low_stock_items
            
        except Exception as e:
            logging.error(f"Error getting low stock items: {e}")
            raise
    
    @staticmethod
    async def get_item_analytics(
        business_id: int, 
        days: int = 30,
        session: AsyncSession
    ) -> Dict[str, Any]:
        """Get item analytics for a business."""
        try:
            # Get all items for the business
            items = (await session.execute(
                select(Item).where(Item.business_id == business_id)
            )).scalars().all()
            
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
                "low_stock_items": len(await ItemService.get_low_stock_items(business_id, session))
            }
            
        except Exception as e:
            logging.error(f"Error getting item analytics: {e}")
            raise

    @staticmethod
    async def get_item_by_id(item_id: int, session: AsyncSession) -> Optional[Item]:
        """Get a specific item by ID for internal service use."""
        try:
            return await session.get(Item, item_id)
        except Exception as e:
            logging.error(f"Error getting item by id {item_id}: {e}")
            return None

    @staticmethod
    async def update_item_image(item_id: int, image_url: str, session: AsyncSession) -> Optional[Item]:
        """Update the image URL for an item."""
        try:
            item = await session.get(Item, item_id)
            if not item:
                return None
            
            item.image_url = image_url
            item.updated_at = datetime.utcnow()
            session.add(item)
            await session.commit()
            
            logging.info(f"Updated image URL for item {item_id}")
            return item
        except Exception as e:
            logging.error(f"Error updating item image for {item_id}: {e}")
            raise

item_service = ItemService()
