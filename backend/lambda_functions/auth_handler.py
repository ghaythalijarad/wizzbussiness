"""
AWS Lambda handler for authentication endpoints.
Pure serverless implementation using API Gateway + Lambda.
"""
import json
import os
from datetime import datetime
from typing import Dict, Any

# AWS Lambda Powertools for better observability
from aws_lambda_powertools import Logger, Tracer, Metrics
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools.metrics import MetricUnit

# Import DynamoDB business service for serverless deployment
from dynamodb_business_service import dynamodb_business_service

# Initialize AWS Lambda Powertools
logger = Logger()
tracer = Tracer()
metrics = Metrics()

# Use DynamoDB business service
business_service = dynamodb_business_service

def lambda_response(status_code: int, body: Dict[str, Any], headers: Dict[str, str] = None) -> Dict[str, Any]:
    """Helper function to create Lambda response."""
    if headers is None:
        headers = {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        }
    
    return {
        'statusCode': status_code,
        'headers': headers,
        'body': json.dumps(body)
    }

def validate_business_registration_data(data: Dict[str, Any]) -> Dict[str, Any]:
    """Validate business registration data."""
    required_fields = [
        'cognito_user_id', 'email', 'business_name', 'business_type',
        'owner_name', 'phone_number', 'address'
    ]
    
    errors = []
    
    for field in required_fields:
        if field not in data or not data[field]:
            errors.append(f"Missing required field: {field}")
    
    # Email validation
    if 'email' in data:
        email = data['email']
        if '@' not in email or '.' not in email.split('@')[-1]:
            errors.append("Invalid email format")
    
    # Address validation
    if 'address' in data and isinstance(data['address'], dict):
        address_required = ['street', 'city', 'zipcode']
        for addr_field in address_required:
            if addr_field not in data['address'] or not data['address'][addr_field]:
                errors.append(f"Missing address field: {addr_field}")
    elif 'address' in data:
        errors.append("Address must be an object with street, city, and zipcode")
    
    return {'valid': len(errors) == 0, 'errors': errors}

async def register_business_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for business registration.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        Lambda response
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        logger.info(f"Processing business registration for user: {body.get('cognito_user_id')}")
        
        # Validate input data
        validation_result = validate_business_registration_data(body)
        if not validation_result['valid']:
            return lambda_response(400, {
                'success': False,
                'message': 'Validation failed',
                'errors': validation_result['errors']
            })
        
        # Prepare business data for storage
        business_data = {
            'cognito_user_id': body['cognito_user_id'],
            'email': body['email'],
            'business_name': body['business_name'],
            'business_type': body['business_type'],
            'owner_name': body['owner_name'],
            'phone_number': body['phone_number'],
            'address': body['address'],
            'created_at': datetime.utcnow().isoformat(),
            'status': 'active'
        }
        
        # Store business data
        result = await business_service.create_business(business_data)
        
        if result['success']:
            logger.info(f"Business registered successfully: {result['business_id']}")
            return lambda_response(200, {
                'success': True,
                'message': 'Business registered successfully',
                'business_id': result['business_id']
            })
        else:
            logger.error(f"Failed to register business: {result['error']}")
            return lambda_response(400, {
                'success': False,
                'message': result['error']
            })
            
    except json.JSONDecodeError:
        return lambda_response(400, {
            'success': False,
            'message': 'Invalid JSON in request body'
        })
    except Exception as e:
        logger.error(f"Error registering business: {str(e)}")
        return lambda_response(500, {
            'success': False,
            'message': f'Internal server error: {str(e)}'
        })

def auth_health_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for auth service health check.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        Lambda response
    """
    return lambda_response(200, {
        'status': 'healthy',
        'service': 'auth',
        'timestamp': datetime.utcnow().isoformat(),
        'function_name': context.function_name if context else 'unknown',
        'request_id': context.aws_request_id if context else 'unknown'
    })

# For backwards compatibility with async event loops
def register_business(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Sync wrapper for register_business_handler."""
    import asyncio
    
    # Create event loop if it doesn't exist
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
    
    return loop.run_until_complete(register_business_handler(event, context))

def auth_health(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Sync wrapper for auth_health_handler."""
    return auth_health_handler(event, context)
