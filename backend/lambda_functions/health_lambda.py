"""
Pure AWS Lambda handlers for health check endpoints.
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

def root(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Pure Lambda handler for root endpoint.
    """
    try:
        if powertools_available:
            logger.info("Root endpoint accessed")
            metrics.add_metric(name="RootEndpointAccess", unit=MetricUnit.Count, value=1)
        
        return lambda_response(200, {
            'message': 'Order Receiver API - Pure Serverless',
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'version': '2.0.0-lambda',
            'architecture': 'API Gateway + Lambda',
            'environment': os.environ.get('ENVIRONMENT', 'production'),
            'function_name': context.function_name if context else 'unknown'
        })
    except Exception as e:
        if powertools_available:
            logger.exception("Error in root endpoint")
        else:
            logger.exception(f"Error in root endpoint: {str(e)}")
            
        return lambda_response(500, {
            'message': 'Internal server error',
            'status': 'error',
            'timestamp': datetime.utcnow().isoformat()
        })

def health(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Pure Lambda handler for basic health check.
    """
    try:
        if powertools_available:
            logger.info("Health check accessed")
            metrics.add_metric(name="HealthCheckAccess", unit=MetricUnit.Count, value=1)
        
        return lambda_response(200, {
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'service': 'Order Receiver API',
            'database': 'DynamoDB (serverless)',
            'architecture': 'Lambda + API Gateway',
            'function_name': context.function_name if context else 'unknown',
            'request_id': context.aws_request_id if context else 'unknown',
            'environment': os.environ.get('ENVIRONMENT', 'production')
        })
    except Exception as e:
        if powertools_available:
            logger.exception("Error in health check")
        else:
            logger.exception(f"Error in health check: {str(e)}")
            
        return lambda_response(500, {
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        })

def health_detailed(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Pure Lambda handler for detailed health check.
    """
    try:
        if powertools_available:
            logger.info("Detailed health check accessed")
            metrics.add_metric(name="DetailedHealthCheckAccess", unit=MetricUnit.Count, value=1)
        
        environment = os.environ.get('ENVIRONMENT', 'production')
        aws_region = os.environ.get('AWS_REGION', 'us-east-1')
        table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'order-receiver-businesses')
        
        # Basic DynamoDB connectivity check
        database_status = 'connected'
        try:
            import boto3
            dynamodb = boto3.resource('dynamodb', region_name=aws_region)
            table = dynamodb.Table(table_name)
            # Just check if table exists - don't actually read data
            table.load()
        except Exception as db_error:
            database_status = f'error: {str(db_error)}'
        
        return lambda_response(200, {
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'service': 'Order Receiver API',
            'version': '2.0.0-lambda',
            'architecture': 'Pure Serverless (Lambda + API Gateway)',
            'database': {
                'type': 'DynamoDB',
                'status': database_status,
                'table': table_name,
                'region': aws_region
            },
            'lambda': {
                'function_name': context.function_name if context else 'unknown',
                'request_id': context.aws_request_id if context else 'unknown',
                'memory_limit': context.memory_limit_in_mb if context else 'unknown',
                'remaining_time': context.get_remaining_time_in_millis() if context else 'unknown'
            },
            'environment': environment,
            'aws_region': aws_region
        })
    except Exception as e:
        if powertools_available:
            logger.exception("Error in detailed health check")
        else:
            logger.exception(f"Error in detailed health check: {str(e)}")
            
        return lambda_response(500, {
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        })

def options_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handle CORS preflight requests for health endpoints.
    """
    return lambda_response(200, {
        'message': 'CORS preflight response'
    }, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Max-Age': '86400'
    })

# Export functions for serverless framework
root_handler = root
health_handler = health
health_detailed_handler = health_detailed
cors_handler = options_handler
