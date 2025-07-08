"""
Pure AWS Lambda handlers for authentication endpoints.
No FastAPI dependencies - pure serverless API Gateway + Lambda.
"""
import json
import os
from datetime import datetime
from typing import Dict, Any

# AWS Lambda Powertools for production-ready observability
try:
    from aws_lambda_powertools import Logger, Tracer, Metrics
    from aws_lambda_powertools.logging import correlation_paths
    from aws_lambda_powertools.metrics import MetricUnit
    
    # Initialize AWS Lambda Powertools
    logger = Logger()
    tracer = Tracer()
    metrics = Metrics()
    powertools_available = True
except ImportError:
    # Fallback to standard logging if powertools not available
    import logging
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    powertools_available = False

# Import DynamoDB business service
try:
    # Try importing as if we're in the lambda_functions directory
    from dynamodb_business_service import DynamoDBBusinessService
except ImportError:
    try:
        # Try importing with full path from Lambda root
        from lambda_functions.dynamodb_business_service import DynamoDBBusinessService
    except ImportError:
        # Try relative import
        from .dynamodb_business_service import DynamoDBBusinessService

# Initialize DynamoDB business service
table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'order-receiver-businesses-dev')
business_service = DynamoDBBusinessService(table_name)

def lambda_response(status_code: int, body: Dict[str, Any], headers: Dict[str, str] = None) -> Dict[str, Any]:
    """Helper function to create standardized Lambda response for API Gateway."""
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
        'body': json.dumps(body, default=str)  # Handle datetime serialization
    }

def validate_business_registration_data(data: Dict[str, Any]) -> Dict[str, Any]:
    """Validate business registration data without Pydantic."""
    required_fields = [
        'cognito_user_id', 'email', 'business_name', 'business_type',
        'owner_name', 'phone_number', 'address'
    ]
    
    errors = []
    
    # Check required fields
    for field in required_fields:
        if field not in data or not data[field]:
            errors.append(f"Missing required field: {field}")
    
    # Email validation (basic)
    if 'email' in data:
        email = data['email']
        if not email or '@' not in email or '.' not in email.split('@')[-1]:
            errors.append("Invalid email format")
    
    # Address validation
    if 'address' in data:
        if isinstance(data['address'], dict):
            address_required = ['street', 'city', 'zipcode']
            for addr_field in address_required:
                if addr_field not in data['address'] or not data['address'][addr_field]:
                    errors.append(f"Missing address field: {addr_field}")
        else:
            errors.append("Address must be an object with street, city, and zipcode")
    
    # Business type validation
    valid_business_types = ['restaurant', 'cafe', 'bakery', 'food_truck', 'catering', 'retail', 'other']
    if 'business_type' in data and data['business_type'] not in valid_business_types:
        errors.append(f"Invalid business type. Must be one of: {', '.join(valid_business_types)}")
    
    return {'valid': len(errors) == 0, 'errors': errors}

def register_business(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Pure Lambda handler for business registration.
    API Gateway integration - no FastAPI dependencies.
    """
    # Decorator approach if powertools available
    if powertools_available:
        @tracer.capture_lambda_handler
        @logger.inject_lambda_context(correlation_id_path=correlation_paths.API_GATEWAY_REST)
        @metrics.log_metrics
        def _register_business_with_powertools():
            return _register_business_core(event, context)
        return _register_business_with_powertools()
    else:
        return _register_business_core(event, context)

def _register_business_core(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Core business registration logic."""
    try:
        # Add custom metrics if available
        if powertools_available:
            metrics.add_metric(name="BusinessRegistrationAttempt", unit=MetricUnit.Count, value=1)
        
        # Parse request body
        body_str = event.get('body', '{}')
        if not body_str:
            body_str = '{}'
            
        body = json.loads(body_str)
        
        if powertools_available:
            logger.info("Processing business registration", extra={"cognito_user_id": body.get('cognito_user_id')})
        else:
            logger.info(f"Processing business registration for user: {body.get('cognito_user_id')}")
        
        # Validate input data
        validation_result = validate_business_registration_data(body)
        if not validation_result['valid']:
            if powertools_available:
                metrics.add_metric(name="BusinessRegistrationValidationError", unit=MetricUnit.Count, value=1)
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
        
        # Store business data (handle async in sync context)
        import asyncio
        try:
            loop = asyncio.get_event_loop()
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
        
        result = loop.run_until_complete(business_service.create_business(business_data))
        
        if result['success']:
            if powertools_available:
                metrics.add_metric(name="BusinessRegistrationSuccess", unit=MetricUnit.Count, value=1)
                logger.info("Business registered successfully", extra={"business_id": result['business_id']})
            else:
                logger.info(f"Business registered successfully: {result['business_id']}")
                
            return lambda_response(200, {
                'success': True,
                'message': 'Business registered successfully',
                'business_id': result['business_id']
            })
        else:
            if powertools_available:
                metrics.add_metric(name="BusinessRegistrationError", unit=MetricUnit.Count, value=1)
                logger.error("Failed to register business", extra={"error": result['error']})
            else:
                logger.error(f"Failed to register business: {result['error']}")
                
            return lambda_response(400, {
                'success': False,
                'message': result['error']
            })
            
    except json.JSONDecodeError:
        if powertools_available:
            metrics.add_metric(name="BusinessRegistrationJSONError", unit=MetricUnit.Count, value=1)
        return lambda_response(400, {
            'success': False,
            'message': 'Invalid JSON in request body'
        })
    except Exception as e:
        if powertools_available:
            metrics.add_metric(name="BusinessRegistrationSystemError", unit=MetricUnit.Count, value=1)
            logger.exception("Unexpected error in business registration")
        else:
            logger.exception(f"Unexpected error in business registration: {str(e)}")
            
        return lambda_response(500, {
            'success': False,
            'message': 'Internal server error'
        })

def auth_health(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Pure Lambda handler for auth service health check.
    """
    try:
        if powertools_available:
            logger.info("Auth health check requested")
        
        return lambda_response(200, {
            'status': 'healthy',
            'service': 'auth-lambda',
            'timestamp': datetime.utcnow().isoformat(),
            'function_name': context.function_name if context else 'unknown',
            'request_id': context.aws_request_id if context else 'unknown',
            'environment': os.environ.get('ENVIRONMENT', 'unknown'),
            'version': '2.0.0-lambda'
        })
    except Exception as e:
        if powertools_available:
            logger.exception("Error in auth health check")
        else:
            logger.exception(f"Error in auth health check: {str(e)}")
            
        return lambda_response(500, {
            'status': 'unhealthy',
            'service': 'auth-lambda',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        })

def options_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handle CORS preflight requests.
    """
    return lambda_response(200, {
        'message': 'CORS preflight response'
    }, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Max-Age': '86400'
    })

# Export functions for serverless framework
register_business_handler = register_business
auth_health_handler = auth_health
cors_handler = options_handler
