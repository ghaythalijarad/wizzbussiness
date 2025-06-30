# Production-Level Backend Architecture Roadmap
# Real-time Notifications, Performance, Security & Stability

## 🎯 Current State Analysis

**✅ What You Have:**
- Basic HTTP polling notification system
- Cloud deployment ready
- MongoDB integration (with connection issues)
- FastAPI framework
- Dual notification systems (WebSocket + HTTP polling)

**Three separate front-end clients:**

- Merchant App (receives new orders, updates status)
- Customer App (places orders, tracks status)
- Driver App (deliveries and status updates)

**Central Platform Service:**

- Independent microservice that consumes order events, assigns drivers, and notifies the Driver App

**🚀 Production Goals:**

- Handle 10,000+ concurrent users
- Real-time notifications (<100ms latency)
- 99.9% uptime
- Enterprise security
- Auto-scaling capabilities
- Performance monitoring

---

## 📋 PHASE 1: Infrastructure & Architecture (Weeks 1-2)

### 1.1 Cloud Infrastructure Migration

**Current POC (Cloud):**

Cloud + Redis can host a single FastAPI backend (Order Orchestrator + Notification Service) that serves all three clients plus a lightweight Central Platform API.

**Long-term (AWS/GCP):**

- Docker Compose (local or ECS):

```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  app:
    build: .
    environment:
      - ENVIRONMENT=production
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=${MONGODB_URI}
    depends_on:
      - redis
      - mongodb

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
```

- Kubernetes (EKS/GKE):
  scale each service (Orchestrator, Notifications, Central Platform) independently with Redis (ElastiCache/MemoryStore) and MongoDB Atlas.

---

### 1.2 Container Orchestration

**Kubernetes Deployment:**

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-receiver-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: order-receiver
  template:
    spec:
      containers:
      - name: backend
        image: your-registry/order-receiver:latest
        ports:
        - containerPort: 8000
        env:
        - name: REDIS_URL
          value: "redis://redis-service:6379"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

### 1.3 Database Optimization

**MongoDB Atlas Production Setup:**

```python
# backend/app/core/database_production.py
import motor.motor_asyncio
from pymongo import MongoClient
from pymongo.read_preferences import ReadPreference
import asyncio

class ProductionDatabaseManager:
    def __init__(self):
        self.read_client = None
        self.write_client = None
        self.connection_pool_size = 50
    
    async def connect(self):
        """Production MongoDB connection with read/write splitting."""
        # Write operations - Primary
        self.write_client = motor.motor_asyncio.AsyncIOMotorClient(
            config.mongodb_write_uri,
            maxPoolSize=self.connection_pool_size,
            minPoolSize=10,
            maxIdleTimeMS=30000,
            waitQueueTimeoutMS=5000,
            w="majority",
            readPreference=ReadPreference.PRIMARY
        )
        
        # Read operations - Secondary preferred
        self.read_client = motor.motor_asyncio.AsyncIOMotorClient(
            config.mongodb_read_uri,
            maxPoolSize=self.connection_pool_size,
            minPoolSize=10,
            readPreference=ReadPreference.SECONDARY_PREFERRED
        )
        
    def get_write_db(self):
        return self.write_client.get_default_database()
    
    def get_read_db(self):
        return self.read_client.get_default_database()
```

---

## 📋 PHASE 2: Real-time Notification System (Weeks 2-3)

### 2.1 Redis-Based Real-time Architecture

**High-Performance Notification Service:**

```python
# backend/app/services/realtime_notification_service.py
import redis.asyncio as redis
import json
import asyncio
from typing import List, Dict, Any
from fastapi import WebSocket
import logging

class RealtimeNotificationService:
    def __init__(self):
        self.redis_client = None
        self.active_connections: Dict[str, List[WebSocket]] = {}
        self.pub_sub = None
        
    async def initialize(self):
        """Initialize Redis connection and pub/sub."""
        self.redis_client = redis.Redis.from_url(
            config.redis_url,
            encoding="utf-8",
            decode_responses=True,
            max_connections=20
        )
        self.pub_sub = self.redis_client.pubsub()
        await self.pub_sub.subscribe("notifications:*")
        
        # Start background listener
        asyncio.create_task(self._listen_for_notifications())
    
    async def connect_websocket(self, websocket: WebSocket, business_id: str):
        """Connect a WebSocket for real-time notifications."""
        await websocket.accept()
        
        if business_id not in self.active_connections:
            self.active_connections[business_id] = []
        
        self.active_connections[business_id].append(websocket)
        
        try:
            while True:
                # Keep connection alive
                await websocket.receive_text()
        except Exception as e:
            logging.info(f"WebSocket disconnected: {e}")
        finally:
            self.active_connections[business_id].remove(websocket)
    
    async def send_notification(self, business_id: str, notification: Dict[str, Any]):
        """Send notification via Redis pub/sub."""
        channel = f"notifications:{business_id}"
        await self.redis_client.publish(channel, json.dumps(notification))
        
        # Also store in MongoDB for persistence
        await self._store_notification(business_id, notification)
    
    async def _listen_for_notifications(self):
        """Background task to listen for Redis notifications."""
        async for message in self.pub_sub.listen():
            if message["type"] == "message":
                channel = message["channel"]
                business_id = channel.split(":")[-1]
                data = json.loads(message["data"])
                
                # Send to all connected WebSockets for this business
                if business_id in self.active_connections:
                    disconnected = []
                    for websocket in self.active_connections[business_id]:
                        try:
                            await websocket.send_text(json.dumps(data))
                        except Exception:
                            disconnected.append(websocket)
                    
                    # Clean up disconnected sockets
                    for ws in disconnected:
                        self.active_connections[business_id].remove(ws)
    
    async def _store_notification(self, business_id: str, notification: Dict[str, Any]):
        """Store notification in MongoDB for persistence."""
        from ..models.notification import Notification
        
        notification_doc = Notification(
            business_id=business_id,
            type=notification["type"],
            title=notification["title"],
            message=notification["message"],
            data=notification.get("data", {}),
            priority=notification.get("priority", "NORMAL"),
            created_at=datetime.utcnow()
        )
        
        await notification_doc.insert()

# Global instance
realtime_service = RealtimeNotificationService()
```

### 2.2 WebSocket Controller with Connection Management

```python
# backend/app/controllers/websocket_controller.py
from fastapi import APIRouter, WebSocket, Depends, HTTPException
from ..services.auth_service import get_current_user_websocket
from ..services.realtime_notification_service import realtime_service

class WebSocketController:
    def __init__(self):
        self.router = APIRouter()
        self._setup_routes()
    
    def _setup_routes(self):
        @self.router.websocket("/ws/notifications/{business_id}")
        async def websocket_notifications(
            websocket: WebSocket,
            business_id: str,
            token: str = None
        ):
            """WebSocket endpoint for real-time notifications."""
            try:
                # Authenticate user
                user = await get_current_user_websocket(token)
                
                # Verify business access
                if not await self._verify_business_access(user, business_id):
                    await websocket.close(code=4003, reason="Access denied")
                    return
                
                # Connect to real-time service
                await realtime_service.connect_websocket(websocket, business_id)
                
            except Exception as e:
                await websocket.close(code=4000, reason=str(e))
    
    async def _verify_business_access(self, user, business_id: str) -> bool:
        """Verify user has access to business notifications."""
        from ..models.business import Business
        business = await Business.get(business_id)
        return business and business.owner_id == user.id

websocket_controller = WebSocketController()
```

### 2.3 Event-Driven Architecture

```python
# backend/app/services/event_service.py
from typing import Dict, Any, Callable, List
import asyncio
from enum import Enum

class EventType(Enum):
    ORDER_CREATED = "order_created"
    ORDER_UPDATED = "order_updated"
    ORDER_CANCELLED = "order_cancelled"
    PAYMENT_RECEIVED = "payment_received"

class EventService:
    def __init__(self):
        self.handlers: Dict[EventType, List[Callable]] = {}
    
    def subscribe(self, event_type: EventType, handler: Callable):
        """Subscribe to an event type."""
        if event_type not in self.handlers:
            self.handlers[event_type] = []
        self.handlers[event_type].append(handler)
    
    async def publish(self, event_type: EventType, data: Dict[str, Any]):
        """Publish an event to all subscribers."""
        if event_type in self.handlers:
            tasks = []
            for handler in self.handlers[event_type]:
                tasks.append(asyncio.create_task(handler(data)))
            
            if tasks:
                await asyncio.gather(*tasks, return_exceptions=True)

# Global event service
event_service = EventService()

# Event handlers for notifications
async def handle_order_created(data: Dict[str, Any]):
    """Handle new order notification."""
    notification = {
        "type": "NEW_ORDER",
        "title": "New Order Received",
        "message": f"Order #{data['order_id']} from {data['customer_name']}",
        "data": data,
        "priority": "HIGH"
    }
    
    await realtime_service.send_notification(
        data["business_id"], 
        notification
    )

# Register event handlers
event_service.subscribe(EventType.ORDER_CREATED, handle_order_created)
```

---

## 📋 PHASE 3: Performance Optimization (Weeks 3-4)

### 3.1 Caching Strategy

```python
# backend/app/services/cache_service.py
import redis.asyncio as redis
import json
import pickle
from typing import Any, Optional
from datetime import datetime, timedelta

class CacheService:
    def __init__(self):
        self.redis_client = None
        self.default_ttl = 3600  # 1 hour
    
    async def initialize(self):
        self.redis_client = redis.Redis.from_url(
            config.redis_url,
            encoding="utf-8",
            decode_responses=False  # For binary data
        )
    
    async def get(self, key: str) -> Optional[Any]:
        """Get cached value."""
        try:
            data = await self.redis_client.get(key)
            if data:
                return pickle.loads(data)
        except Exception as e:
            logging.error(f"Cache get error: {e}")
        return None
    
    async def set(self, key: str, value: Any, ttl: int = None) -> bool:
        """Set cached value."""
        try:
            ttl = ttl or self.default_ttl
            serialized = pickle.dumps(value)
            await self.redis_client.setex(key, ttl, serialized)
            return True
        except Exception as e:
            logging.error(f"Cache set error: {e}")
            return False
    
    async def delete(self, key: str) -> bool:
        """Delete cached value."""
        try:
            await self.redis_client.delete(key)
            return True
        except Exception as e:
            logging.error(f"Cache delete error: {e}")
            return False
    
    async def get_business_stats(self, business_id: str) -> Optional[Dict]:
        """Get cached business statistics."""
        return await self.get(f"business_stats:{business_id}")
    
    async def set_business_stats(self, business_id: str, stats: Dict):
        """Cache business statistics for 5 minutes."""
        await self.set(f"business_stats:{business_id}", stats, 300)

cache_service = CacheService()
```

### 3.2 Database Query Optimization

```python
# backend/app/services/optimized_order_service.py
from ..core.database_production import ProductionDatabaseManager
from ..services.cache_service import cache_service
from typing import List, Dict, Any
import asyncio

class OptimizedOrderService:
    def __init__(self):
        self.db = ProductionDatabaseManager()
    
    async def get_business_orders(
        self, 
        business_id: str, 
        page: int = 1, 
        limit: int = 20,
        status: str = None
    ) -> List[Dict[str, Any]]:
        """Get orders with caching and optimized queries."""
        
        cache_key = f"orders:{business_id}:{page}:{limit}:{status}"
        
        # Try cache first
        cached_orders = await cache_service.get(cache_key)
        if cached_orders:
            return cached_orders
        
        # Build query
        query = {"business_id": business_id}
        if status:
            query["status"] = status
        
        # Use read replica for queries
        db = self.db.get_read_db()
        
        # Optimized aggregation pipeline
        pipeline = [
            {"$match": query},
            {"$sort": {"created_at": -1}},
            {"$skip": (page - 1) * limit},
            {"$limit": limit},
            {
                "$lookup": {
                    "from": "customers",
                    "localField": "customer_id",
                    "foreignField": "_id",
                    "as": "customer"
                }
            },
            {"$unwind": "$customer"},
            {
                "$project": {
                    "_id": 1,
                    "order_number": 1,
                    "status": 1,
                    "total_amount": 1,
                    "created_at": 1,
                    "customer_name": "$customer.name",
                    "customer_phone": "$customer.phone"
                }
            }
        ]
        
        orders = await db.orders.aggregate(pipeline).to_list(length=limit)
        
        # Cache for 2 minutes
        await cache_service.set(cache_key, orders, 120)
        
        return orders
    
    async def get_dashboard_stats(self, business_id: str) -> Dict[str, Any]:
        """Get dashboard statistics with caching."""
        
        cached_stats = await cache_service.get_business_stats(business_id)
        if cached_stats:
            return cached_stats
        
        # Parallel queries for better performance
        db = self.db.get_read_db()
        
        today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        
        tasks = [
            db.orders.count_documents({
                "business_id": business_id,
                "created_at": {"$gte": today}
            }),
            db.orders.aggregate([
                {"$match": {"business_id": business_id, "created_at": {"$gte": today}}},
                {"$group": {"_id": None, "total": {"$sum": "$total_amount"}}}
            ]).to_list(1),
            db.orders.count_documents({
                "business_id": business_id,
                "status": "pending"
            })
        ]
        
        results = await asyncio.gather(*tasks)
        
        stats = {
            "today_orders": results[0],
            "today_revenue": results[1][0]["total"] if results[1] else 0,
            "pending_orders": results[2],
            "updated_at": datetime.utcnow().isoformat()
        }
        
        await cache_service.set_business_stats(business_id, stats)
        
        return stats
```

### 3.3 Connection Pooling & Rate Limiting

```python
# backend/app/core/rate_limiter.py
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import Request
import redis.asyncio as redis

class ProductionRateLimiter:
    def __init__(self):
        self.redis_client = None
        self.limiter = None
    
    async def initialize(self):
        self.redis_client = redis.Redis.from_url(config.redis_url)
        
        def rate_limit_key_func(request: Request):
            # Use user ID if authenticated, otherwise IP
            if hasattr(request.state, 'user'):
                return f"user:{request.state.user.id}"
            return f"ip:{get_remote_address(request)}"
        
        self.limiter = Limiter(
            key_func=rate_limit_key_func,
            storage_uri=config.redis_url
        )
    
    def get_limiter(self):
        return self.limiter

rate_limiter = ProductionRateLimiter()

# Usage in controllers
@rate_limiter.get_limiter().limit("100/minute")
async def get_orders(request: Request, ...):
    pass
```

---

## 📋 PHASE 4: Security Hardening (Weeks 4-5)

### 4.1 Enhanced Authentication & Authorization

```python
# backend/app/services/security_service.py
import jwt
from cryptography.fernet import Fernet
import bcrypt
import secrets
from typing import Optional, Dict, Any
import redis.asyncio as redis
from datetime import datetime, timedelta

class SecurityService:
    def __init__(self):
        self.redis_client = None
        self.fernet = Fernet(config.encryption_key.encode())
        self.failed_attempts = {}
    
    async def initialize(self):
        self.redis_client = redis.Redis.from_url(config.redis_url)
    
    async def create_secure_session(self, user_id: str, device_info: Dict) -> str:
        """Create secure session with device tracking."""
        session_id = secrets.token_urlsafe(32)
        
        session_data = {
            "user_id": user_id,
            "device_info": device_info,
            "created_at": datetime.utcnow().isoformat(),
            "last_activity": datetime.utcnow().isoformat()
        }
        
        # Store session in Redis with 24-hour expiry
        await self.redis_client.setex(
            f"session:{session_id}",
            86400,
            json.dumps(session_data)
        )
        
        return session_id
    
    async def validate_session(self, session_id: str) -> Optional[Dict]:
        """Validate and refresh session."""
        session_data = await self.redis_client.get(f"session:{session_id}")
        if not session_data:
            return None
        
        data = json.loads(session_data)
        
        # Update last activity
        data["last_activity"] = datetime.utcnow().isoformat()
        await self.redis_client.setex(
            f"session:{session_id}",
            86400,
            json.dumps(data)
        )
        
        return data
    
    async def check_rate_limit(self, identifier: str, max_attempts: int = 5) -> bool:
        """Check if identifier has exceeded rate limit."""
        key = f"rate_limit:{identifier}"
        current = await self.redis_client.get(key)
        
        if current and int(current) >= max_attempts:
            return False
        
        # Increment counter
        await self.redis_client.incr(key)
        await self.redis_client.expire(key, 3600)  # 1 hour
        
        return True
    
    def encrypt_sensitive_data(self, data: str) -> str:
        """Encrypt sensitive data."""
        return self.fernet.encrypt(data.encode()).decode()
    
    def decrypt_sensitive_data(self, encrypted_data: str) -> str:
        """Decrypt sensitive data."""
        return self.fernet.decrypt(encrypted_data.encode()).decode()

security_service = SecurityService()
```

### 4.2 API Security Middleware

```python
# backend/app/middleware/security_middleware.py
from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
import time
import logging
import json

class SecurityMiddleware(BaseHTTPMiddleware):
    def __init__(self, app):
        super().__init__(app)
        self.suspicious_patterns = [
            "script>", "javascript:", "onload=", "onerror=",
            "../../", "../", "eval(", "exec(",
            "union select", "drop table", "delete from"
        ]
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        # Security checks
        await self._check_request_security(request)
        
        # Add security headers
        response = await call_next(request)
        
        # Security headers
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Content-Security-Policy"] = "default-src 'self'"
        
        # Request logging
        process_time = time.time() - start_time
        logging.info(f"{request.method} {request.url} - {response.status_code} - {process_time:.3f}s")
        
        return response
    
    async def _check_request_security(self, request: Request):
        """Perform security checks on incoming requests."""
        
        # Check for suspicious patterns in URL
        url_str = str(request.url).lower()
        for pattern in self.suspicious_patterns:
            if pattern in url_str:
                logging.warning(f"Suspicious URL pattern detected: {url_str}")
                raise HTTPException(status_code=400, detail="Invalid request")
        
        # Check content length
        content_length = request.headers.get("content-length")
        if content_length and int(content_length) > 10 * 1024 * 1024:  # 10MB
            raise HTTPException(status_code=413, detail="Request too large")
        
        # Check for common attack headers
        user_agent = request.headers.get("user-agent", "").lower()
        if not user_agent or len(user_agent) < 10:
            logging.warning(f"Suspicious user agent: {user_agent}")
```

---

## 📋 PHASE 5: Monitoring & Observability (Week 5)

### 5.1 Comprehensive Monitoring

```python
# backend/app/services/monitoring_service.py
import time
import psutil
import asyncio
from typing import Dict, Any
from prometheus_client import Counter, Histogram, Gauge, generate_latest
import logging

class MonitoringService:
    def __init__(self):
        # Prometheus metrics
        self.request_count = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
        self.request_duration = Histogram('http_request_duration_seconds', 'HTTP request duration')
        self.active_connections = Gauge('websocket_connections_active', 'Active WebSocket connections')
        self.notification_count = Counter('notifications_sent_total', 'Total notifications sent', ['type'])
        self.database_operations = Counter('database_operations_total', 'Database operations', ['operation', 'collection'])
        
        # System metrics
        self.cpu_usage = Gauge('system_cpu_usage_percent', 'CPU usage percentage')
        self.memory_usage = Gauge('system_memory_usage_bytes', 'Memory usage in bytes')
        self.disk_usage = Gauge('system_disk_usage_percent', 'Disk usage percentage')
        
        # Custom business metrics
        self.orders_processed = Counter('orders_processed_total', 'Total orders processed', ['status'])
        self.revenue_total = Gauge('revenue_total_amount', 'Total revenue amount')
        
        # Start background monitoring
        asyncio.create_task(self._collect_system_metrics())
    
    async def _collect_system_metrics(self):
        """Collect system metrics every 30 seconds."""
        while True:
            try:
                # CPU usage
                cpu_percent = psutil.cpu_percent(interval=1)
                self.cpu_usage.set(cpu_percent)
                
                # Memory usage
                memory = psutil.virtual_memory()
                self.memory_usage.set(memory.used)
                
                # Disk usage
                disk = psutil.disk_usage('/')
                self.disk_usage.set(disk.percent)
                
                await asyncio.sleep(30)
            except Exception as e:
                logging.error(f"Error collecting system metrics: {e}")
                await asyncio.sleep(30)
    
    def record_request(self, method: str, endpoint: str, status_code: int, duration: float):
        """Record HTTP request metrics."""
        self.request_count.labels(method=method, endpoint=endpoint, status=status_code).inc()
        self.request_duration.observe(duration)
    
    def record_notification(self, notification_type: str):
        """Record notification metrics."""
        self.notification_count.labels(type=notification_type).inc()
    
    def record_database_operation(self, operation: str, collection: str):
        """Record database operation metrics."""
        self.database_operations.labels(operation=operation, collection=collection).inc()
    
    def get_metrics(self) -> str:
        """Get Prometheus metrics."""
        return generate_latest()

monitoring_service = MonitoringService()
```

### 5.2 Health Check System

```python
# backend/app/services/health_service.py
import asyncio
import time
from typing import Dict, Any, List
from enum import Enum

class HealthStatus(Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"

class HealthCheck:
    def __init__(self, name: str, check_func, timeout: int = 5):
        self.name = name
        self.check_func = check_func
        self.timeout = timeout
        self.last_check = None
        self.last_status = None
        self.last_error = None

class HealthService:
    def __init__(self):
        self.checks: List[HealthCheck] = []
        self.overall_status = HealthStatus.HEALTHY
        
    def register_check(self, name: str, check_func, timeout: int = 5):
        """Register a health check."""
        self.checks.append(HealthCheck(name, check_func, timeout))
    
    async def run_checks(self) -> Dict[str, Any]:
        """Run all health checks."""
        results = {}
        unhealthy_count = 0
        
        for check in self.checks:
            start_time = time.time()
            try:
                # Run check with timeout
                result = await asyncio.wait_for(
                    check.check_func(),
                    timeout=check.timeout
                )
                
                check.last_status = HealthStatus.HEALTHY
                check.last_error = None
                
                results[check.name] = {
                    "status": HealthStatus.HEALTHY.value,
                    "response_time": round(time.time() - start_time, 3),
                    "details": result
                }
                
            except asyncio.TimeoutError:
                check.last_status = HealthStatus.UNHEALTHY
                check.last_error = "Timeout"
                unhealthy_count += 1
                
                results[check.name] = {
                    "status": HealthStatus.UNHEALTHY.value,
                    "response_time": check.timeout,
                    "error": "Health check timeout"
                }
                
            except Exception as e:
                check.last_status = HealthStatus.UNHEALTHY
                check.last_error = str(e)
                unhealthy_count += 1
                
                results[check.name] = {
                    "status": HealthStatus.UNHEALTHY.value,
                    "response_time": round(time.time() - start_time, 3),
                    "error": str(e)
                }
            
            check.last_check = time.time()
        
        # Determine overall status
        if unhealthy_count == 0:
            self.overall_status = HealthStatus.HEALTHY
        elif unhealthy_count < len(self.checks) / 2:
            self.overall_status = HealthStatus.DEGRADED
        else:
            self.overall_status = HealthStatus.UNHEALTHY
        
        return {
            "status": self.overall_status.value,
            "timestamp": time.time(),
            "checks": results
        }

# Health check functions
async def check_database():
    """Check database connectivity."""
    try:
        db = db_manager.get_read_db()
        await db.command("ping")
        return {"connection": "ok"}
    except Exception as e:
        raise Exception(f"Database unreachable: {e}")

async def check_redis():
    """Check Redis connectivity."""
    try:
        await cache_service.redis_client.ping()
        return {"connection": "ok"}
    except Exception as e:
        raise Exception(f"Redis unreachable: {e}")

async def check_external_apis():
    """Check external API dependencies."""
    # Add your external API checks here
    return {"apis": "ok"}

# Initialize health service
health_service = HealthService()
health_service.register_check("database", check_database)
health_service.register_check("redis", check_redis)
health_service.register_check("external_apis", check_external_apis)
```

---

## 📋 PHASE 6: Auto-scaling & Load Balancing (Week 6)

### 6.1 Kubernetes Auto-scaling

```yaml
# k8s/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-receiver-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-receiver-backend
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 25
        periodSeconds: 60
```

### 6.2 Load Balancer Configuration

```nginx
# nginx.conf
upstream backend {
    least_conn;
    server backend-1:8000 max_fails=3 fail_timeout=30s;
    server backend-2:8000 max_fails=3 fail_timeout=30s;
    server backend-3:8000 max_fails=3 fail_timeout=30s;
}

upstream websocket {
    ip_hash;  # Sticky sessions for WebSocket
    server backend-1:8000;
    server backend-2:8000;
    server backend-3:8000;
}

server {
    listen 80;
    listen 443 ssl http2;
    
    # SSL configuration
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # WebSocket location
    location /ws/ {
        proxy_pass http://websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # API endpoints
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # Rate limiting
        limit_req zone=api burst=20 nodelay;
    }
    
    # Rate limiting zones
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
}
```

---

## 📋 DEPLOYMENT CHECKLIST

### 🚀 Production Deployment Steps

1. **Infrastructure Setup:**
   ```bash
   # Set up Kubernetes cluster
   kubectl apply -f k8s/namespace.yaml
   kubectl apply -f k8s/configmap.yaml
   kubectl apply -f k8s/secrets.yaml
   kubectl apply -f k8s/deployment.yaml
   kubectl apply -f k8s/service.yaml
   kubectl apply -f k8s/hpa.yaml
   ```

2. **Database Setup:**
   ```bash
   # MongoDB Atlas production cluster
   # Redis cluster setup
   # Database migrations
   ```

3. **Monitoring Setup:**
   ```bash
   # Prometheus + Grafana
   kubectl apply -f monitoring/prometheus.yaml
   kubectl apply -f monitoring/grafana.yaml
   ```

4. **Security Setup:**
   ```bash
   # SSL certificates
   # WAF configuration
   # VPN setup for admin access
   ```

### 📊 Performance Targets

- **Latency:** < 100ms for 95% of requests
- **Throughput:** 10,000+ requests/second
- **Availability:** 99.9% uptime
- **Scalability:** Auto-scale 3-20 pods based on load
- **Real-time:** < 50ms notification delivery

### 🔒 Security Measures

- **Authentication:** JWT + Redis sessions
- **Authorization:** Role-based access control
- **Rate Limiting:** Per-user and per-IP limits
- **Encryption:** TLS 1.3, data encryption at rest
- **Monitoring:** Real-time security alerts

---

This roadmap will transform your current cloud deployment into a production-grade, enterprise-level system capable of handling real-time notifications for thousands of concurrent users with high performance, security, and reliability.

Would you like me to start implementing any specific phase or provide more details on particular aspects?
