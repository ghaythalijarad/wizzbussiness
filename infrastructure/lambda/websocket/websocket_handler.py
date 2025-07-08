"""
WebSocket API for real-time notifications to merchants.
Handles connection management and real-time order notifications.
"""
import json
import os
import logging
from typing import Dict, Any, Optional
import boto3
from botocore.exceptions import ClientError
from datetime import datetime, timezone

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize services
dynamodb = boto3.resource('dynamodb')
apigateway = boto3.client('apigatewaymanagementapi')
table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'order-receiver-data')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """WebSocket event handler"""
    
    try:
        route_key = event.get('requestContext', {}).get('routeKey', '')
        connection_id = event.get('requestContext', {}).get('connectionId', '')
        
        logger.info(f"WebSocket event: {route_key}, Connection: {connection_id}")
        
        if route_key == '$connect':
            return handle_connect(event, connection_id)
        elif route_key == '$disconnect':
            return handle_disconnect(event, connection_id)
        elif route_key == 'subscribe_merchant':
            return handle_merchant_subscribe(event, connection_id)
        elif route_key == 'ping':
            return handle_ping(event, connection_id)
        else:
            return {'statusCode': 404}
    
    except Exception as e:
        logger.error(f"WebSocket error: {str(e)}")
        return {'statusCode': 500}

def handle_connect(event, connection_id):
    """Handle WebSocket connection"""
    try:
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Store connection
        connection_item = {
            'PK': f'WEBSOCKET#{connection_id}',
            'SK': 'CONNECTION',
            'GSI1_PK': 'ACTIVE_CONNECTIONS',
            'GSI1_SK': timestamp,
            
            'connection_id': connection_id,
            'status': 'connected',
            'connected_at': timestamp,
            'last_ping': timestamp,
            'entity_type': 'WEBSOCKET_CONNECTION'
        }
        
        table.put_item(Item=connection_item)
        
        return {'statusCode': 200}
    
    except Exception as e:
        logger.error(f"Error handling connect: {str(e)}")
        return {'statusCode': 500}

def handle_disconnect(event, connection_id):
    """Handle WebSocket disconnection"""
    try:
        # Remove connection
        table.delete_item(
            Key={
                'PK': f'WEBSOCKET#{connection_id}',
                'SK': 'CONNECTION'
            }
        )
        
        # Remove merchant subscription if exists
        try:
            table.delete_item(
                Key={
                    'PK': f'WEBSOCKET#{connection_id}',
                    'SK': 'MERCHANT_SUBSCRIPTION'
                }
            )
        except:
            pass  # Subscription might not exist
        
        return {'statusCode': 200}
    
    except Exception as e:
        logger.error(f"Error handling disconnect: {str(e)}")
        return {'statusCode': 500}

def handle_merchant_subscribe(event, connection_id):
    """Subscribe merchant to real-time notifications"""
    try:
        body = json.loads(event.get('body', '{}'))
        merchant_id = body.get('merchant_id')
        business_id = body.get('business_id')
        
        if not merchant_id or not business_id:
            send_error_message(connection_id, "merchant_id and business_id are required")
            return {'statusCode': 400}
        
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Store merchant subscription
        subscription_item = {
            'PK': f'WEBSOCKET#{connection_id}',
            'SK': 'MERCHANT_SUBSCRIPTION',
            'GSI1_PK': f'MERCHANT_NOTIFICATIONS#{business_id}',
            'GSI1_SK': connection_id,
            
            'connection_id': connection_id,
            'merchant_id': merchant_id,
            'business_id': business_id,
            'subscribed_at': timestamp,
            'entity_type': 'MERCHANT_SUBSCRIPTION'
        }
        
        table.put_item(Item=subscription_item)
        
        # Send confirmation
        send_message(connection_id, {
            'type': 'subscription_confirmed',
            'merchant_id': merchant_id,
            'business_id': business_id,
            'message': 'Successfully subscribed to real-time notifications'
        })
        
        return {'statusCode': 200}
    
    except Exception as e:
        logger.error(f"Error handling merchant subscribe: {str(e)}")
        return {'statusCode': 500}

def handle_ping(event, connection_id):
    """Handle ping/keepalive"""
    try:
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Update last ping time
        table.update_item(
            Key={
                'PK': f'WEBSOCKET#{connection_id}',
                'SK': 'CONNECTION'
            },
            UpdateExpression='SET last_ping = :timestamp',
            ExpressionAttributeValues={':timestamp': timestamp}
        )
        
        # Send pong
        send_message(connection_id, {
            'type': 'pong',
            'timestamp': timestamp
        })
        
        return {'statusCode': 200}
    
    except Exception as e:
        logger.error(f"Error handling ping: {str(e)}")
        return {'statusCode': 500}

def send_message(connection_id: str, message: Dict[str, Any]):
    """Send message to WebSocket connection"""
    try:
        apigateway.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps(message)
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'GoneException':
            # Connection is stale, remove it
            logger.info(f"Removing stale connection: {connection_id}")
            try:
                table.delete_item(
                    Key={
                        'PK': f'WEBSOCKET#{connection_id}',
                        'SK': 'CONNECTION'
                    }
                )
            except:
                pass
        else:
            logger.error(f"Error sending message: {str(e)}")

def send_error_message(connection_id: str, error: str):
    """Send error message to WebSocket connection"""
    send_message(connection_id, {
        'type': 'error',
        'error': error
    })

def notify_merchants_of_new_order(business_id: str, order_data: Dict[str, Any]):
    """Send real-time notification to subscribed merchants"""
    try:
        # Get all connections subscribed to this business
        response = table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1_PK = :subscription_key',
            ExpressionAttributeValues={
                ':subscription_key': f'MERCHANT_NOTIFICATIONS#{business_id}'
            }
        )
        
        connections = response.get('Items', [])
        
        notification_message = {
            'type': 'new_order',
            'order_id': order_data['order_id'],
            'customer_name': order_data.get('customer_name', 'Unknown'),
            'total_amount': order_data.get('total_amount', 0),
            'items_count': len(order_data.get('items', [])),
            'delivery_address': order_data.get('delivery_address', {}),
            'created_at': order_data.get('created_at'),
            'message': f"New order #{order_data['order_id'][:8]} for ${order_data.get('total_amount', 0)}"
        }
        
        # Send to all connected merchants
        for connection in connections:
            connection_id = connection['connection_id']
            send_message(connection_id, notification_message)
        
        logger.info(f"Sent new order notification to {len(connections)} connections")
        
    except Exception as e:
        logger.error(f"Error notifying merchants: {str(e)}")

def notify_merchants_of_status_update(business_id: str, order_id: str, status: str, details: Dict[str, Any] = None):
    """Send order status update to merchants"""
    try:
        # Get all connections subscribed to this business
        response = table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1_PK = :subscription_key',
            ExpressionAttributeValues={
                ':subscription_key': f'MERCHANT_NOTIFICATIONS#{business_id}'
            }
        )
        
        connections = response.get('Items', [])
        
        notification_message = {
            'type': 'order_status_update',
            'order_id': order_id,
            'status': status,
            'details': details or {},
            'message': f"Order #{order_id[:8]} status updated to {status}"
        }
        
        # Send to all connected merchants
        for connection in connections:
            connection_id = connection['connection_id']
            send_message(connection_id, notification_message)
        
        logger.info(f"Sent status update notification to {len(connections)} connections")
        
    except Exception as e:
        logger.error(f"Error notifying merchants of status update: {str(e)}")
