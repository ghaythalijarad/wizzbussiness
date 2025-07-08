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
