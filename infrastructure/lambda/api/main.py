"""
Simple Lambda handler for Order Receiver API without FastAPI.
Uses native AWS Lambda + API Gateway integration with DynamoDB.
"""
import json
import os
import logging
from typing import Dict, Any, Optional
import boto3
from botocore.exceptions import ClientError
from datetime import datetime
import uuid
from dao import NotificationDAO, DriverAssignmentDAO

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'order-receiver-data')
table = dynamodb.Table(table_name)

# CORS headers
CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'
}

def create_response(status_code: int, body: Dict[str, Any], headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
    """Create a properly formatted API Gateway response."""
    response_headers = CORS_HEADERS.copy()
    if headers:
        response_headers.update(headers)
    
    return {
        'statusCode': status_code,
        'headers': response_headers,
        'body': json.dumps(body, default=str)
    }

def generate_id() -> str:
    """Generate a unique ID."""
    return str(uuid.uuid4())

def get_timestamp() -> str:
    """Get current timestamp in ISO format."""
    return datetime.utcnow().isoformat()

# User operations
def create_user(user_data: Dict[str, Any]) -> Dict[str, Any]:
    """Create a new user in DynamoDB."""
    user_id = generate_id()
    timestamp = get_timestamp()
    
    # Check if user already exists
    try:
        response = table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1_PK = :email',
            ExpressionAttributeValues={':email': user_data['email']}
        )
        if response.get('Items'):
            raise ValueError("User with this email already exists")
    except ClientError as e:
        logger.error(f"Error checking existing user: {e}")
        raise
    
    item = {
        'PK': f'USER#{user_id}',
        'SK': 'PROFILE',
        'GSI1_PK': user_data['email'],
        'GSI1_SK': f'USER#{user_id}',
        'user_id': user_id,
        'email': user_data['email'],
        'phone': user_data.get('phone'),
        'business_name': user_data.get('business_name'),
        'first_name': user_data.get('first_name'),
        'last_name': user_data.get('last_name'),
        'created_at': timestamp,
        'updated_at': timestamp,
        'entity_type': 'USER'
    }
    
    try:
        table.put_item(Item=item)
        return item
    except ClientError as e:
        logger.error(f"Error creating user: {e}")
        raise

def get_user_by_id(user_id: str) -> Optional[Dict[str, Any]]:
    """Get user by ID from DynamoDB."""
    try:
        response = table.get_item(
            Key={
                'PK': f'USER#{user_id}',
                'SK': 'PROFILE'
            }
        )
        return response.get('Item')
    except ClientError as e:
        logger.error(f"Error getting user: {e}")
        raise

def get_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    """Get user by email using GSI1."""
    try:
        response = table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1_PK = :email',
            ExpressionAttributeValues={':email': email}
        )
        items = response.get('Items', [])
        return items[0] if items else None
    except ClientError as e:
        logger.error(f"Error getting user by email: {e}")
        raise

# Business operations
def create_business(business_data: Dict[str, Any]) -> Dict[str, Any]:
    """Create a new business in DynamoDB."""
    business_id = generate_id()
    timestamp = get_timestamp()
    
    item = {
        'PK': f'BUS#{business_id}',
        'SK': 'PROFILE',
        'business_id': business_id,
        'user_id': business_data['user_id'],
        'name': business_data['name'],
        'type': business_data.get('type', 'restaurant'),
        'status': business_data.get('status', 'pending'),
        'contact_phone': business_data.get('contact_phone'),
        'contact_email': business_data.get('contact_email'),
        'address': business_data.get('address', {}),
        'settings': business_data.get('settings', {}),
        'created_at': timestamp,
        'updated_at': timestamp,
        'entity_type': 'BUSINESS'
    }
    
    try:
        table.put_item(Item=item)
        return item
    except ClientError as e:
        logger.error(f"Error creating business: {e}")
        raise

def get_business_by_id(business_id: str) -> Optional[Dict[str, Any]]:
    """Get business by ID from DynamoDB."""
    try:
        response = table.get_item(
            Key={
                'PK': f'BUS#{business_id}',
                'SK': 'PROFILE'
            }
        )
        return response.get('Item')
    except ClientError as e:
        logger.error(f"Error getting business: {e}")
        raise

# Order operations
def create_order(order_data: Dict[str, Any]) -> Dict[str, Any]:
    """Create a new order in DynamoDB."""
    order_id = generate_id()
    timestamp = get_timestamp()
    
    # Main order record
    order_item = {
        'PK': f'ORD#{order_id}',
        'SK': 'DETAILS',
        'order_id': order_id,
        'business_id': order_data['business_id'],
        'customer_name': order_data['customer_name'],
        'customer_phone': order_data.get('customer_phone'),
        'customer_email': order_data.get('customer_email'),
        'items': order_data['items'],
        'total_amount': order_data['total_amount'],
        'status': order_data.get('status', 'pending'),
        'delivery_address': order_data.get('delivery_address', {}),
        'notes': order_data.get('notes'),
        'created_at': timestamp,
        'updated_at': timestamp,
        'entity_type': 'ORDER'
    }
    
    # Business-order lookup record for GSI2
    business_order_item = {
        'PK': f'BUS#{order_data["business_id"]}',
        'SK': f'ORD#{order_id}',
        'GSI2_PK': f'BUS#{order_data["business_id"]}',
        'GSI2_SK': f'STATUS#{order_data.get("status", "pending")}#CREATED#{timestamp}',
        'order_id': order_id,
        'customer_name': order_data['customer_name'],
        'total_amount': order_data['total_amount'],
        'status': order_data.get('status', 'pending'),
        'created_at': timestamp,
        'entity_type': 'ORDER_BUSINESS'
    }
    
    try:
        # Use batch write for consistency
        with table.batch_writer() as batch:
            batch.put_item(Item=order_item)
            batch.put_item(Item=business_order_item)
        
        return order_item
    except ClientError as e:
        logger.error(f"Error creating order: {e}")
        raise

def get_order_by_id(order_id: str) -> Optional[Dict[str, Any]]:
    """Get order by ID from DynamoDB."""
    try:
        response = table.get_item(
            Key={
                'PK': f'ORD#{order_id}',
                'SK': 'DETAILS'
            }
        )
        return response.get('Item')
    except ClientError as e:
        logger.error(f"Error getting order: {e}")
        raise

# Notification operations
class NotificationDAO:
    """Data access object for notifications."""
    
    def __init__(self):
        self.table = table
    
    def list_notifications(self, target: str) -> list:
        """List notifications for a target (e.g., user or business)."""
        try:
            response = self.table.query(
                IndexName='GSI1',
                KeyConditionExpression='GSI1_PK = :target',
                ExpressionAttributeValues={':target': target}
            )
            return response.get('Items', [])
        except ClientError as e:
            logger.error(f"Error listing notifications: {e}")
            raise
    
    def create_notification(self, target: str, message: str, metadata: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Create a new notification."""
        notification_id = generate_id()
        timestamp = get_timestamp()
        
        notification_item = {
            'PK': f'NOTIF#{notification_id}',
            'SK': 'DETAILS',
            'GSI1_PK': target,
            'GSI1_SK': f'NOTIF#{notification_id}',
            'notification_id': notification_id,
            'target': target,
            'message': message,
            'metadata': metadata or {},
            'status': 'unread',
            'created_at': timestamp,
            'updated_at': timestamp,
            'entity_type': 'NOTIFICATION'
        }
        
        try:
            self.table.put_item(Item=notification_item)
            return notification_item
        except ClientError as e:
            logger.error(f"Error creating notification: {e}")
            raise

# Driver assignment operations
class DriverAssignmentDAO:
    """Data access object for driver assignments."""
    
    def __init__(self):
        self.table = table
    
    def assign_driver(self, order_id: str, driver_id: str) -> Dict[str, Any]:
        """Assign a driver to an order."""
        assignment_id = generate_id()
        timestamp = get_timestamp()
        
        assignment_item = {
            'PK': f'ORD#{order_id}',
            'SK': f'DRIVER#{driver_id}',
            'GSI1_PK': f'DRIVER#{driver_id}',
            'GSI1_SK': f'ORD#{order_id}',
            'assignment_id': assignment_id,
            'order_id': order_id,
            'driver_id': driver_id,
            'status': 'assigned',
            'created_at': timestamp,
            'updated_at': timestamp,
            'entity_type': 'DRIVER_ASSIGNMENT'
        }
        
        try:
            self.table.put_item(Item=assignment_item)
            return assignment_item
        except ClientError as e:
            logger.error(f"Error assigning driver: {e}")
            raise
    
    def get_assignments_for_driver(self, driver_id: str) -> list:
        """Get all assignments for a driver."""
        try:
            response = self.table.query(
                IndexName='GSI1',
                KeyConditionExpression='GSI1_PK = :driver_id',
                ExpressionAttributeValues={':driver_id': f'DRIVER#{driver_id}'}
            )
            return response.get('Items', [])
        except ClientError as e:
            logger.error(f"Error getting driver assignments: {e}")
            raise

def handle_health_check() -> Dict[str, Any]:
    """Handle health check endpoint."""
    try:
        # Test DynamoDB connection
        table.describe_table()
        return create_response(200, {
            'status': 'healthy',
            'timestamp': get_timestamp(),
            'service': 'order-receiver-api'
        })
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return create_response(503, {
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': get_timestamp()
        })

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for Order Receiver API.
    Handles API Gateway events without FastAPI.
    """
    try:
        # Log the incoming event for debugging
        logger.info(f"Received event: {json.dumps(event, default=str)}")
        
        # Handle CORS preflight requests
        if event.get('httpMethod') == 'OPTIONS':
            return create_response(200, {})
        
        # Extract request details
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '/')
        query_params = event.get('queryStringParameters') or {}
        headers = event.get('headers') or {}
        
        # Parse body if present
        body = {}
        if event.get('body'):
            try:
                body = json.loads(event['body'])
            except json.JSONDecodeError:
                return create_response(400, {'error': 'Invalid JSON in request body'})
        
        # Route handling
        if path == '/health' or path == '/':
            return handle_health_check()
        
        elif path == '/api/users' and http_method == 'POST':
            # Create user
            required_fields = ['email']
            if not all(field in body for field in required_fields):
                return create_response(400, {'error': 'Missing required fields: email'})
            
            user = create_user(body)
            return create_response(201, {'message': 'User created successfully', 'user': user})
        
        elif path.startswith('/api/users/') and http_method == 'GET':
            # Get user by ID
            user_id = path.split('/')[-1]
            user = get_user_by_id(user_id)
            if not user:
                return create_response(404, {'error': 'User not found'})
            return create_response(200, {'user': user})
        
        elif path == '/api/users' and http_method == 'GET':
            # Get user by email
            email = query_params.get('email')
            if not email:
                return create_response(400, {'error': 'Email parameter required'})
            
            user = get_user_by_email(email)
            if not user:
                return create_response(404, {'error': 'User not found'})
            return create_response(200, {'user': user})
        
        elif path == '/api/businesses' and http_method == 'POST':
            # Create business
            required_fields = ['name', 'user_id']
            if not all(field in body for field in required_fields):
                return create_response(400, {'error': 'Missing required fields: name, user_id'})
            
            # Verify user exists
            user = get_user_by_id(body['user_id'])
            if not user:
                return create_response(404, {'error': 'User not found'})
            
            business = create_business(body)
            return create_response(201, {'message': 'Business created successfully', 'business': business})
        
        elif path.startswith('/api/businesses/') and http_method == 'GET':
            # Get business by ID
            business_id = path.split('/')[-1]
            business = get_business_by_id(business_id)
            if not business:
                return create_response(404, {'error': 'Business not found'})
            return create_response(200, {'business': business})
        
        elif path == '/api/orders' and http_method == 'POST':
            # Create order
            required_fields = ['business_id', 'customer_name', 'items', 'total_amount']
            if not all(field in body for field in required_fields):
                return create_response(400, {'error': f'Missing required fields: {", ".join(required_fields)}'})
            
            # Verify business exists
            business = get_business_by_id(body['business_id'])
            if not business:
                return create_response(404, {'error': 'Business not found'})
            
            order = create_order(body)
            return create_response(201, {'message': 'Order created successfully', 'order': order})
        
        elif path.startswith('/api/orders/') and http_method == 'GET':
            # Get order by ID
            order_id = path.split('/')[-1]
            order = get_order_by_id(order_id)
            if not order:
                return create_response(404, {'error': 'Order not found'})
            return create_response(200, {'order': order})
        
        # Notification endpoints
        elif path.startswith('/notifications'):
            dao = NotificationDAO()
            if http_method == 'GET':
                target = event['queryStringParameters'].get('target')
                notifs = dao.list_notifications(target)
                return create_response(200, {'notifications': notifs})
            elif http_method == 'POST':
                data = json.loads(body)
                notif = dao.create_notification(data['target'], data['message'], data.get('metadata'))
                return create_response(201, notif)
        
        # Driver assignment endpoints
        elif path.startswith('/drivers/assign'):
            data = json.loads(body)
            dao = DriverAssignmentDAO()
            assignment = dao.assign_driver(data['order_id'], data['driver_id'])
            return create_response(201, assignment)
        elif path.startswith('/drivers/orders'):
            driver_id = event['queryStringParameters'].get('driver_id')
            dao = DriverAssignmentDAO()
            orders = dao.get_assignments_for_driver(driver_id)
            return create_response(200, {'assignments': orders})
        
        else:
            return create_response(404, {'error': 'Endpoint not found'})
    
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        return create_response(400, {'error': str(e)})
    
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return create_response(500, {'error': 'Internal server error'})
        
        # Use Mangum to handle the request
        response = handler(event, context)
        
        # Ensure CORS headers are present
        if "headers" not in response:
            response["headers"] = {}
        
        response["headers"].update({
            "Access-Control-Allow-Origin": cors_origins[0] if cors_origins else "*",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
        })
        
        return response
        
    except Exception as e:
        print(f"Lambda handler error: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": cors_origins[0] if cors_origins else "*",
            },
            "body": json.dumps({
                "error": "Internal server error",
                "message": str(e) if os.getenv("ENVIRONMENT") != "production" else "An error occurred"
            })
        }
