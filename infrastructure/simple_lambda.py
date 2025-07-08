import json
import uuid
from datetime import datetime

def lambda_handler(event, context):
    """Main Lambda handler"""
    try:
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '/')
        body = event.get('body', '{}')
        
        try:
            request_data = json.loads(body) if body else {}
        except:
            request_data = {}
        
        if path == '/register' and http_method == 'POST':
            return handle_register(request_data)
        elif path == '/login' and http_method == 'POST':
            return handle_login(request_data)
        elif path == '/orders' and http_method == 'GET':
            return handle_get_orders()
        elif path == '/health':
            return create_response(200, {'status': 'healthy'})
        else:
            return create_response(404, {'error': 'Not found'})
    except Exception as e:
        return create_response(500, {'error': str(e)})

def handle_register(data):
    email = data.get('email')
    password = data.get('password')
    if not email or not password:
        return create_response(400, {'error': 'Email and password required'})
    return create_response(201, {'id': str(uuid.uuid4()), 'email': email})

def handle_login(data):
    email = data.get('email')
    password = data.get('password')
    if email == 'saif@yahoo.com' and password == 'Gha@551987':
        return create_response(200, {
            'access_token': f'token-{uuid.uuid4()}',
            'user': {'email': email, 'business_name': 'Demo Restaurant'}
        })
    return create_response(401, {'error': 'Invalid credentials'})

def handle_get_orders():
    orders = [
        {'id': str(uuid.uuid4()), 'customer_name': 'Ahmed', 'status': 'pending', 'total': 45.50},
        {'id': str(uuid.uuid4()), 'customer_name': 'Fatima', 'status': 'preparing', 'total': 32.00}
    ]
    return create_response(200, {'orders': orders})

def create_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization'
        },
        'body': json.dumps(body)
    }
