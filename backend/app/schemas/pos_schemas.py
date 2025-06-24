"""
POS Settings Schemas for request/response validation
"""
from pydantic import BaseModel, validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

from ..models.pos_settings import PosSystemType


class PosSettingsBase(BaseModel):
    """Base POS settings schema"""
    enabled: bool = False
    auto_send_orders: bool = False
    system_type: PosSystemType = PosSystemType.GENERIC_API
    api_endpoint: str = ""
    api_key: str = ""
    access_token: Optional[str] = None
    location_id: Optional[str] = None
    timeout_seconds: int = 30
    retry_attempts: int = 3
    test_mode: bool = False

    @validator('api_endpoint')
    def validate_api_endpoint(cls, v):
        if v and not (v.startswith('http://') or v.startswith('https://')):
            raise ValueError('API endpoint must be a valid URL starting with http:// or https://')
        return v

    @validator('timeout_seconds')
    def validate_timeout(cls, v):
        if v < 5 or v > 300:
            raise ValueError('Timeout must be between 5 and 300 seconds')
        return v

    @validator('retry_attempts')
    def validate_retry_attempts(cls, v):
        if v < 0 or v > 10:
            raise ValueError('Retry attempts must be between 0 and 10')
        return v


class PosSettingsCreate(PosSettingsBase):
    """Schema for creating POS settings"""
    pass


class PosSettingsUpdate(BaseModel):
    """Schema for updating POS settings"""
    enabled: Optional[bool] = None
    auto_send_orders: Optional[bool] = None
    system_type: Optional[PosSystemType] = None
    api_endpoint: Optional[str] = None
    api_key: Optional[str] = None
    access_token: Optional[str] = None
    location_id: Optional[str] = None
    timeout_seconds: Optional[int] = None
    retry_attempts: Optional[int] = None
    test_mode: Optional[bool] = None

    @validator('api_endpoint')
    def validate_api_endpoint(cls, v):
        if v and not (v.startswith('http://') or v.startswith('https://')):
            raise ValueError('API endpoint must be a valid URL starting with http:// or https://')
        return v

    @validator('timeout_seconds')
    def validate_timeout(cls, v):
        if v is not None and (v < 5 or v > 300):
            raise ValueError('Timeout must be between 5 and 300 seconds')
        return v

    @validator('retry_attempts')
    def validate_retry_attempts(cls, v):
        if v is not None and (v < 0 or v > 10):
            raise ValueError('Retry attempts must be between 0 and 10')
        return v


class PosSettingsResponse(BaseModel):
    """Schema for POS settings response"""
    business_id: str
    settings: PosSettingsBase
    last_updated: Optional[datetime] = None
    connection_status: Optional[bool] = None
    last_test_date: Optional[datetime] = None


class PosTestRequest(BaseModel):
    """Schema for testing POS connection"""
    system_type: PosSystemType
    api_endpoint: str
    api_key: str
    access_token: Optional[str] = None
    location_id: Optional[str] = None
    timeout_seconds: int = 30

    @validator('api_endpoint')
    def validate_api_endpoint(cls, v):
        if not (v.startswith('http://') or v.startswith('https://')):
            raise ValueError('API endpoint must be a valid URL starting with http:// or https://')
        return v


class PosConnectionResponse(BaseModel):
    """Schema for POS connection test response"""
    success: bool
    message: str
    response_time_ms: Optional[int] = None
    error_details: Optional[str] = None
    system_info: Optional[Dict[str, Any]] = None
    tested_at: datetime


class PosSyncLogResponse(BaseModel):
    """Schema for POS sync log response"""
    id: str
    business_id: str
    order_id: str
    pos_system_type: PosSystemType
    sync_status: str
    sync_timestamp: datetime
    pos_order_id: Optional[str] = None
    error_message: Optional[str] = None
    retry_count: int = 0


class PosSystemInfo(BaseModel):
    """Schema for POS system information"""
    type: PosSystemType
    name: str
    description: str
    api_docs_url: str
    required_fields: List[str]
    optional_fields: List[str]


class PosOrderSyncRequest(BaseModel):
    """Schema for manual order sync request"""
    order_id: str
    force_resync: bool = False


class PosSystemStats(BaseModel):
    """Schema for POS system statistics"""
    total_orders_synced: int
    successful_syncs: int
    failed_syncs: int
    last_sync_time: Optional[datetime] = None
    average_response_time_ms: Optional[float] = None
    sync_success_rate: float = 0.0


class PosHealthStatus(BaseModel):
    """Schema for POS system health status"""
    system_type: PosSystemType
    is_connected: bool
    last_check: datetime
    response_time_ms: Optional[int] = None
    error_message: Optional[str] = None
    uptime_percentage: float = 0.0


class PosConfigurationGuide(BaseModel):
    """Schema for POS configuration guide"""
    system_type: PosSystemType
    setup_steps: List[str]
    required_permissions: List[str]
    api_endpoints: Dict[str, str]
    webhook_urls: Optional[Dict[str, str]] = None
    testing_instructions: List[str]


class PosErrorResponse(BaseModel):
    """Schema for POS error responses"""
    error_code: str
    error_message: str
    error_details: Optional[Dict[str, Any]] = None
    timestamp: datetime
    suggested_action: Optional[str] = None


class PosBulkSyncRequest(BaseModel):
    """Schema for bulk order sync request"""
    order_ids: List[str]
    sync_since: Optional[datetime] = None
    force_resync: bool = False


class PosBulkSyncResponse(BaseModel):
    """Schema for bulk sync response"""
    total_orders: int
    successful_syncs: int
    failed_syncs: int
    sync_results: List[Dict[str, Any]]
    started_at: datetime
    completed_at: Optional[datetime] = None
