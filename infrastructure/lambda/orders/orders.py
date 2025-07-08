"""
Order processing Lambda function for Order Receiver.
Handles order-related operations.
"""
import json
import os
from typing import Any, Dict
import uuid
from datetime import datetime

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for order processing requests.
    
    Args:
        event: Lambda event from API Gateway
        context: Lambda context
        
    Returns:
        API Gateway response
    """
    try:
        # Extract request details
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '/api/orders')
        body = event.get('body', '{}')
        headers = event.get('headers', {})
        path_parameters = event.get('pathParameters') or {}
        query_parameters = event.get('queryStringParameters') or {}
        
        # Parse request body
        try:
            request_data = json.loads(body) if body else {}
        except json.JSONDecodeError:
            request_data = {}
        
        # Route order requests
        if http_method == 'GET' and not path_parameters:
            return handle_list_orders(query_parameters, headers)
        elif http_method == 'POST':
            return handle_create_order(request_data, headers)
        elif http_method == 'GET' and path_parameters.get('proxy'):
            order_id = path_parameters.get('proxy')
            return handle_get_order(order_id, headers)
        elif http_method == 'PUT' and path_parameters.get('proxy'):
            order_id = path_parameters.get('proxy')
            return handle_update_order(order_id, request_data, headers)
        else:
            return {
                'statusCode': 404,
                'headers': get_cors_headers(),
                'body': json.dumps({'error': 'Not found'})
            }
            
    except Exception as e:
        print(f"Order Lambda error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': get_cors_headers(),
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') != 'production' else 'Order processing error'
            })
        }

def handle_list_orders(query_params: Dict[str, Any], headers: Dict[str, str]) -> Dict[str, Any]:
    """Handle listing orders."""
    # Demo data - replace with database query
    orders = [
        {
            'id': str(uuid.uuid4()),
            'customer_name': 'John Doe',
            'status': 'pending',
            'total': 25.99,
            'items': [
                {'name': 'Pizza Margherita', 'quantity': 1, 'price': 15.99},
                {'name': 'Coca Cola', 'quantity': 2, 'price': 5.00}
            ],
            'created_at': datetime.utcnow().isoformat()
        },
        {
            'id': str(uuid.uuid4()),
            'customer_name': 'Jane Smith',
            'status': 'completed',
            'total': 18.50,
            'items': [
                {'name': 'Burger', 'quantity': 1, 'price': 12.50},
                {'name': 'Fries', 'quantity': 1, 'price': 6.00}
            ],
            'created_at': datetime.utcnow().isoformat()
        }
    ]
    
    # Apply filters if provided
    status_filter = query_params.get('status')
    if status_filter:
        orders = [order for order in orders if order['status'] == status_filter]
    
    return {
        'statusCode': 200,
        'headers': get_cors_headers(),
        'body': json.dumps({
            'orders': orders,
            'total': len(orders),
            'page': int(query_params.get('page', 1)),
            'limit': int(query_params.get('limit', 10))
        })
    }

def handle_create_order(order_data: Dict[str, Any], headers: Dict[str, str]) -> Dict[str, Any]:
    """Handle creating a new order."""
    # Validate required fields
    required_fields = ['customer_name', 'items']
    for field in required_fields:
        if field not in order_data:
            return {
                'statusCode': 400,
                'headers': get_cors_headers(),
                'body': json.dumps({'error': f'Missing required field: {field}'})
            }
    
    # Calculate total
    total = sum(item.get('price', 0) * item.get('quantity', 1) for item in order_data.get('items', []))
    
    # Create order (demo - replace with database insert)
    new_order = {
        'id': str(uuid.uuid4()),
        'customer_name': order_data['customer_name'],
        'status': 'pending',
        'total': total,
        'items': order_data['items'],
        'special_instructions': order_data.get('special_instructions', ''),
        'delivery_address': order_data.get('delivery_address', {}),
        'created_at': datetime.utcnow().isoformat(),
        'updated_at': datetime.utcnow().isoformat()
    }
    
    return {
        'statusCode': 201,
        'headers': get_cors_headers(),
        'body': json.dumps({
            'message': 'Order created successfully',
            'order': new_order
        })
    }

def handle_get_order(order_id: str, headers: Dict[str, str]) -> Dict[str, Any]:
    """Handle getting a specific order."""
    # Demo order - replace with database query
    order = {
        'id': order_id,
        'customer_name': 'John Doe',
        'status': 'pending',
        'total': 25.99,
        'items': [
            {'name': 'Pizza Margherita', 'quantity': 1, 'price': 15.99},
            {'name': 'Coca Cola', 'quantity': 2, 'price': 5.00}
        ],
        'created_at': datetime.utcnow().isoformat()
    }
    
    return {
        'statusCode': 200,
        'headers': get_cors_headers(),
        'body': json.dumps({'order': order})
    }

def handle_update_order(order_id: str, update_data: Dict[str, Any], headers: Dict[str, str]) -> Dict[str, Any]:
    """Handle updating an order."""
    # Demo update - replace with database update
    updated_order = {
        'id': order_id,
        'customer_name': 'John Doe',
        'status': update_data.get('status', 'pending'),
        'total': 25.99,
        'items': [
            {'name': 'Pizza Margherita', 'quantity': 1, 'price': 15.99},
            {'name': 'Coca Cola', 'quantity': 2, 'price': 5.00}
        ],
        'updated_at': datetime.utcnow().isoformat()
    }
    
    return {
        'statusCode': 200,
        'headers': get_cors_headers(),
        'body': json.dumps({
            'message': 'Order updated successfully',
            'order': updated_order
        })
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
