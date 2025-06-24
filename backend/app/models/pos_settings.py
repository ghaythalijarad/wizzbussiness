"""
POS Settings Model for MongoDB storage and API operations
"""
from beanie import Document, PydanticObjectId
from pydantic import BaseModel, validator
from typing import Optional, Dict, Any
from datetime import datetime
from enum import Enum


class PosSystemType(str, Enum):
    """Supported POS system types"""
    SQUARE = "square"
    TOAST = "toast" 
    CLOVER = "clover"
    SHOPIFY_POS = "shopifyPos"
    GENERIC_API = "genericApi"


class PosSettings(BaseModel):
    """POS Settings configuration model"""
    enabled: bool = False
    auto_send_orders: bool = False
    system_type: PosSystemType = PosSystemType.GENERIC_API
    api_endpoint: str = ""
    api_key: str = ""
    access_token: Optional[str] = None
    location_id: Optional[str] = None
    
    # Additional configuration options
    timeout_seconds: int = 30
    retry_attempts: int = 3
    test_mode: bool = False
    
    # Connection status tracking
    last_connection_test: Optional[datetime] = None
    last_connection_status: bool = False
    last_error_message: Optional[str] = None
    
    @validator('api_endpoint')
    def validate_api_endpoint(cls, v):
        if v and not (v.startswith('http://') or v.startswith('https://')):
            raise ValueError('API endpoint must be a valid URL starting with http:// or https://')
        return v
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for storage"""
        return {
            "enabled": self.enabled,
            "auto_send_orders": self.auto_send_orders,
            "system_type": self.system_type.value,
            "api_endpoint": self.api_endpoint,
            "api_key": self.api_key,
            "access_token": self.access_token,
            "location_id": self.location_id,
            "timeout_seconds": self.timeout_seconds,
            "retry_attempts": self.retry_attempts,
            "test_mode": self.test_mode,
            "last_connection_test": self.last_connection_test.isoformat() if self.last_connection_test else None,
            "last_connection_status": self.last_connection_status,
            "last_error_message": self.last_error_message
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'PosSettings':
        """Create from dictionary"""
        if 'last_connection_test' in data and data['last_connection_test']:
            data['last_connection_test'] = datetime.fromisoformat(data['last_connection_test'])
        
        if 'system_type' in data and isinstance(data['system_type'], str):
            data['system_type'] = PosSystemType(data['system_type'])
            
        return cls(**data)


class BusinessPosSettings(Document):
    """MongoDB document for storing business POS settings"""
    business_id: PydanticObjectId
    settings: PosSettings
    created_at: datetime = datetime.utcnow()
    updated_at: datetime = datetime.utcnow()
    
    class Settings:
        name = "business_pos_settings"
        indexes = [
            "business_id",
            [("business_id", 1), ("updated_at", -1)]
        ]
    
    def update_settings(self, new_settings: PosSettings):
        """Update POS settings and timestamp"""
        self.settings = new_settings
        self.updated_at = datetime.utcnow()


class PosTestConnection(BaseModel):
    """Model for testing POS connection"""
    system_type: PosSystemType
    api_endpoint: str
    api_key: str
    access_token: Optional[str] = None
    location_id: Optional[str] = None
    timeout_seconds: int = 30


class PosConnectionResult(BaseModel):
    """Result of POS connection test"""
    success: bool
    message: str
    response_time_ms: Optional[int] = None
    error_details: Optional[str] = None
    system_info: Optional[Dict[str, Any]] = None


class PosOrderSyncLog(Document):
    """Log of orders sent to POS systems"""
    business_id: PydanticObjectId
    order_id: str
    pos_system_type: PosSystemType
    sync_status: str  # success, failed, pending
    sync_timestamp: datetime = datetime.utcnow()
    pos_order_id: Optional[str] = None
    error_message: Optional[str] = None
    retry_count: int = 0
    
    class Settings:
        name = "pos_order_sync_logs"
        indexes = [
            "business_id",
            "order_id", 
            "sync_timestamp",
            [("business_id", 1), ("sync_timestamp", -1)]
        ]
