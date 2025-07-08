"""
Notification handler for managing merchant notifications.
Handles notification creation, delivery, and management.
"""
import json
import os
import logging
from typing import Dict, Any, Optional, List
import boto3
from botocore.exceptions import ClientError
from datetime import datetime, timezone, timedelta
import uuid

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize services
dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')
table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'order-receiver-data')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """Main notification handler"""
    
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
        
        logger.info(f"Notification: {http_method} {resource_path}")
        
        # Route notification requests
        if resource_path == '/notifications/{business_id}' and http_method == 'GET':
            return handle_get_notifications(path_params, query_params)
        
        elif resource_path == '/notifications/{business_id}/unread-count' and http_method == 'GET':
            return handle_get_unread_count(path_params)
        
        elif resource_path == '/notifications/{business_id}/{notification_id}/read' and http_method == 'POST':
            return handle_mark_notification_read(path_params)
        
        elif resource_path == '/notifications/{business_id}/mark-all-read' and http_method == 'POST':
            return handle_mark_all_read(path_params)
        
        elif resource_path == '/notifications/{business_id}/test' and http_method == 'POST':
            return handle_send_test_notification(path_params, body)
        
        elif resource_path == '/notifications/send' and http_method == 'POST':
            return handle_send_notification(body)
        
        elif resource_path == '/notifications/cleanup' and http_method == 'POST':
            return handle_cleanup_old_notifications(body)
        
        else:
            return create_response(404, {'error': 'Notification endpoint not found'})
    
    except Exception as e:
        logger.error(f"Notification error: {str(e)}")
        return create_response(500, {'error': 'Internal server error'})

def handle_get_notifications(path_params: Dict[str, Any], query_params: Dict[str, Any]) -> Dict[str, Any]:
    """Get notifications for a business"""
    try:
        business_id = path_params.get('business_id')
        if not business_id:
            return create_response(400, {'error': 'Missing business_id'})
        
        # Query parameters
        limit = int(query_params.get('limit', 50))
        unread_only = query_params.get('unread_only', 'false').lower() == 'true'
        
        # Query notifications from DynamoDB
        query_params_db = {
            'IndexName': 'GSI1',
            'KeyConditionExpression': 'GSI1_PK = :pk',
            'ExpressionAttributeValues': {
                ':pk': f'BUSINESS#{business_id}'
            },
            'ScanIndexForward': False,  # Most recent first
            'Limit': limit
        }
        
        # Add filter for unread notifications if requested
        if unread_only:
            query_params_db['FilterExpression'] = 'is_read = :is_read'
            query_params_db['ExpressionAttributeValues'][':is_read'] = False
        
        response = table.query(**query_params_db)
        notifications = response.get('Items', [])
        
        # Filter only notification items
        notifications = [item for item in notifications if item.get('entity_type') == 'NOTIFICATION']
        
        logger.info(f"Retrieved {len(notifications)} notifications for business {business_id}")
        
        return create_response(200, {
            'notifications': notifications,
            'count': len(notifications)
        })
        
    except Exception as e:
        logger.error(f"Get notifications error: {str(e)}")
        return create_response(500, {'error': 'Failed to retrieve notifications'})

def handle_get_unread_count(path_params: Dict[str, Any]) -> Dict[str, Any]:
    """Get count of unread notifications for a business"""
    try:
        business_id = path_params.get('business_id')
        if not business_id:
            return create_response(400, {'error': 'Missing business_id'})
        
        # Query unread notifications
        response = table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1_PK = :pk',
            FilterExpression='is_read = :is_read AND entity_type = :entity_type',
            ExpressionAttributeValues={
                ':pk': f'BUSINESS#{business_id}',
                ':is_read': False,
                ':entity_type': 'NOTIFICATION'
            },
            Select='COUNT'
        )
        
        unread_count = response.get('Count', 0)
        
        logger.info(f"Business {business_id} has {unread_count} unread notifications")
        
        return create_response(200, {
            'unread_count': unread_count
        })
        
    except Exception as e:
        logger.error(f"Get unread count error: {str(e)}")
        return create_response(500, {'error': 'Failed to get unread count'})

def handle_mark_notification_read(path_params: Dict[str, Any]) -> Dict[str, Any]:
    """Mark a specific notification as read"""
    try:
        business_id = path_params.get('business_id')
        notification_id = path_params.get('notification_id')
        
        if not business_id or not notification_id:
            return create_response(400, {'error': 'Missing business_id or notification_id'})
        
        # Update notification to mark as read
        timestamp = datetime.now(timezone.utc).isoformat()
        
        try:
            table.update_item(
                Key={'PK': f'NOTIFICATION#{notification_id}', 'SK': 'DETAILS'},
                UpdateExpression='SET is_read = :is_read, read_at = :read_at',
                ConditionExpression='business_id = :business_id',
                ExpressionAttributeValues={
                    ':is_read': True,
                    ':read_at': timestamp,
                    ':business_id': business_id
                }
            )
        except ClientError as e:
            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                return create_response(404, {'error': 'Notification not found or access denied'})
            raise
        
        logger.info(f"Notification {notification_id} marked as read")
        
        return create_response(200, {
            'success': True,
            'notification_id': notification_id,
            'message': 'Notification marked as read'
        })
        
    except Exception as e:
        logger.error(f"Mark notification read error: {str(e)}")
        return create_response(500, {'error': 'Failed to mark notification as read'})

def handle_mark_all_read(path_params: Dict[str, Any]) -> Dict[str, Any]:
    """Mark all notifications as read for a business"""
    try:
        business_id = path_params.get('business_id')
        if not business_id:
            return create_response(400, {'error': 'Missing business_id'})
        
        # Query all unread notifications for the business
        response = table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1_PK = :pk',
            FilterExpression='is_read = :is_read AND entity_type = :entity_type',
            ExpressionAttributeValues={
                ':pk': f'BUSINESS#{business_id}',
                ':is_read': False,
                ':entity_type': 'NOTIFICATION'
            }
        )
        
        unread_notifications = response.get('Items', [])
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Mark each notification as read
        updated_count = 0
        for notification in unread_notifications:
            try:
                table.update_item(
                    Key={'PK': notification['PK'], 'SK': notification['SK']},
                    UpdateExpression='SET is_read = :is_read, read_at = :read_at',
                    ExpressionAttributeValues={
                        ':is_read': True,
                        ':read_at': timestamp
                    }
                )
                updated_count += 1
            except ClientError as e:
                logger.error(f"Failed to update notification {notification.get('PK')}: {str(e)}")
                continue
        
        logger.info(f"Marked {updated_count} notifications as read for business {business_id}")
        
        return create_response(200, {
            'success': True,
            'updated_count': updated_count,
            'message': f'Marked {updated_count} notifications as read'
        })
        
    except Exception as e:
        logger.error(f"Mark all read error: {str(e)}")
        return create_response(500, {'error': 'Failed to mark all notifications as read'})

def handle_send_test_notification(path_params: Dict[str, Any], body: Dict[str, Any]) -> Dict[str, Any]:
    """Send a test notification to a business"""
    try:
        business_id = path_params.get('business_id')
        if not business_id:
            return create_response(400, {'error': 'Missing business_id'})
        
        message = body.get('message', 'This is a test notification')
        
        # Create test notification
        notification_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()
        
        notification_item = {
            'PK': f'NOTIFICATION#{notification_id}',
            'SK': 'DETAILS',
            'GSI1_PK': f'BUSINESS#{business_id}',
            'GSI1_SK': f'NOTIFICATION#{timestamp}',
            'notification_id': notification_id,
            'business_id': business_id,
            'type': 'test',
            'title': 'Test Notification',
            'message': message,
            'data': {'test': True},
            'priority': 'normal',
            'is_read': False,
            'created_at': timestamp,
            'entity_type': 'NOTIFICATION'
        }
        
        table.put_item(Item=notification_item)
        
        logger.info(f"Test notification sent to business {business_id}")
        
        return create_response(200, {
            'success': True,
            'notification_id': notification_id,
            'message': 'Test notification sent successfully'
        })
        
    except Exception as e:
        logger.error(f"Send test notification error: {str(e)}")
        return create_response(500, {'error': 'Failed to send test notification'})

def handle_send_notification(body: Dict[str, Any]) -> Dict[str, Any]:
    """Send a notification to one or more businesses"""
    try:
        business_ids = body.get('business_ids', [])
        if isinstance(business_ids, str):
            business_ids = [business_ids]
        
        notification_type = body.get('type', 'general')
        title = body.get('title', '')
        message = body.get('message', '')
        data = body.get('data', {})
        priority = body.get('priority', 'normal')
        
        if not business_ids or not title or not message:
            return create_response(400, {'error': 'Missing required fields: business_ids, title, message'})
        
        # Send notification to each business
        notification_ids = []
        timestamp = datetime.now(timezone.utc).isoformat()
        
        for business_id in business_ids:
            notification_id = str(uuid.uuid4())
            notification_item = {
                'PK': f'NOTIFICATION#{notification_id}',
                'SK': 'DETAILS',
                'GSI1_PK': f'BUSINESS#{business_id}',
                'GSI1_SK': f'NOTIFICATION#{timestamp}',
                'notification_id': notification_id,
                'business_id': business_id,
                'type': notification_type,
                'title': title,
                'message': message,
                'data': data,
                'priority': priority,
                'is_read': False,
                'created_at': timestamp,
                'entity_type': 'NOTIFICATION'
            }
            table.put_item(Item=notification_item)
            notification_ids.append(notification_id)

        
        logger.info(f"Sent notifications to {len(business_ids)} businesses")
        
        return create_response(200, {
            'success': True,
            'notification_ids': notification_ids,
            'business_count': len(business_ids),
            'message': f'Notifications sent to {len(business_ids)} businesses'
        })
        
    except Exception as e:
        logger.error(f"Send notification error: {str(e)}")
        return create_response(500, {'error': 'Failed to send notifications'})

def handle_cleanup_old_notifications(body: Dict[str, Any]) -> Dict[str, Any]:
    """Clean up old notifications (admin function)"""
    try:
        days_old = body.get('days_old', 30)
        business_id = body.get('business_id')  # Optional: clean for specific business
        
        # Calculate cutoff date
        cutoff_date = (datetime.now(timezone.utc) - timedelta(days=days_old)).isoformat()
        
        # Query old notifications
        if business_id:
            response = table.query(
                IndexName='GSI1',
                KeyConditionExpression='GSI1_PK = :pk AND GSI1_SK < :sk',
                ExpressionAttributeValues={
                    ':pk': f'BUSINESS#{business_id}',
                    ':sk': f'NOTIFICATION#{cutoff_date}'
                }
            )
        else:
            # This requires a full table scan which is expensive.
            # Consider a more efficient approach for production, e.g., a dedicated GSI.
            response = table.scan(
                FilterExpression='entity_type = :entity_type AND created_at < :cutoff',
                ExpressionAttributeValues={
                    ':entity_type': 'NOTIFICATION',
                    ':cutoff': cutoff_date
                }
            )
        
        old_notifications = response.get('Items', [])
        
        # Delete old notifications
        deleted_count = 0
        with table.batch_writer() as batch:
            for notification in old_notifications:
                batch.delete_item(
                    Key={'PK': notification['PK'], 'SK': notification['SK']}
                )
                deleted_count += 1
        
        logger.info(f"Deleted {deleted_count} old notifications older than {days_old} days")
        
        return create_response(200, {
            'success': True,
            'deleted_count': deleted_count,
            'cutoff_date': cutoff_date,
            'message': f'Deleted {deleted_count} old notifications'
        })
        
    except Exception as e:
        logger.error(f"Cleanup notifications error: {str(e)}")
        return create_response(500, {'error': 'Failed to cleanup old notifications'})

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
