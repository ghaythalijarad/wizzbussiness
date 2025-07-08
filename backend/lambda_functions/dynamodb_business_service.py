"""
DynamoDB-based business service for Lambda functions.
Replaces in-memory storage with DynamoDB for serverless deployment.
"""
import json
import logging
import os
import uuid
from datetime import datetime
from typing import Dict, Any, Optional

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)

class DynamoDBBusinessService:
    """Service for business data management using DynamoDB."""
    
    def __init__(self, table_name: str = None):
        """Initialize DynamoDB business service."""
        self.dynamodb = boto3.resource('dynamodb')
        self.table_name = table_name or os.environ.get('DYNAMODB_TABLE_NAME', 'order-receiver-businesses-dev')
        self.table = self.dynamodb.Table(self.table_name)
        logger.info(f"DynamoDBBusinessService initialized with table: {self.table_name}")
    
    async def create_business(self, business_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a new business record in DynamoDB.
        
        Args:
            business_data: Business information to store
            
        Returns:
            Dictionary with success status and business ID
        """
        try:
            # Generate unique business ID
            business_id = str(uuid.uuid4())
            
            # Prepare item for DynamoDB
            item = {
                'business_id': business_id,
                'cognito_user_id': business_data['cognito_user_id'],
                'email': business_data['email'],
                'business_name': business_data['business_name'],
                'business_type': business_data['business_type'],
                'owner_name': business_data['owner_name'],
                'phone_number': business_data['phone_number'],
                'address': business_data['address'],
                'created_at': business_data.get('created_at', datetime.utcnow().isoformat()),
                'updated_at': datetime.utcnow().isoformat(),
                'status': business_data.get('status', 'active')
            }
            
            # Check if business with this email already exists
            existing_business = await self.get_business_by_email(business_data['email'])
            if existing_business['success'] and existing_business['business']:
                return {
                    'success': False,
                    'error': 'A business with this email already exists'
                }
            
            # Store in DynamoDB
            self.table.put_item(Item=item)
            
            logger.info(f"Business created successfully with ID: {business_id}")
            return {
                'success': True,
                'business_id': business_id,
                'message': 'Business created successfully'
            }
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            logger.error(f"DynamoDB error creating business: {error_code} - {error_message}")
            return {
                'success': False,
                'error': f'Database error: {error_message}'
            }
        except Exception as e:
            logger.error(f"Unexpected error creating business: {str(e)}")
            return {
                'success': False,
                'error': f'Failed to create business: {str(e)}'
            }
    
    async def get_business_by_id(self, business_id: str) -> Dict[str, Any]:
        """
        Get business by ID.
        
        Args:
            business_id: Business ID to lookup
            
        Returns:
            Dictionary with success status and business data
        """
        try:
            response = self.table.get_item(Key={'business_id': business_id})
            
            if 'Item' in response:
                return {
                    'success': True,
                    'business': response['Item']
                }
            else:
                return {
                    'success': False,
                    'error': 'Business not found'
                }
                
        except ClientError as e:
            error_message = e.response['Error']['Message']
            logger.error(f"DynamoDB error getting business: {error_message}")
            return {
                'success': False,
                'error': f'Database error: {error_message}'
            }
        except Exception as e:
            logger.error(f"Unexpected error getting business: {str(e)}")
            return {
                'success': False,
                'error': f'Failed to get business: {str(e)}'
            }
    
    async def get_business_by_email(self, email: str) -> Dict[str, Any]:
        """
        Get business by email using GSI.
        
        Args:
            email: Business email to lookup
            
        Returns:
            Dictionary with success status and business data
        """
        try:
            response = self.table.query(
                IndexName='email-index',
                KeyConditionExpression='email = :email',
                ExpressionAttributeValues={':email': email}
            )
            
            if response['Items']:
                return {
                    'success': True,
                    'business': response['Items'][0]  # Assuming email is unique
                }
            else:
                return {
                    'success': True,
                    'business': None
                }
                
        except ClientError as e:
            error_message = e.response['Error']['Message']
            logger.error(f"DynamoDB error querying business by email: {error_message}")
            return {
                'success': False,
                'error': f'Database error: {error_message}'
            }
        except Exception as e:
            logger.error(f"Unexpected error querying business by email: {str(e)}")
            return {
                'success': False,
                'error': f'Failed to query business: {str(e)}'
            }
    
    async def get_business_by_cognito_user_id(self, cognito_user_id: str) -> Dict[str, Any]:
        """
        Get business by Cognito user ID using GSI.
        
        Args:
            cognito_user_id: Cognito user ID to lookup
            
        Returns:
            Dictionary with success status and business data
        """
        try:
            response = self.table.query(
                IndexName='cognito-user-index',
                KeyConditionExpression='cognito_user_id = :user_id',
                ExpressionAttributeValues={':user_id': cognito_user_id}
            )
            
            if response['Items']:
                return {
                    'success': True,
                    'business': response['Items'][0]  # Assuming one business per user
                }
            else:
                return {
                    'success': True,
                    'business': None
                }
                
        except ClientError as e:
            error_message = e.response['Error']['Message']
            logger.error(f"DynamoDB error querying business by Cognito user ID: {error_message}")
            return {
                'success': False,
                'error': f'Database error: {error_message}'
            }
        except Exception as e:
            logger.error(f"Unexpected error querying business by Cognito user ID: {str(e)}")
            return {
                'success': False,
                'error': f'Failed to query business: {str(e)}'
            }
    
    async def update_business(self, business_id: str, updates: Dict[str, Any]) -> Dict[str, Any]:
        """
        Update business data.
        
        Args:
            business_id: Business ID to update
            updates: Dictionary of fields to update
            
        Returns:
            Dictionary with success status
        """
        try:
            # Add updated timestamp
            updates['updated_at'] = datetime.utcnow().isoformat()
            
            # Build update expression
            update_expression = "SET "
            expression_attribute_values = {}
            expression_attribute_names = {}
            
            for key, value in updates.items():
                if key not in ['business_id']:  # Don't update the key
                    attr_name = f"#{key}"
                    attr_value = f":{key}"
                    update_expression += f"{attr_name} = {attr_value}, "
                    expression_attribute_names[attr_name] = key
                    expression_attribute_values[attr_value] = value
            
            # Remove trailing comma and space
            update_expression = update_expression.rstrip(', ')
            
            # Update item
            response = self.table.update_item(
                Key={'business_id': business_id},
                UpdateExpression=update_expression,
                ExpressionAttributeNames=expression_attribute_names,
                ExpressionAttributeValues=expression_attribute_values,
                ReturnValues='UPDATED_NEW'
            )
            
            return {
                'success': True,
                'updated_attributes': response['Attributes'],
                'message': 'Business updated successfully'
            }
            
        except ClientError as e:
            error_message = e.response['Error']['Message']
            logger.error(f"DynamoDB error updating business: {error_message}")
            return {
                'success': False,
                'error': f'Database error: {error_message}'
            }
        except Exception as e:
            logger.error(f"Unexpected error updating business: {str(e)}")
            return {
                'success': False,
                'error': f'Failed to update business: {str(e)}'
            }
    
    async def list_businesses(self, limit: int = 50) -> Dict[str, Any]:
        """
        List all businesses (with pagination).
        
        Args:
            limit: Maximum number of businesses to return
            
        Returns:
            Dictionary with success status and businesses list
        """
        try:
            response = self.table.scan(Limit=limit)
            
            return {
                'success': True,
                'businesses': response['Items'],
                'count': len(response['Items']),
                'last_evaluated_key': response.get('LastEvaluatedKey')
            }
            
        except ClientError as e:
            error_message = e.response['Error']['Message']
            logger.error(f"DynamoDB error listing businesses: {error_message}")
            return {
                'success': False,
                'error': f'Database error: {error_message}'
            }
        except Exception as e:
            logger.error(f"Unexpected error listing businesses: {str(e)}")
            return {
                'success': False,
                'error': f'Failed to list businesses: {str(e)}'
            }

# Create a singleton instance for import
dynamodb_business_service = DynamoDBBusinessService()
