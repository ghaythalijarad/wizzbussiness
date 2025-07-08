"""
AWS Lambda handler for health check endpoints.
Replaces FastAPI health_controller.py with pure Lambda functions.
"""
import json
import os
from datetime import datetime
from typing import Dict, Any

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

def root_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for root endpoint.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        Lambda response
    """
    return lambda_response(200, {
        'message': 'Order Receiver API - Serverless',
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '2.0.0',
        'environment': os.environ.get('ENVIRONMENT', 'production')
    })

def health_check_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for basic health check.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        Lambda response
    """
    return lambda_response(200, {
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'Order Receiver API',
        'database': 'DynamoDB (serverless)',
        'function_name': context.function_name if context else 'unknown',
        'request_id': context.aws_request_id if context else 'unknown'
    })

def detailed_health_check_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for detailed health check.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        Lambda response
    """
    environment = os.environ.get('ENVIRONMENT', 'production')
    aws_region = os.environ.get('AWS_REGION', 'us-east-1')
    table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'order-receiver-businesses')
    
    return lambda_response(200, {
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'Order Receiver API',
        'version': '2.0.0',
        'database': {
            'type': 'DynamoDB',
            'status': 'serverless',
            'table': table_name,
            'region': aws_region
        },
        'environment': environment,
        'lambda': {
            'function_name': context.function_name if context else 'unknown',
            'request_id': context.aws_request_id if context else 'unknown',
            'memory_limit': context.memory_limit_in_mb if context else 'unknown',
            'remaining_time': context.get_remaining_time_in_millis() if context else 'unknown'
        }
    })

# Export handlers with simple names for SAM/Serverless Framework
def root(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Root endpoint handler."""
    return root_handler(event, context)

def health(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Health check handler."""
    return health_check_handler(event, context)

def health_detailed(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Detailed health check handler."""
    return detailed_health_check_handler(event, context)
