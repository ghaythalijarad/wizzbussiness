"""
Integration tests for the Order Receiver API
These tests run against the deployed API endpoints
"""

import pytest
import requests
import json
import os
from typing import Dict, Any


class TestAPIIntegration:
    """Integration tests for the API endpoints"""
    
    def setup_class(self):
        """Setup test class with API URL and test data"""
        self.api_url = os.getenv('API_URL', 'http://localhost:3000')
        self.test_user_email = f"test_integration_{os.getpid()}@example.com"
        self.test_user_password = "TestPassword123!"
        self.auth_token = None
        
    def test_health_check(self):
        """Test the health check endpoint"""
        response = requests.get(f"{self.api_url}/health")
        assert response.status_code == 200
        data = response.json()
        assert data.get('status') == 'healthy'
        
    def test_register_user(self):
        """Test user registration"""
        payload = {
            "email": self.test_user_email,
            "password": self.test_user_password,
            "username": f"testuser{os.getpid()}"
        }
        
        response = requests.post(f"{self.api_url}/auth/register", json=payload)
        assert response.status_code in [200, 201]
        
    def test_login_user(self):
        """Test user login and get auth token"""
        payload = {
            "email": self.test_user_email,
            "password": self.test_user_password
        }
        
        response = requests.post(f"{self.api_url}/auth/login", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert 'token' in data
        self.auth_token = data['token']
        
    def test_protected_endpoint(self):
        """Test a protected endpoint with authentication"""
        if not self.auth_token:
            self.test_login_user()
            
        headers = {"Authorization": f"Bearer {self.auth_token}"}
        response = requests.get(f"{self.api_url}/api/orders", headers=headers)
        assert response.status_code in [200, 404]  # 404 is acceptable if no orders exist
        
    def test_create_order(self):
        """Test creating a new order"""
        if not self.auth_token:
            self.test_login_user()
            
        headers = {"Authorization": f"Bearer {self.auth_token}"}
        payload = {
            "customer_name": "Integration Test Customer",
            "items": [
                {
                    "name": "Test Item",
                    "quantity": 2,
                    "price": 15.99
                }
            ],
            "total_amount": 31.98
        }
        
        response = requests.post(f"{self.api_url}/api/orders", json=payload, headers=headers)
        assert response.status_code in [200, 201]
        
    def test_analytics_endpoint(self):
        """Test analytics endpoint"""
        if not self.auth_token:
            self.test_login_user()
            
        headers = {"Authorization": f"Bearer {self.auth_token}"}
        response = requests.get(f"{self.api_url}/api/analytics/summary", headers=headers)
        assert response.status_code == 200


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
