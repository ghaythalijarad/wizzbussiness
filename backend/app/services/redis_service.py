"""
Redis Service for Production
Handles caching, session management, and pub/sub for real-time notifications
"""

import redis.asyncio as redis
import json
import logging
from typing import Any, Optional, Dict, List
import os
import asyncio
from datetime import datetime, timedelta

class RedisService:
    def __init__(self):
        self.client = None
        self.pubsub = None
        self.connected = False
        
    async def initialize(self):
        """Initialize Redis connection."""
        redis_url = os.getenv("REDIS_URL")
        if not redis_url:
            logging.warning("REDIS_URL not found, Redis features will be disabled")
            return False
            
        try:
            # Parse Redis URL for connection parameters
            self.client = redis.from_url(
                redis_url,
                encoding="utf-8",
                decode_responses=True,
                socket_keepalive=True,
                socket_keepalive_options={},
                health_check_interval=30,
                retry_on_timeout=True,
                socket_connect_timeout=5,
                socket_timeout=5
            )
            
            # Test connection
            await self.client.ping()
            self.connected = True
            logging.info("Redis connected successfully")
            
            # Initialize pub/sub
            self.pubsub = self.client.pubsub()
            
            return True
            
        except Exception as e:
            logging.error(f"Redis connection failed: {e}")
            self.connected = False
            return False
    
    async def health_check(self) -> Dict[str, Any]:
        """Check Redis health."""
        if not self.client:
            return {"healthy": False, "status": "not_configured"}
        
        try:
            start_time = datetime.now()
            await self.client.ping()
            response_time = (datetime.now() - start_time).total_seconds()
            
            # Get Redis info
            info = await self.client.info()
            
            return {
                "healthy": True,
                "status": "connected",
                "response_time": response_time,
                "connected_clients": info.get("connected_clients", 0),
                "used_memory": info.get("used_memory_human", "unknown"),
                "redis_version": info.get("redis_version", "unknown")
            }
        except Exception as e:
            return {
                "healthy": False,
                "status": "error",
                "error": str(e)
            }
    
    # Caching Methods
    async def cache_set(self, key: str, value: Any, ttl: int = 3600) -> bool:
        """Set cache value with TTL."""
        if not self.connected:
            return False
            
        try:
            serialized = json.dumps(value) if not isinstance(value, str) else value
            await self.client.setex(key, ttl, serialized)
            return True
        except Exception as e:
            logging.error(f"Cache set error for key '{key}': {e}")
            return False
    
    async def cache_get(self, key: str) -> Optional[Any]:
        """Get cache value."""
        if not self.connected:
            return None
            
        try:
            value = await self.client.get(key)
            if value:
                try:
                    return json.loads(value)
                except json.JSONDecodeError:
                    return value
        except Exception as e:
            logging.error(f"Cache get error for key '{key}': {e}")
        return None
    
    async def cache_delete(self, key: str) -> bool:
        """Delete cache value."""
        if not self.connected:
            return False
            
        try:
            await self.client.delete(key)
            return True
        except Exception as e:
            logging.error(f"Cache delete error for key '{key}': {e}")
            return False
    
    async def cache_exists(self, key: str) -> bool:
        """Check if cache key exists."""
        if not self.connected:
            return False
            
        try:
            result = await self.client.exists(key)
            return bool(result)
        except Exception as e:
            logging.error(f"Cache exists error for key '{key}': {e}")
            return False
    
    # Pub/Sub Methods for Real-time Notifications
    async def publish_notification(self, channel: str, data: Dict[str, Any]) -> bool:
        """Publish notification to Redis channel."""
        if not self.connected:
            return False
            
        try:
            message = json.dumps({
                "timestamp": datetime.utcnow().isoformat(),
                "data": data
            })
            
            await self.client.publish(channel, message)
            logging.info(f"Published notification to channel '{channel}'")
            return True
        except Exception as e:
            logging.error(f"Publish error for channel '{channel}': {e}")
            return False
    
    async def subscribe_to_notifications(self, channels: List[str], callback):
        """Subscribe to notification channels."""
        if not self.connected:
            logging.warning("Cannot subscribe: Redis not connected")
            return
            
        try:
            await self.pubsub.subscribe(*channels)
            logging.info(f"Subscribed to channels: {channels}")
            
            async for message in self.pubsub.listen():
                if message["type"] == "message":
                    try:
                        data = json.loads(message["data"])
                        await callback(message["channel"], data)
                    except Exception as e:
                        logging.error(f"Error processing message: {e}")
                        
        except Exception as e:
            logging.error(f"Subscription error: {e}")
    
    # Session Management
    async def set_session(self, session_id: str, user_data: Dict[str, Any], ttl: int = 3600) -> bool:
        """Set user session data."""
        return await self.cache_set(f"session:{session_id}", user_data, ttl)
    
    async def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get user session data."""
        return await self.cache_get(f"session:{session_id}")
    
    async def delete_session(self, session_id: str) -> bool:
        """Delete user session."""
        return await self.cache_delete(f"session:{session_id}")
    
    # Rate Limiting
    async def check_rate_limit(self, key: str, limit: int, window: int) -> Dict[str, Any]:
        """Check rate limit for a key."""
        if not self.connected:
            return {"allowed": True, "remaining": limit}
            
        try:
            current_count = await self.client.incr(key)
            
            if current_count == 1:
                # First request, set expiration
                await self.client.expire(key, window)
            
            remaining = max(0, limit - current_count)
            allowed = current_count <= limit
            
            return {
                "allowed": allowed,
                "remaining": remaining,
                "reset_time": window,
                "total": limit
            }
            
        except Exception as e:
            logging.error(f"Rate limit check error for key '{key}': {e}")
            return {"allowed": True, "remaining": limit}
    
    # Business-specific caching
    async def cache_business_stats(self, business_id: str, stats: Dict[str, Any], ttl: int = 600) -> bool:
        """Cache business statistics."""
        return await self.cache_set(f"business_stats:{business_id}", stats, ttl)
    
    async def get_business_stats(self, business_id: str) -> Optional[Dict[str, Any]]:
        """Get cached business statistics."""
        return await self.cache_get(f"business_stats:{business_id}")
    
    async def cache_user_permissions(self, user_id: str, permissions: List[str], ttl: int = 1800) -> bool:
        """Cache user permissions."""
        return await self.cache_set(f"user_permissions:{user_id}", permissions, ttl)
    
    async def get_user_permissions(self, user_id: str) -> Optional[List[str]]:
        """Get cached user permissions."""
        return await self.cache_get(f"user_permissions:{user_id}")
    
    # Notification queuing
    async def queue_notification(self, business_id: str, notification: Dict[str, Any]) -> bool:
        """Queue notification for later delivery."""
        if not self.connected:
            return False
            
        try:
            queue_key = f"notification_queue:{business_id}"
            notification_with_timestamp = {
                **notification,
                "queued_at": datetime.utcnow().isoformat()
            }
            
            await self.client.lpush(queue_key, json.dumps(notification_with_timestamp))
            # Keep only last 100 notifications
            await self.client.ltrim(queue_key, 0, 99)
            return True
            
        except Exception as e:
            logging.error(f"Queue notification error: {e}")
            return False
    
    async def get_queued_notifications(self, business_id: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Get queued notifications for a business."""
        if not self.connected:
            return []
            
        try:
            queue_key = f"notification_queue:{business_id}"
            notifications = await self.client.lrange(queue_key, 0, limit - 1)
            
            return [json.loads(notif) for notif in notifications]
            
        except Exception as e:
            logging.error(f"Get queued notifications error: {e}")
            return []
    
    async def clear_notification_queue(self, business_id: str) -> bool:
        """Clear notification queue for a business."""
        if not self.connected:
            return False
            
        try:
            queue_key = f"notification_queue:{business_id}"
            await self.client.delete(queue_key)
            return True
            
        except Exception as e:
            logging.error(f"Clear notification queue error: {e}")
            return False
    
    async def close(self):
        """Close Redis connections."""
        if self.pubsub:
            await self.pubsub.unsubscribe()
            await self.pubsub.close()
        
        if self.client:
            await self.client.close()
        
        self.connected = False
        logging.info("Redis connections closed")

# Global Redis service instance
redis_service = RedisService()

# Decorators for caching
def cache_result(ttl: int = 300, key_prefix: str = "cache"):
    """Decorator to cache function results in Redis."""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            # Create cache key from function name and args
            cache_key = f"{key_prefix}:{func.__name__}:{hash(str(args) + str(kwargs))}"
            
            # Try to get from cache
            cached = await redis_service.cache_get(cache_key)
            if cached is not None:
                return cached
            
            # Execute function and cache result
            result = await func(*args, **kwargs)
            await redis_service.cache_set(cache_key, result, ttl)
            return result
        return wrapper
    return decorator

# Rate limiting decorator
def rate_limit(limit: int = 100, window: int = 3600):
    """Decorator for rate limiting functions."""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            # Extract identifier (could be user_id, ip, etc.)
            identifier = kwargs.get('user_id') or kwargs.get('ip') or 'anonymous'
            rate_key = f"rate_limit:{func.__name__}:{identifier}"
            
            rate_check = await redis_service.check_rate_limit(rate_key, limit, window)
            
            if not rate_check["allowed"]:
                raise Exception(f"Rate limit exceeded. Try again in {rate_check['reset_time']} seconds.")
            
            return await func(*args, **kwargs)
        return wrapper
    return decorator
