"""
Business service for managing business data storage.
"""
import logging
import uuid
from datetime import datetime
from typing import Dict, Any, Optional

class BusinessService:
    """Service for business data management."""
    
    def __init__(self):
        """Initialize business service."""
        self.businesses = {}  # In-memory storage for development
        logging.info("BusinessService initialized with in-memory storage")
    
    async def create_business(self, business_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a new business record.
        
        Args:
            business_data: Business information to store
            
        Returns:
            Dictionary with success status and business ID
        """
        try:
            # Generate unique business ID
            business_id = str(uuid.uuid4())
            
            # Add metadata
            business_data['business_id'] = business_id
            business_data['created_at'] = datetime.utcnow().isoformat()
            business_data['updated_at'] = datetime.utcnow().isoformat()
            
            # Store in memory (in production, this would be DynamoDB)
            self.businesses[business_id] = business_data
            
            logging.info(f"Business created successfully: {business_id}")
            logging.info(f"Business data: {business_data}")
            
            return {
                'success': True,
                'business_id': business_id,
                'message': 'Business created successfully'
            }
            
        except Exception as e:
            logging.error(f"Error creating business: {str(e)}")
            return {
                'success': False,
                'error': f"Failed to create business: {str(e)}"
            }
    
    async def get_business(self, business_id: str) -> Dict[str, Any]:
        """
        Get business by ID.
        
        Args:
            business_id: Business identifier
            
        Returns:
            Business data or error
        """
        try:
            if business_id in self.businesses:
                return {
                    'success': True,
                    'business': self.businesses[business_id]
                }
            else:
                return {
                    'success': False,
                    'error': 'Business not found'
                }
                
        except Exception as e:
            logging.error(f"Error getting business: {str(e)}")
            return {
                'success': False,
                'error': f"Failed to get business: {str(e)}"
            }
    
    async def get_business_by_cognito_user(self, cognito_user_id: str) -> Dict[str, Any]:
        """
        Get business by Cognito user ID.
        
        Args:
            cognito_user_id: Cognito user identifier
            
        Returns:
            Business data or error
        """
        try:
            for business_id, business_data in self.businesses.items():
                if business_data.get('cognito_user_id') == cognito_user_id:
                    return {
                        'success': True,
                        'business': business_data
                    }
            
            return {
                'success': False,
                'error': 'Business not found for user'
            }
            
        except Exception as e:
            logging.error(f"Error getting business by user: {str(e)}")
            return {
                'success': False,
                'error': f"Failed to get business: {str(e)}"
            }
    
    async def list_businesses(self) -> Dict[str, Any]:
        """
        List all businesses (for debugging).
        
        Returns:
            List of all businesses
        """
        try:
            return {
                'success': True,
                'businesses': list(self.businesses.values()),
                'count': len(self.businesses)
            }
            
        except Exception as e:
            logging.error(f"Error listing businesses: {str(e)}")
            return {
                'success': False,
                'error': f"Failed to list businesses: {str(e)}"
            }
