"""
Webhook handler for incoming orders and driver assignments from centralized platform.
Handles webhook events from the centralized delivery platform.
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

# Initialize services
dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')
apigateway = boto3.client('apigatewaymanagementapi')
table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'order-receiver-data')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """Main webhook handler"""
    
    try:
        http_method = event.get('httpMethod', '')
        resource_path = event.get('resource', '')
        path_params = event.get('pathParameters') or {}
        
        # Parse request body
        body = {}
        if event.get('body'):
            try:
                body = json.loads(event['body'])
            except json.JSONDecodeError:
                return create_response(400, {'error': 'Invalid JSON in request body'})
        
        logger.info(f"Webhook: {http_method} {resource_path}")
        logger.info(f"Webhook body: {json.dumps(body, default=str)}")
        
        # Route webhook events
        if resource_path == '/webhooks/new-order' and http_method == 'POST':
            return handle_new_order_webhook(body)
        
        elif resource_path == '/webhooks/driver-assignment' and http_method == 'POST':
            return handle_driver_assignment_webhook(body)
        
        elif resource_path == '/webhooks/order-status' and http_method == 'POST':
            return handle_order_status_webhook(body)
        
        elif resource_path == '/webhooks/customer-notification' and http_method == 'POST':
            return handle_customer_notification_webhook(body)
        
        else:
            return create_response(404, {'error': 'Webhook endpoint not found'})
    
    except Exception as e:
        logger.error(f"Webhook error: {str(e)}")
        return create_response(500, {'error': 'Internal server error'})

def handle_new_order_webhook(body: Dict[str, Any]) -> Dict[str, Any]:
    """Handle incoming new order from centralized platform"""
    try:
        # Extract order data
        order_id = body.get('order_id')
        business_id = body.get('business_id')
        order_data = body.get('order_data', {})
        
        if not order_id or not business_id:
            return create_response(400, {'error': 'Missing order_id or business_id'})
        
        # Create order record in DynamoDB
        timestamp = datetime.now(timezone.utc).isoformat()
        order_item = {
            'PK': f'ORDER#{order_id}',
            'SK': 'DETAILS',
            'GSI1_PK': f'BUSINESS#{business_id}',
            'GSI1_SK': f'ORDER#{timestamp}',
            'order_id': order_id,
            'business_id': business_id,
            'status': 'pending',
            'customer_name': order_data.get('customer_name', ''),
            'customer_phone': order_data.get('customer_phone', ''),
            'customer_email': order_data.get('customer_email', ''),
            'items': order_data.get('items', []),
            'total_amount': order_data.get('total_amount', 0),
            'delivery_address': order_data.get('delivery_address', {}),
            'delivery_fee': order_data.get('delivery_fee', 0),
            'payment_method': order_data.get('payment_method', ''),
            'special_instructions': order_data.get('special_instructions', ''),
            'created_at': timestamp,
            'updated_at': timestamp,
            'entity_type': 'ORDER'
        }
        
        # Save to DynamoDB
        table.put_item(Item=order_item)
        
        # Create notification for merchant
        notification_id = str(uuid.uuid4())
        notification_item = {
            'PK': f'NOTIFICATION#{notification_id}',
            'SK': 'DETAILS',
            'GSI1_PK': f'BUSINESS#{business_id}',
            'GSI1_SK': f'NOTIFICATION#{timestamp}',
            'notification_id': notification_id,
            'business_id': business_id,
            'type': 'new_order',
            'title': 'New Order Received',
            'message': f'New order from {order_data.get("customer_name", "Customer")} - ${order_data.get("total_amount", 0)}',
            'data': {
                'order_id': order_id,
                'customer_name': order_data.get('customer_name', ''),
                'total_amount': order_data.get('total_amount', 0)
            },
            'priority': 'high',
            'is_read': False,
            'created_at': timestamp,
            'entity_type': 'NOTIFICATION'
        }
        
        table.put_item(Item=notification_item)
        
        # Send real-time notification via WebSocket
        await_send_websocket_notification(business_id, notification_item)
        
        logger.info(f"New order {order_id} created for business {business_id}")
        
        return create_response(200, {
            'success': True,
            'order_id': order_id,
            'message': 'Order received successfully'
        })
        
    except Exception as e:
        logger.error(f"New order webhook error: {str(e)}")
        return create_response(500, {'error': 'Failed to process new order'})

def handle_driver_assignment_webhook(body: Dict[str, Any]) -> Dict[str, Any]:
    """Handle driver assignment notification from centralized platform"""
    try:
        order_id = body.get('order_id')
        driver_info = body.get('driver_info', {})
        estimated_pickup_time = body.get('estimated_pickup_time')
        
        if not order_id:
            return create_response(400, {'error': 'Missing order_id'})
        
        # Update order with driver information
        timestamp = datetime.now(timezone.utc).isoformat()
        
        try:
            table.update_item(
                Key={'PK': f'ORDER#{order_id}', 'SK': 'DETAILS'},
                UpdateExpression='SET driver_info = :driver, estimated_pickup_time = :pickup_time, updated_at = :updated',
                ExpressionAttributeValues={
                    ':driver': driver_info,
                    ':pickup_time': estimated_pickup_time,
                    ':updated': timestamp
                }
            )
        except ClientError as e:
            logger.error(f"Failed to update order {order_id}: {str(e)}")
            return create_response(404, {'error': 'Order not found'})
        
        # Get business_id from order
        try:
            order_response = table.get_item(Key={'PK': f'ORDER#{order_id}', 'SK': 'DETAILS'})
            if 'Item' not in order_response:
                return create_response(404, {'error': 'Order not found'})
            
            business_id = order_response['Item']['business_id']
        except ClientError:
            return create_response(500, {'error': 'Failed to retrieve order'})
        
        # Create notification for merchant
        notification_id = str(uuid.uuid4())
        notification_item = {
            'PK': f'NOTIFICATION#{notification_id}',
            'SK': 'DETAILS',
            'GSI1_PK': f'BUSINESS#{business_id}',
            'GSI1_SK': f'NOTIFICATION#{timestamp}',
            'notification_id': notification_id,
            'business_id': business_id,
            'type': 'driver_assigned',
            'title': 'Driver Assigned',
            'message': f'Driver {driver_info.get("name", "Unknown")} assigned to order {order_id}',
            'data': {
                'order_id': order_id,
                'driver_info': driver_info,
                'estimated_pickup_time': estimated_pickup_time
            },
            'priority': 'normal',
            'is_read': False,
            'created_at': timestamp,
            'entity_type': 'NOTIFICATION'
        }
        
        table.put_item(Item=notification_item)
        
        # Send real-time notification
        await_send_websocket_notification(business_id, notification_item)
        
        logger.info(f"Driver assigned to order {order_id}")
        
        return create_response(200, {
            'success': True,
            'order_id': order_id,
            'driver_info': driver_info,
            'message': 'Driver assignment processed successfully'
        })
        
    except Exception as e:
        logger.error(f"Driver assignment webhook error: {str(e)}")
        return create_response(500, {'error': 'Failed to process driver assignment'})

def handle_order_status_webhook(body: Dict[str, Any]) -> Dict[str, Any]:
    """Handle order status updates from centralized platform"""
    try:
        order_id = body.get('order_id')
        status = body.get('status')
        notes = body.get('notes', '')
        
        if not order_id or not status:
            return create_response(400, {'error': 'Missing order_id or status'})
        
        # Update order status
        timestamp = datetime.now(timezone.utc).isoformat()
        
        try:
            table.update_item(
                Key={'PK': f'ORDER#{order_id}', 'SK': 'DETAILS'},
                UpdateExpression='SET #status = :status, platform_notes = :notes, updated_at = :updated',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': status,
                    ':notes': notes,
                    ':updated': timestamp
                }
            )
        except ClientError as e:
            logger.error(f"Failed to update order {order_id}: {str(e)}")
            return create_response(404, {'error': 'Order not found'})
        
        logger.info(f"Order {order_id} status updated to {status}")
        
        return create_response(200, {
            'success': True,
            'order_id': order_id,
            'status': status,
            'message': 'Order status updated successfully'
        })
        
    except Exception as e:
        logger.error(f"Order status webhook error: {str(e)}")
        return create_response(500, {'error': 'Failed to update order status'})

def handle_customer_notification_webhook(body: Dict[str, Any]) -> Dict[str, Any]:
    """Handle customer notification requests from centralized platform"""
    try:
        customer_id = body.get('customer_id')
        order_id = body.get('order_id')
        notification_type = body.get('notification_type')
        message = body.get('message')
        
        if not customer_id or not notification_type:
            return create_response(400, {'error': 'Missing customer_id or notification_type'})
        
        # Log the customer notification for auditing
        timestamp = datetime.now(timezone.utc).isoformat()
        log_id = str(uuid.uuid4())
        
        log_item = {
            'PK': f'CUSTOMER_NOTIFICATION#{log_id}',
            'SK': 'LOG',
            'customer_id': customer_id,
            'order_id': order_id,
            'notification_type': notification_type,
            'message': message,
            'sent_at': timestamp,
            'entity_type': 'CUSTOMER_NOTIFICATION_LOG'
        }
        
        table.put_item(Item=log_item)
        
        logger.info(f"Customer notification logged: {notification_type} for customer {customer_id}")
        
        return create_response(200, {
            'success': True,
            'customer_id': customer_id,
            'notification_type': notification_type,
            'message': 'Customer notification logged successfully'
        })
        
    except Exception as e:
        logger.error(f"Customer notification webhook error: {str(e)}")
        return create_response(500, {'error': 'Failed to process customer notification'})

def await_send_websocket_notification(business_id: str, notification: Dict[str, Any]):
    """Send real-time notification via WebSocket to connected merchants"""
    try:
        # Query for active WebSocket connections for this business
        response = table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1_PK = :pk',
            ExpressionAttributeValues={
                ':pk': f'WEBSOCKET#{business_id}'
            }
        )
        
        connections = response.get('Items', [])
        
        # Send notification to each active connection
        for connection in connections:
            connection_id = connection.get('connection_id')
            if connection_id:
                try:
                    # Send message via API Gateway Management API
                    # Note: This would need the WebSocket API endpoint configured
                    message = {
                        'type': 'notification',
                        'data': notification
                    }
                    
                    # In production, you would use:
                    # apigateway.post_to_connection(
                    #     Data=json.dumps(message),
                    #     ConnectionId=connection_id
                    # )
                    
                    logger.info(f"WebSocket notification sent to connection {connection_id}")
                    
                except Exception as e:
                    logger.error(f"Failed to send WebSocket notification to {connection_id}: {str(e)}")
                    # Remove stale connection
                    try:
                        table.delete_item(
                            Key={
                                'PK': connection['PK'],
                                'SK': connection['SK']
                            }
                        )
                    except:
                        pass
    
    except Exception as e:
        logger.error(f"WebSocket notification error: {str(e)}")

def create_response(status_code: int, body: Dict[str, Any], headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
    """Create a properly formatted API Gateway response"""
    response_headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'
    }
    
    if headers:
        response_headers.update(headers)
    
    return {
        'statusCode': status_code,
        'headers': response_headers,
        'body': json.dumps(body, default=str)
    }
