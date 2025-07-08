"""
Authentication Lambda function for Order Receiver.
Handles user authentication and JWT token management.
"""
import json
import os
import sys
from typing import Any, Dict
import boto3
from boto3.dynamodb.conditions import Key
import uuid
from datetime import datetime

# Add path for imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Initialize DynamoDB table
_dynamodb = boto3.resource('dynamodb')
_table = _dynamodb.Table(os.environ.get('DYNAMODB_TABLE_NAME'))

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for authentication requests.
    
    Args:
        event: Lambda event from API Gateway
        context: Lambda context
        
    Returns:
        API Gateway response
    """
    try:
        # Extract request details
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '/auth')
        body = event.get('body', '{}')
        headers = event.get('headers', {})
        
        # Parse request body
        try:
            request_data = json.loads(body) if body else {}
        except json.JSONDecodeError:
            request_data = {}
        
        # Route authentication requests
        if path.endswith('/login') and http_method == 'POST':
            return handle_login(request_data)
        elif path.endswith('/register') and http_method == 'POST':
            return handle_register(request_data)
        elif path.endswith('/register-business') and http_method == 'POST':
            return handle_business_registration(request_data)
        elif path.endswith('/verify') and http_method == 'GET':
            return handle_verify(headers)
        else:
            return {
                'statusCode': 404,
                'headers': get_cors_headers(),
                'body': json.dumps({'error': 'Not found'})
            }
            
    except Exception as e:
        print(f"Auth Lambda error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': get_cors_headers(),
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') != 'production' else 'Authentication error'
            })
        }

def handle_login(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle user login."""
    email = request_data.get('email', request_data.get('username'))
    password = request_data.get('password')
    
    if not email or not password:
        return {
            'statusCode': 400,
            'headers': get_cors_headers(),
            'body': json.dumps({'error': 'Email and password are required'})
        }
    
    # Query user by email from DynamoDB
    try:
        resp = _table.query(
            IndexName='GSI1',
            KeyConditionExpression=Key('GSI1_PK').eq(email)
        )
        items = resp.get('Items', [])
    except Exception as e:
        return {'statusCode': 500, 'headers': get_cors_headers(), 'body': json.dumps({'error': 'DB query error', 'message': str(e)})}
    if not items:
        return {'statusCode': 401, 'headers': get_cors_headers(), 'body': json.dumps({'error': 'Invalid email or password'})}
    user = items[0]
    if user.get('password') != password:
        return {'statusCode': 401, 'headers': get_cors_headers(), 'body': json.dumps({'error': 'Invalid email or password'})}
    # Generate JWT
    import jwt, datetime
    payload = {'user_id': user['user_id'], 'email': email, 'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24), 'iat': datetime.datetime.utcnow()}
    secret_key = os.getenv('SECRET_KEY', 'demo-secret-key')
    token = jwt.encode(payload, secret_key, algorithm='HS256')

    return {'statusCode': 200, 'headers': get_cors_headers(), 'body': json.dumps({'access_token': token, 'token_type': 'bearer', 'expires_in': 86400, 'user': {'id': user['user_id'], 'email': email, 'is_active': True}})}

def handle_register(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle user registration."""
    # Validate input
    email = request_data.get('email')
    password = request_data.get('password')
    if not email or not password:
        return {'statusCode': 400, 'headers': get_cors_headers(), 'body': json.dumps({'error': 'Email and password are required'})}
    # Check existing user
    try:
        resp = _table.query(IndexName='GSI1', KeyConditionExpression=Key('GSI1_PK').eq(email))
        if resp.get('Items'):
            return {'statusCode': 400, 'headers': get_cors_headers(), 'body': json.dumps({'error': 'User already exists'})}
    except Exception as e:
        return {'statusCode': 500, 'headers': get_cors_headers(), 'body': json.dumps({'error': 'DB query error', 'message': str(e)})}
    # Create user record
    user_id = str(uuid.uuid4())
    ts = datetime.utcnow().isoformat()
    item = {'PK': f'USER#{user_id}', 'SK': 'PROFILE', 'GSI1_PK': email, 'GSI1_SK': f'USER#{user_id}', 'user_id': user_id, 'email': email, 'password': password, 'created_at': ts, 'updated_at': ts, 'entity_type': 'USER'}
    try:
        _table.put_item(Item=item)
    except Exception as e:
        return {'statusCode': 500, 'headers': get_cors_headers(), 'body': json.dumps({'error': 'DB write error', 'message': str(e)})}
    return {'statusCode': 201, 'headers': get_cors_headers(), 'body': json.dumps({'id': user_id, 'email': email})}

def handle_business_registration(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle business registration after Cognito signup."""
    try:
        # Extract required data
        cognito_user_id = request_data.get('cognito_user_id')
        email = request_data.get('email')
        business_name = request_data.get('business_name')
        business_type = request_data.get('business_type', 'restaurant')
        owner_name = request_data.get('owner_name')
        phone_number = request_data.get('phone_number')
        address = request_data.get('address', {})
        
        # Validate required fields
        if not all([cognito_user_id, email, business_name, owner_name]):
            return {
                'statusCode': 400,
                'headers': get_cors_headers(),
                'body': json.dumps({'error': 'Missing required fields: cognito_user_id, email, business_name, owner_name'})
            }
        
        # Generate IDs and timestamp
        business_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        # Create user record linked to Cognito
        user_item = {
            'PK': f'USER#{user_id}',
            'SK': 'PROFILE',
            'GSI1_PK': email,
            'GSI1_SK': f'USER#{user_id}',
            'user_id': user_id,
            'cognito_user_id': cognito_user_id,
            'email': email,
            'owner_name': owner_name,
            'phone_number': phone_number,
            'created_at': timestamp,
            'updated_at': timestamp,
            'entity_type': 'USER'
        }
        
        # Create business record
        business_item = {
            'PK': f'BUS#{business_id}',
            'SK': 'PROFILE',
            'GSI1_PK': f'USER#{user_id}',
            'GSI1_SK': f'BUS#{business_id}',
            'business_id': business_id,
            'user_id': user_id,
            'name': business_name,
            'business_type': business_type,
            'status': 'pending_verification',
            'contact_phone': phone_number,
            'contact_email': email,
            'address': {
                'city': address.get('city', ''),
                'district': address.get('district', ''),
                'country': address.get('country', ''),
                'zip_code': address.get('zip_code', ''),
                'neighborhood': address.get('neighborhood', ''),
                'street': address.get('street', ''),
                'home_address': address.get('home_address', ''),
                'latitude': address.get('latitude', 0.0),
                'longitude': address.get('longitude', 0.0)
            },
            'settings': {
                'notifications_enabled': True,
                'auto_accept_orders': False,
                'operating_hours': {
                    'monday': {'open': '09:00', 'close': '22:00', 'is_open': True},
                    'tuesday': {'open': '09:00', 'close': '22:00', 'is_open': True},
                    'wednesday': {'open': '09:00', 'close': '22:00', 'is_open': True},
                    'thursday': {'open': '09:00', 'close': '22:00', 'is_open': True},
                    'friday': {'open': '09:00', 'close': '22:00', 'is_open': True},
                    'saturday': {'open': '09:00', 'close': '22:00', 'is_open': True},
                    'sunday': {'open': '09:00', 'close': '22:00', 'is_open': True}
                }
            },
            'created_at': timestamp,
            'updated_at': timestamp,
            'entity_type': 'BUSINESS'
        }
        
        # Create default categories for the business
        default_categories = [
            {'name': 'Appetizers', 'description': 'Starter dishes'},
            {'name': 'Main Courses', 'description': 'Main dishes'},
            {'name': 'Beverages', 'description': 'Drinks and beverages'},
            {'name': 'Desserts', 'description': 'Sweet treats and desserts'}
        ]
        
        category_items = []
        for i, category in enumerate(default_categories):
            category_id = str(uuid.uuid4())
            category_item = {
                'PK': f'BUS#{business_id}',
                'SK': f'CAT#{category_id}',
                'GSI1_PK': f'BUS#{business_id}',
                'GSI1_SK': f'CAT#{category_id}',
                'category_id': category_id,
                'business_id': business_id,
                'name': category['name'],
                'description': category['description'],
                'sort_order': i + 1,
                'is_active': True,
                'created_at': timestamp,
                'updated_at': timestamp,
                'entity_type': 'CATEGORY'
            }
            category_items.append(category_item)
        
        # Save all items to DynamoDB
        with _table.batch_writer() as batch:
            # Write user
            batch.put_item(Item=user_item)
            # Write business
            batch.put_item(Item=business_item)
            # Write categories
            for category_item in category_items:
                batch.put_item(Item=category_item)
        
        return {
            'statusCode': 201,
            'headers': get_cors_headers(),
            'body': json.dumps({
                'success': True,
                'user_id': user_id,
                'business_id': business_id,
                'message': 'Business registration completed successfully'
            })
        }
        
    except Exception as e:
        print(f"Business registration error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': get_cors_headers(),
            'body': json.dumps({
                'error': 'Failed to register business',
                'message': str(e) if os.getenv('ENVIRONMENT') != 'production' else 'Registration error'
            })
        }

def handle_verify(headers: Dict[str, Any]) -> Dict[str, Any]:
    """Handle token verification."""
    auth_header = headers.get('Authorization', headers.get('authorization', ''))
    
    if not auth_header.startswith('Bearer '):
        return {
            'statusCode': 401,
            'headers': get_cors_headers(),
            'body': json.dumps({'error': 'Missing or invalid authorization header'})
        }
    
    token = auth_header.replace('Bearer ', '')
    
    try:
        import jwt
        secret_key = os.getenv('SECRET_KEY', 'demo-secret-key')
        payload = jwt.decode(token, secret_key, algorithms=['HS256'])
        
        return {
            'statusCode': 200,
            'headers': get_cors_headers(),
            'body': json.dumps({
                'valid': True,
                'user': {
                    'id': payload.get('user_id'),
                    'email': payload.get('email')
                }
            })
        }
        
    except jwt.ExpiredSignatureError:
        return {
            'statusCode': 401,
            'headers': get_cors_headers(),
            'body': json.dumps({'error': 'Token expired'})
        }
    except jwt.InvalidTokenError:
        return {
            'statusCode': 401,
            'headers': get_cors_headers(),
            'body': json.dumps({'error': 'Invalid token'})
        }

def get_cors_headers() -> Dict[str, str]:
    """Get CORS headers for responses."""
    cors_origins = os.getenv('CORS_ORIGINS', '*')
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': cors_origins.split(',')[0] if ',' in cors_origins else cors_origins,
        'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
    }
