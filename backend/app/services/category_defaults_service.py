"""
Category defaults service for auto-creating business-specific categories.
"""
from typing import Dict, List
from beanie import PydanticObjectId
import logging

from ..models.business import BusinessType
from ..models.item import ItemCategory
from ..schemas.item import ItemCategoryCreateSchema


class CategoryDefaultsService:
    """Service for creating default categories based on business type."""
    
    # Default categories for each business type
    DEFAULT_CATEGORIES = {
        BusinessType.RESTAURANT: [
            {
                "name": "Appetizers",
                "description": "Starters and small plates to begin your meal",
                "display_order": 1,
                "color": "#FF6B6B",
                "icon": "🥗"
            },
            {
                "name": "Main Courses",
                "description": "Hearty main dishes and entrees",
                "display_order": 2,
                "color": "#4ECDC4",
                "icon": "🍽️"
            },
            {
                "name": "Beverages",
                "description": "Refreshing drinks and beverages",
                "display_order": 3,
                "color": "#45B7D1",
                "icon": "🥤"
            },
            {
                "name": "Desserts",
                "description": "Sweet treats and desserts",
                "display_order": 4,
                "color": "#F7B731",
                "icon": "🍰"
            }
        ],
        
        BusinessType.STORE: [
            {
                "name": "Electronics",
                "description": "Electronic devices and accessories",
                "display_order": 1,
                "color": "#2F3542",
                "icon": "📱"
            },
            {
                "name": "Clothing",
                "description": "Fashion and apparel for all ages",
                "display_order": 2,
                "color": "#FF6B6B",
                "icon": "👕"
            },
            {
                "name": "Home & Garden",
                "description": "Home improvement and garden supplies",
                "display_order": 3,
                "color": "#26de81",
                "icon": "🏠"
            },
            {
                "name": "Groceries",
                "description": "Food items and daily necessities",
                "display_order": 4,
                "color": "#FFA502",
                "icon": "🛒"
            }
        ],
        
        BusinessType.PHARMACY: [
            {
                "name": "Prescription Drugs",
                "description": "Prescription medications and controlled substances",
                "display_order": 1,
                "color": "#E74C3C",
                "icon": "💊"
            },
            {
                "name": "Over-the-Counter",
                "description": "Non-prescription medications and supplements",
                "display_order": 2,
                "color": "#3498DB",
                "icon": "🧴"
            },
            {
                "name": "Health & Beauty",
                "description": "Personal care and beauty products",
                "display_order": 3,
                "color": "#E91E63",
                "icon": "💄"
            },
            {
                "name": "Medical Equipment",
                "description": "Medical devices and health monitoring equipment",
                "display_order": 4,
                "color": "#607D8B",
                "icon": "🩺"
            }
        ],
        
        BusinessType.KITCHEN: [
            {
                "name": "Prepared Meals",
                "description": "Ready-to-eat complete meals",
                "display_order": 1,
                "color": "#FF5722",
                "icon": "🍱"
            },
            {
                "name": "Ingredients",
                "description": "Fresh ingredients for cooking",
                "display_order": 2,
                "color": "#4CAF50",
                "icon": "🥕"
            },
            {
                "name": "Beverages",
                "description": "Drinks and refreshments",
                "display_order": 3,
                "color": "#2196F3",
                "icon": "🥤"
            },
            {
                "name": "Snacks",
                "description": "Quick bites and snack foods",
                "display_order": 4,
                "color": "#FF9800",
                "icon": "🍿"
            }
        ]
    }
    
    @classmethod
    async def create_default_categories(cls, business_id: PydanticObjectId, business_type: BusinessType) -> List[ItemCategory]:
        """Create default categories for a business based on its type."""
        try:
            categories_data = cls.DEFAULT_CATEGORIES.get(business_type, [])
            
            if not categories_data:
                logging.warning(f"No default categories defined for business type: {business_type}")
                return []
            
            created_categories = []
            
            for category_data in categories_data:
                try:
                    # Create category
                    category = ItemCategory(
                        business_id=business_id,
                        **category_data
                    )
                    
                    await category.insert()
                    created_categories.append(category)
                    
                    logging.info(f"Created default category '{category.name}' for business {business_id}")
                    
                except Exception as e:
                    logging.error(f"Error creating category '{category_data.get('name', 'Unknown')}': {e}")
                    # Continue with other categories even if one fails
                    continue
            
            logging.info(f"Successfully created {len(created_categories)} default categories for {business_type} business {business_id}")
            return created_categories
            
        except Exception as e:
            logging.error(f"Error creating default categories for business {business_id}: {e}")
            raise
    
    @classmethod
    def get_default_categories_preview(cls, business_type: BusinessType) -> List[Dict]:
        """Get a preview of default categories for a business type without creating them."""
        return cls.DEFAULT_CATEGORIES.get(business_type, [])
    
    @classmethod
    def get_supported_business_types(cls) -> List[BusinessType]:
        """Get list of business types that have default categories."""
        return list(cls.DEFAULT_CATEGORIES.keys())


# Create global instance
category_defaults_service = CategoryDefaultsService()
