"""
Core configuration management using OOP principles.
"""
import os
from typing import List, Optional
from dotenv import load_dotenv


class DatabaseConfig:
    """Database configuration class."""
    
    def __init__(self):
        # PostgreSQL Database URL (e.g., AWS RDS endpoint)
        self.database_url = os.getenv("DATABASE_URL")
        if not self.database_url:
            raise ValueError("DATABASE_URL environment variable is required for database connection")
        
        # Extract database name from URL for reference
        self.database_name = self._extract_database_name()
    
    def _extract_database_name(self) -> str:
        """Extract database name from PostgreSQL URL."""
        if "/" in self.database_url:
            return self.database_url.split("/")[-1].split("?")[0]
        return "order_receiver_dev"


class SecurityConfig:
    """Security configuration class."""
    
    def __init__(self):
        self.secret_key = os.getenv("SECRET_KEY")
        if not self.secret_key:
            raise ValueError("SECRET_KEY environment variable is required")
        
        self.jwt_lifetime_seconds = int(os.getenv("JWT_LIFETIME_SECONDS", "3600"))
        self.reset_password_token_secret = self.secret_key
        self.verification_token_secret = self.secret_key


class CORSConfig:
    """CORS configuration class."""
    
    def __init__(self):
        allowed_origins = os.getenv("ALLOWED_ORIGINS")
        self.origins = allowed_origins.split(",") if allowed_origins else [
            "http://localhost:3000",
            "http://127.0.0.1:3000", 
            "http://192.168.31.7:3000",
            # Flutter development origins
            "http://localhost:8080",
            "http://127.0.0.1:8080",
            "http://192.168.31.7:8080",
            "http://10.0.2.2:8000",  # Android emulator
            "*"  # Allow all origins for development (remove in production)
        ]
        self.allow_credentials = True
        self.allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
        self.allow_headers = [
            "Accept",
            "Accept-Language", 
            "Content-Language",
            "Content-Type",
            "Authorization"
        ]


class CentralizedPlatformConfig:
    """Centralized platform integration configuration."""
    
    def __init__(self):
        # Platform URL - will be updated when platform is deployed
        self.centralized_platform_url = os.getenv(
            "CENTRALIZED_PLATFORM_URL", 
            "https://api.example.com"  # Generic API endpoint
        )
        
        # API key for authenticating with the platform
        self.centralized_platform_api_key = os.getenv(
            "CENTRALIZED_PLATFORM_API_KEY",
            "your-platform-api-key"  # Default placeholder
        )
        
        # Webhook secret for verifying incoming webhooks from platform
        self.centralized_platform_webhook_secret = os.getenv(
            "CENTRALIZED_PLATFORM_WEBHOOK_SECRET",
            "webhook-secret"  # Default placeholder
        )
        
        # Platform app name
        self.platform_app_name = os.getenv(
            "PLATFORM_APP_NAME",
            "delivery-platform-central"  # Default app name
        )
        
        # Timeout for API calls to platform
        self.platform_timeout = int(os.getenv("PLATFORM_TIMEOUT", "10"))
        
        # Retry attempts for failed platform calls
        self.platform_retry_attempts = int(os.getenv("PLATFORM_RETRY_ATTEMPTS", "3"))


class AppConfig:
    """Main application configuration class."""
    
    def __init__(self):
        # Load environment variables
        dotenv_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 
            '.env'
        )
        load_dotenv(dotenv_path=dotenv_path)
        
        # Initialize configuration sections
        self.database = DatabaseConfig()
        self.security = SecurityConfig()
        self.cors = CORSConfig()
        self.centralized_platform = CentralizedPlatformConfig()
        
        # App settings
        self.title = "Order Receiver API"
        self.version = "1.0.0"
        self.debug = os.getenv("DEBUG", "False").lower() == "true"


# Global configuration instance
config = AppConfig()
