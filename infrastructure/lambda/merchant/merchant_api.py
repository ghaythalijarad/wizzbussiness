"""
Merchant-focused Lambda handler for Order Receiver app.
Handles order management, notifications, and merchant workflows.
"""
import json
import os
import logging
from typing import Dict, Any, Optional
import boto3
from botocore.exceptions import ClientError
from datetime import datetime, timezone
import uuid

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

def get_merchant_id_from_token(event):
    """Extract merchant ID from authorization token/context"""
    # In production, this would decode JWT token
    # For now, get from headers or path parameters
    auth_context = event.get('requestContext', {}).get('authorizer', {})
    return auth_context.get('merchant_id') or event.get('pathParameters', {}).get('merchant_id')

def lambda_handler(event, context):
    """Main Lambda handler for merchant operations"""
    
    try:
        http_method = event.get('httpMethod', '')
        resource_path = event.get('resource', '')
        path_params = event.get('pathParameters') or {}
        query_params = event.get('queryStringParameters') or {}
        
        # Parse request body
        body = {}
        if event.get('body'):
            try:
                body = json.loads(event['body'])
            except json.JSONDecodeError:
                return create_response(400, {'error': 'Invalid JSON in request body'})
        
        logger.info(f"Processing {http_method} {resource_path}")
        
        # Route to appropriate handler
        if resource_path == '/orders/pending' and http_method == 'GET':
            return handle_get_pending_orders(path_params, query_params)
        
        elif resource_path == '/orders/{order_id}' and http_method == 'GET':
            return handle_get_order_details(path_params)
        
        elif resource_path == '/orders/{order_id}/accept' and http_method == 'POST':
            return handle_accept_order(path_params, body)
        
        elif resource_path == '/orders/{order_id}/reject' and http_method == 'POST':
            return handle_reject_order(path_params, body)
        
        elif resource_path == '/orders/{order_id}/status' and http_method == 'PUT':
            return handle_update_order_status(path_params, body)
        
        elif resource_path == '/orders/receive' and http_method == 'POST':
            return handle_receive_order(body)
        
        elif resource_path == '/notifications' and http_method == 'GET':
            return handle_get_notifications(path_params, query_params)
        
        elif resource_path == '/notifications/{notification_id}/read' and http_method == 'POST':
            return handle_mark_notification_read(path_params)
        
        elif resource_path == '/analytics/daily' and http_method == 'GET':
            return handle_get_daily_analytics(path_params, query_params)
        
        elif resource_path == '/health' and http_method == 'GET':
            return create_response(200, {'status': 'healthy', 'service': 'merchant-api'})
        
        else:
            return create_response(404, {'error': 'Endpoint not found'})
    
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return create_response(500, {'error': 'Internal server error'})

def handle_receive_order(body: Dict[str, Any]) -> Dict[str, Any]:
    """Handle incoming order from customer app"""
    try:
        # Validate required fields
        required_fields = ['business_id', 'customer_id', 'items', 'total_amount']
        for field in required_fields:
            if field not in body:
                return create_response(400, {'error': f'Missing required field: {field}'})
        
        # Create order
        order_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Main order record
        order_item = {
            'PK': f'ORDER#{order_id}',
            'SK': 'METADATA',
            'GSI1_PK': f'BUSINESS#{body["business_id"]}',
            'GSI1_SK': f'ORDER#{timestamp}',
            'GSI2_PK': f'CUSTOMER#{body["customer_id"]}',
            'GSI2_SK': f'ORDER#{timestamp}',
            
            'order_id': order_id,
            'business_id': body['business_id'],
            'customer_id': body['customer_id'],
            'customer_name': body.get('customer_name', ''),
            'customer_phone': body.get('customer_phone', ''),
            'customer_email': body.get('customer_email', ''),
            
            'status': 'pending_merchant',
            'total_amount': body['total_amount'],
            'tax_amount': body.get('tax_amount', 0),
            'delivery_fee': body.get('delivery_fee', 0),
            'discount_amount': body.get('discount_amount', 0),
            
            'delivery_address': body.get('delivery_address', {}),
            'delivery_instructions': body.get('delivery_instructions', ''),
            'estimated_preparation_time': body.get('estimated_preparation_time', 30),
            
            'payment_method': body.get('payment_method', 'cash'),
            'payment_status': body.get('payment_status', 'pending'),
            
            'created_at': timestamp,
            'updated_at': timestamp,
            'entity_type': 'ORDER'
        }
        
        # Save order
        table.put_item(Item=order_item)
        
        # Save order items
        for idx, item in enumerate(body['items']):
            item_id = str(uuid.uuid4())
            order_item_record = {
                'PK': f'ORDER#{order_id}',
                'SK': f'ITEM#{item_id}',
                'GSI1_PK': f'ORDER#{order_id}',
                'GSI1_SK': f'ITEM#{idx:03d}',
                
                'order_id': order_id,
                'item_id': item_id,
                'menu_item_id': item.get('menu_item_id', ''),
                'name': item['name'],
                'description': item.get('description', ''),
                'price': item['price'],
                'quantity': item['quantity'],
                'customizations': item.get('customizations', []),
                'special_instructions': item.get('special_instructions', ''),
                
                'created_at': timestamp,
                'entity_type': 'ORDER_ITEM'
            }
            table.put_item(Item=order_item_record)
        
        # Create notification for merchant
        notification_id = str(uuid.uuid4())
        notification = {
            'PK': f'BUSINESS#{body["business_id"]}',
            'SK': f'NOTIFICATION#{notification_id}',
            'GSI1_PK': f'NOTIFICATION#{body["business_id"]}',
            'GSI1_SK': timestamp,
            
            'notification_id': notification_id,
            'business_id': body['business_id'],
            'type': 'new_order',
            'status': 'unread',
            'title': 'New Order Received',
            'message': f'You have a new order #{order_id[:8]} for ${body["total_amount"]}',
            'order_id': order_id,
            'created_at': timestamp,
            'entity_type': 'NOTIFICATION'
        }
        table.put_item(Item=notification)
        
        return create_response(201, {
            'message': 'Order received successfully',
            'order_id': order_id,
            'status': 'pending_merchant'
        })
    
    except Exception as e:
        logger.error(f"Error receiving order: {str(e)}")
        return create_response(500, {'error': 'Failed to receive order'})

def handle_get_pending_orders(path_params: Dict[str, Any], query_params: Dict[str, Any]) -> Dict[str, Any]:
    """Get pending orders for merchant"""
    try:
        business_id = path_params.get('business_id') or query_params.get('business_id')
        if not business_id:
            return create_response(400, {'error': 'business_id is required'})
        
        # Query pending orders
        response = table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1_PK = :business_id',
            FilterExpression='attribute_exists(#status) AND #status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':business_id': f'BUSINESS#{business_id}',
                ':status': 'pending_merchant'
            },
            ScanIndexForward=False  # Latest orders first
        )
        
        orders = response.get('Items', [])
        
        # Get items for each order
        for order in orders:
            order_id = order['order_id']
            items_response = table.query(
                KeyConditionExpression='PK = :order_pk AND begins_with(SK, :item_prefix)',
                ExpressionAttributeValues={
                    ':order_pk': f'ORDER#{order_id}',
                    ':item_prefix': 'ITEM#'
                }
            )
            order['items'] = items_response.get('Items', [])
        
        return create_response(200, {
            'orders': orders,
            'count': len(orders)
        })
    
    except Exception as e:
        logger.error(f"Error getting pending orders: {str(e)}")
        return create_response(500, {'error': 'Failed to get pending orders'})

def handle_get_order_details(path_params: Dict[str, Any]) -> Dict[str, Any]:
    """Get detailed order information"""
    try:
        order_id = path_params.get('order_id')
        if not order_id:
            return create_response(400, {'error': 'order_id is required'})
        
        # Get order and all its items
        response = table.query(
            KeyConditionExpression='PK = :order_pk',
            ExpressionAttributeValues={':order_pk': f'ORDER#{order_id}'}
        )
        
        items = response.get('Items', [])
        order_data = None
        order_items = []
        
        for item in items:
            if item['SK'] == 'METADATA':
                order_data = item
            elif item['SK'].startswith('ITEM#'):
                order_items.append(item)
        
        if not order_data:
            return create_response(404, {'error': 'Order not found'})
        
        order_data['items'] = order_items
        
        return create_response(200, {'order': order_data})
    
    except Exception as e:
        logger.error(f"Error getting order details: {str(e)}")
        return create_response(500, {'error': 'Failed to get order details'})

def handle_accept_order(path_params: Dict[str, Any], body: Dict[str, Any]) -> Dict[str, Any]:
    """Accept an order"""
    try:
        order_id = path_params.get('order_id')
        merchant_id = body.get('merchant_id', 'unknown')
        estimated_time = body.get('estimated_preparation_time', 30)
        
        if not order_id:
            return create_response(400, {'error': 'order_id is required'})
        
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Update order status
        response = table.update_item(
            Key={'PK': f'ORDER#{order_id}', 'SK': 'METADATA'},
            UpdateExpression='SET #status = :status, updated_at = :timestamp, accepted_by = :merchant, estimated_preparation_time = :prep_time',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'accepted',
                ':timestamp': timestamp,
                ':merchant': merchant_id,
                ':prep_time': estimated_time
            },
            ReturnValues='ALL_NEW'
        )
        
        updated_order = response.get('Attributes', {})
        customer_id = updated_order.get('customer_id')
        
        # Create notification for customer
        if customer_id:
            notification_id = str(uuid.uuid4())
            customer_notification = {
                'PK': f'CUSTOMER#{customer_id}',
                'SK': f'NOTIFICATION#{notification_id}',
                'GSI1_PK': f'NOTIFICATION#{customer_id}',
                'GSI1_SK': timestamp,
                
                'notification_id': notification_id,
                'customer_id': customer_id,
                'type': 'order_update',
                'status': 'unread',
                'title': 'Order Accepted!',
                'message': f'Your order #{order_id[:8]} has been accepted and will be ready in {estimated_time} minutes',
                'order_id': order_id,
                'created_at': timestamp,
                'entity_type': 'NOTIFICATION'
            }
            table.put_item(Item=customer_notification)
        
        # Trigger driver assignment
        assignment_id = str(uuid.uuid4())
        driver_assignment = {
            'PK': f'DRIVER_ASSIGNMENT#{assignment_id}',
            'SK': 'METADATA',
            'GSI1_PK': f'ORDER#{order_id}',
            'GSI1_SK': f'ASSIGNMENT#{timestamp}',
            'GSI2_PK': 'PENDING_ASSIGNMENTS',
            'GSI2_SK': timestamp,
            
            'assignment_id': assignment_id,
            'order_id': order_id,
            'business_id': updated_order.get('business_id'),
            'pickup_address': updated_order.get('business_address', {}),
            'delivery_address': updated_order.get('delivery_address', {}),
            'delivery_fee': updated_order.get('delivery_fee', 0),
            'status': 'pending',
            'created_at': timestamp,
            'entity_type': 'DRIVER_ASSIGNMENT'
        }
        table.put_item(Item=driver_assignment)
        
        return create_response(200, {
            'message': 'Order accepted successfully',
            'order': updated_order,
            'driver_assignment_id': assignment_id
        })
    
    except Exception as e:
        logger.error(f"Error accepting order: {str(e)}")
        return create_response(500, {'error': 'Failed to accept order'})

def handle_reject_order(path_params: Dict[str, Any], body: Dict[str, Any]) -> Dict[str, Any]:
    """Reject an order"""
    try:
        order_id = path_params.get('order_id')
        merchant_id = body.get('merchant_id', 'unknown')
        rejection_reason = body.get('reason', 'No reason provided')
        
        if not order_id:
            return create_response(400, {'error': 'order_id is required'})
        
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Update order status
        response = table.update_item(
            Key={'PK': f'ORDER#{order_id}', 'SK': 'METADATA'},
            UpdateExpression='SET #status = :status, updated_at = :timestamp, rejected_by = :merchant, rejection_reason = :reason',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'rejected',
                ':timestamp': timestamp,
                ':merchant': merchant_id,
                ':reason': rejection_reason
            },
            ReturnValues='ALL_NEW'
        )
        
        updated_order = response.get('Attributes', {})
        customer_id = updated_order.get('customer_id')
        
        # Create notification for customer
        if customer_id:
            notification_id = str(uuid.uuid4())
            customer_notification = {
                'PK': f'CUSTOMER#{customer_id}',
                'SK': f'NOTIFICATION#{notification_id}',
                'GSI1_PK': f'NOTIFICATION#{customer_id}',
                'GSI1_SK': timestamp,
                
                'notification_id': notification_id,
                'customer_id': customer_id,
                'type': 'order_update',
                'status': 'unread',
                'title': 'Order Rejected',
                'message': f'Sorry, your order #{order_id[:8]} was rejected. Reason: {rejection_reason}',
                'order_id': order_id,
                'created_at': timestamp,
                'entity_type': 'NOTIFICATION'
            }
            table.put_item(Item=customer_notification)
        
        return create_response(200, {
            'message': 'Order rejected successfully',
            'order': updated_order
        })
    
    except Exception as e:
        logger.error(f"Error rejecting order: {str(e)}")
        return create_response(500, {'error': 'Failed to reject order'})

def handle_update_order_status(path_params: Dict[str, Any], body: Dict[str, Any]) -> Dict[str, Any]:
    """Update order status (preparing, ready, etc.)"""
    try:
        order_id = path_params.get('order_id')
        new_status = body.get('status')
        merchant_id = body.get('merchant_id', 'unknown')
        
        if not order_id or not new_status:
            return create_response(400, {'error': 'order_id and status are required'})
        
        valid_statuses = ['preparing', 'ready_for_pickup', 'completed']
        if new_status not in valid_statuses:
            return create_response(400, {'error': f'Invalid status. Must be one of: {valid_statuses}'})
        
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Update order status
        response = table.update_item(
            Key={'PK': f'ORDER#{order_id}', 'SK': 'METADATA'},
            UpdateExpression='SET #status = :status, updated_at = :timestamp, updated_by = :merchant',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': new_status,
                ':timestamp': timestamp,
                ':merchant': merchant_id
            },
            ReturnValues='ALL_NEW'
        )
        
        updated_order = response.get('Attributes', {})
        customer_id = updated_order.get('customer_id')
        
        # Create notification for customer
        if customer_id:
            status_messages = {
                'preparing': 'Your order is being prepared',
                'ready_for_pickup': 'Your order is ready for pickup!',
                'completed': 'Your order has been completed'
            }
            
            notification_id = str(uuid.uuid4())
            customer_notification = {
                'PK': f'CUSTOMER#{customer_id}',
                'SK': f'NOTIFICATION#{notification_id}',
                'GSI1_PK': f'NOTIFICATION#{customer_id}',
                'GSI1_SK': timestamp,
                
                'notification_id': notification_id,
                'customer_id': customer_id,
                'type': 'order_update',
                'status': 'unread',
                'title': f'Order Update - {new_status.title()}',
                'message': status_messages.get(new_status, f'Order status updated to {new_status}'),
                'order_id': order_id,
                'created_at': timestamp,
                'entity_type': 'NOTIFICATION'
            }
            table.put_item(Item=customer_notification)
        
        return create_response(200, {
            'message': 'Order status updated successfully',
            'order': updated_order
        })
    
    except Exception as e:
        logger.error(f"Error updating order status: {str(e)}")
        return create_response(500, {'error': 'Failed to update order status'})

def handle_get_notifications(path_params: Dict[str, Any], query_params: Dict[str, Any]) -> Dict[str, Any]:
    """Get notifications for merchant"""
    try:
        business_id = path_params.get('business_id') or query_params.get('business_id')
        limit = int(query_params.get('limit', 20))
        
        if not business_id:
            return create_response(400, {'error': 'business_id is required'})
        
        # Get notifications
        response = table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1_PK = :notification_pk',
            ExpressionAttributeValues={':notification_pk': f'NOTIFICATION#{business_id}'},
            ScanIndexForward=False,  # Latest first
            Limit=limit
        )
        
        notifications = response.get('Items', [])
        
        # Get unread count
        unread_response = table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1_PK = :notification_pk',
            FilterExpression='#status = :unread_status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':notification_pk': f'NOTIFICATION#{business_id}',
                ':unread_status': 'unread'
            },
            Select='COUNT'
        )
        unread_count = unread_response.get('Count', 0)
        
        return create_response(200, {
            'notifications': notifications,
            'unread_count': unread_count,
            'total_count': len(notifications)
        })
    
    except Exception as e:
        logger.error(f"Error getting notifications: {str(e)}")
        return create_response(500, {'error': 'Failed to get notifications'})

def handle_mark_notification_read(path_params: Dict[str, Any]) -> Dict[str, Any]:
    """Mark notification as read"""
    try:
        business_id = path_params.get('business_id')
        notification_id = path_params.get('notification_id')
        
        if not business_id or not notification_id:
            return create_response(400, {'error': 'business_id and notification_id are required'})
        
        # Update notification status
        response = table.update_item(
            Key={
                'PK': f'BUSINESS#{business_id}',
                'SK': f'NOTIFICATION#{notification_id}'
            },
            UpdateExpression='SET #status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'read'},
            ReturnValues='ALL_NEW'
        )
        
        return create_response(200, {
            'message': 'Notification marked as read',
            'notification': response.get('Attributes', {})
        })
    
    except Exception as e:
        logger.error(f"Error marking notification as read: {str(e)}")
        return create_response(500, {'error': 'Failed to mark notification as read'})

def handle_get_daily_analytics(path_params: Dict[str, Any], query_params: Dict[str, Any]) -> Dict[str, Any]:
    """Get daily analytics for merchant"""
    try:
        business_id = path_params.get('business_id') or query_params.get('business_id')
        date = query_params.get('date', datetime.now().strftime('%Y-%m-%d'))
        
        if not business_id:
            return create_response(400, {'error': 'business_id is required'})
        
        start_date = f"{date}T00:00:00"
        end_date = f"{date}T23:59:59"
        
        # Query orders for the date
        response = table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1_PK = :business_id AND GSI1_SK BETWEEN :start_date AND :end_date',
            ExpressionAttributeValues={
                ':business_id': f'BUSINESS#{business_id}',
                ':start_date': f'ORDER#{start_date}',
                ':end_date': f'ORDER#{end_date}'
            }
        )
        
        orders = response.get('Items', [])
        
        # Calculate statistics
        stats = {
            'date': date,
            'total_orders': len(orders),
            'accepted_orders': 0,
            'rejected_orders': 0,
            'completed_orders': 0,
            'total_revenue': 0,
            'average_order_value': 0
        }
        
        for order in orders:
            status = order.get('status', '')
            if status == 'accepted':
                stats['accepted_orders'] += 1
            elif status == 'rejected':
                stats['rejected_orders'] += 1
            elif status in ['delivered', 'completed']:
                stats['completed_orders'] += 1
                stats['total_revenue'] += float(order.get('total_amount', 0))
        
        if stats['completed_orders'] > 0:
            stats['average_order_value'] = stats['total_revenue'] / stats['completed_orders']
        
        return create_response(200, {'analytics': stats})
    
    except Exception as e:
        logger.error(f"Error getting daily analytics: {str(e)}")
        return create_response(500, {'error': 'Failed to get daily analytics'})
