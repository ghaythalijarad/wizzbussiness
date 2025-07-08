"""
DAO definitions for notifications and driver assignments
"""
import uuid
from datetime import datetime
from typing import Optional, List
import boto3
from botocore.exceptions import ClientError

# Initialize DynamoDB table
_dynamodb = boto3.resource('dynamodb')
_table_name = None

def _get_table():
    global _table_name
    if not _table_name:
        _table_name = __import__('os').environ.get('DYNAMODB_TABLE_NAME')
    return _dynamodb.Table(_table_name)

class NotificationDAO:
    """Data Access Object for merchant/customer notifications"""
    def __init__(self):
        self.table = _get_table()

    def create_notification(self, target_pk: str, message: str, metadata: dict = None) -> dict:
        notif_id = str(uuid.uuid4())
        ts = datetime.utcnow().isoformat()
        item = {
            'PK': target_pk,
            'SK': f'NOTIF#{notif_id}',
            'notification_id': notif_id,
            'message': message,
            'metadata': metadata or {},
            'created_at': ts,
            'read': False,
            'entity_type': 'NOTIFICATION'
        }
        self.table.put_item(Item=item)
        return item

    def list_notifications(self, target_pk: str, limit: int = 50) -> List[dict]:
        resp = self.table.query(
            KeyConditionExpression='PK = :pk',
            ExpressionAttributeValues={':pk': target_pk},
            ScanIndexForward=False,
            Limit=limit
        )
        return resp.get('Items', [])

class DriverAssignmentDAO:
    """Data Access Object for driver assignment operations"""
    def __init__(self):
        self.table = _get_table()

    def assign_driver(self, order_id: str, driver_id: str) -> dict:
        pk = f'ORDER#{order_id}'
        sk = f'DRIVER#{driver_id}'
        ts = datetime.utcnow().isoformat()
        item = {
            'PK': pk,
            'SK': sk,
            'order_id': order_id,
            'driver_id': driver_id,
            'assigned_at': ts,
            'entity_type': 'DRIVER_ASSIGNMENT'
        }
        self.table.put_item(Item=item)
        return item

    def get_assignments_for_driver(self, driver_id: str) -> List[dict]:
        resp = self.table.query(
            IndexName='GSI2',
            KeyConditionExpression='GSI2_PK = :drv',
            ExpressionAttributeValues={':drv': f'DRIVER#{driver_id}'},
            ScanIndexForward=False
        )
        return resp.get('Items', [])
