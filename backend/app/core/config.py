"""
Core configuration management using OOP principles.
"""
import os
from typing import List, Optional
from dotenv import load_dotenv


class DatabaseConfig:
    """Database configuration class."""
    
    def __init__(self):
        self.mongo_uri = os.getenv("MONGO_URI", "mongodb://localhost:27017/order_receiver")
        self.database_name = self._extract_database_name()
    
    def _extract_database_name(self) -> str:
        """Extract database name from MongoDB URI."""
        if "/" in self.mongo_uri:
            return self.mongo_uri.split("/")[-1]
        return "order_receiver"


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
        
        # App settings
        self.title = "Order Receiver API"
        self.version = "1.0.0"
        self.debug = os.getenv("DEBUG", "False").lower() == "true"


# Global configuration instance
config = AppConfig()
