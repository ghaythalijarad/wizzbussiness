"""
POS Settings Service for handling business POS integrations
"""
import asyncio
import aiohttp
import json
from datetime import datetime
from typing import Dict, Any, Optional, List
from beanie import PydanticObjectId

from ..models.pos_settings import (
    PosSettings, 
    BusinessPosSettings, 
    PosTestConnection, 
    PosConnectionResult,
    PosOrderSyncLog,
    PosSystemType
)
from ..models.business import Business
from ..models.order import Order


class PosSettingsService:
    """Service for managing POS settings and integrations"""
    
    @staticmethod
    async def get_business_pos_settings(business_id: PydanticObjectId) -> Optional[PosSettings]:
        """Get POS settings for a business"""
        try:
            business_settings = await BusinessPosSettings.find_one(
                BusinessPosSettings.business_id == business_id
            )
            return business_settings.settings if business_settings else None
        except Exception as e:
            print(f"Error getting POS settings: {e}")
            return None
    
    @staticmethod
    async def save_business_pos_settings(
        business_id: PydanticObjectId, 
        settings: PosSettings
    ) -> bool:
        """Save or update POS settings for a business"""
        try:
            # Check if settings already exist
            existing = await BusinessPosSettings.find_one(
                BusinessPosSettings.business_id == business_id
            )
            
            if existing:
                # Update existing settings
                existing.update_settings(settings)
                await existing.save()
            else:
                # Create new settings
                new_settings = BusinessPosSettings(
                    business_id=business_id,
                    settings=settings
                )
                await new_settings.insert()
            
            return True
        except Exception as e:
            print(f"Error saving POS settings: {e}")
            return False
    
    @staticmethod
    async def delete_business_pos_settings(business_id: PydanticObjectId) -> bool:
        """Delete POS settings for a business"""
        try:
            existing = await BusinessPosSettings.find_one(
                BusinessPosSettings.business_id == business_id
            )
            if existing:
                await existing.delete()
                return True
            return False
        except Exception as e:
            print(f"Error deleting POS settings: {e}")
            return False
    
    @staticmethod
    async def test_pos_connection(test_config: PosTestConnection) -> PosConnectionResult:
        """Test connection to POS system"""
        start_time = datetime.utcnow()
        
        try:
            # Build test request based on POS system type
            test_url, headers, payload = PosSettingsService._build_test_request(test_config)
            
            async with aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=test_config.timeout_seconds)
            ) as session:
                async with session.get(test_url, headers=headers) as response:
                    end_time = datetime.utcnow()
                    response_time = int((end_time - start_time).total_seconds() * 1000)
                    
                    if response.status < 400:
                        # Parse response for system info
                        try:
                            response_data = await response.json()
                            system_info = PosSettingsService._extract_system_info(
                                test_config.system_type, 
                                response_data
                            )
                        except:
                            system_info = {"status": "connected"}
                        
                        return PosConnectionResult(
                            success=True,
                            message="Connection successful",
                            response_time_ms=response_time,
                            system_info=system_info
                        )
                    else:
                        error_text = await response.text()
                        return PosConnectionResult(
                            success=False,
                            message=f"Connection failed: HTTP {response.status}",
                            response_time_ms=response_time,
                            error_details=error_text
                        )
                        
        except asyncio.TimeoutError:
            return PosConnectionResult(
                success=False,
                message="Connection timeout",
                error_details="Request timed out"
            )
        except Exception as e:
            return PosConnectionResult(
                success=False,
                message="Connection error",
                error_details=str(e)
            )
    
    @staticmethod
    def _build_test_request(config: PosTestConnection) -> tuple[str, Dict[str, str], Optional[Dict]]:
        """Build test request URL, headers, and payload for each POS system"""
        headers = {"User-Agent": "Wizz-Business-App/1.0"}
        
        if config.system_type == PosSystemType.SQUARE:
            url = f"{config.api_endpoint}/v2/locations"
            headers.update({
                "Authorization": f"Bearer {config.access_token}",
                "Square-Version": "2023-10-18"
            })
            
        elif config.system_type == PosSystemType.TOAST:
            url = f"{config.api_endpoint}/restaurants"
            headers.update({
                "Authorization": f"Bearer {config.access_token}",
                "Toast-Restaurant-External-ID": config.location_id or ""
            })
            
        elif config.system_type == PosSystemType.CLOVER:
            url = f"{config.api_endpoint}/v3/merchants/{config.location_id}"
            headers.update({
                "Authorization": f"Bearer {config.access_token}"
            })
            
        elif config.system_type == PosSystemType.SHOPIFY_POS:
            url = f"{config.api_endpoint}/admin/api/2023-10/locations.json"
            headers.update({
                "X-Shopify-Access-Token": config.access_token or ""
            })
            
        else:  # Generic API
            url = f"{config.api_endpoint}/health"
            headers.update({
                "Authorization": f"Bearer {config.api_key}",
                "X-API-Key": config.api_key
            })
        
        return url, headers, None
    
    @staticmethod
    def _extract_system_info(system_type: PosSystemType, response_data: Dict) -> Dict[str, Any]:
        """Extract useful system information from API response"""
        info = {"system_type": system_type.value}
        
        try:
            if system_type == PosSystemType.SQUARE:
                locations = response_data.get("locations", [])
                info["locations_count"] = len(locations)
                if locations:
                    info["primary_location"] = locations[0].get("name", "Unknown")
                    
            elif system_type == PosSystemType.TOAST:
                restaurants = response_data.get("restaurants", [])
                info["restaurants_count"] = len(restaurants)
                if restaurants:
                    info["restaurant_name"] = restaurants[0].get("name", "Unknown")
                    
            elif system_type == PosSystemType.CLOVER:
                info["merchant_name"] = response_data.get("name", "Unknown")
                info["merchant_id"] = response_data.get("id", "Unknown")
                
            elif system_type == PosSystemType.SHOPIFY_POS:
                locations = response_data.get("locations", [])
                info["locations_count"] = len(locations)
                if locations:
                    info["primary_location"] = locations[0].get("name", "Unknown")
                    
            else:  # Generic API
                info["status"] = response_data.get("status", "unknown")
                info["version"] = response_data.get("version", "unknown")
                
        except Exception as e:
            info["extraction_error"] = str(e)
        
        return info
    
    @staticmethod
    async def send_order_to_pos(
        business_id: PydanticObjectId, 
        order: Order
    ) -> bool:
        """Send order to configured POS system"""
        try:
            # Get POS settings
            pos_settings = await PosSettingsService.get_business_pos_settings(business_id)
            if not pos_settings or not pos_settings.enabled:
                return False
            
            # Create sync log entry
            sync_log = PosOrderSyncLog(
                business_id=business_id,
                order_id=str(order.id),
                pos_system_type=pos_settings.system_type,
                sync_status="pending"
            )
            await sync_log.insert()
            
            # Format order data for POS system
            order_data = PosSettingsService._format_order_for_pos(order, pos_settings)
            
            # Send to POS system
            success, pos_order_id, error_msg = await PosSettingsService._send_to_pos_system(
                pos_settings, order_data
            )
            
            # Update sync log
            sync_log.sync_status = "success" if success else "failed"
            sync_log.pos_order_id = pos_order_id
            sync_log.error_message = error_msg
            await sync_log.save()
            
            return success
            
        except Exception as e:
            print(f"Error sending order to POS: {e}")
            return False
    
    @staticmethod
    def _format_order_for_pos(order: Order, settings: PosSettings) -> Dict[str, Any]:
        """Format order data according to POS system requirements"""
        base_data = {
            "id": str(order.id),
            "order_number": order.order_number,
            "customer_name": order.customer_name,
            "customer_phone": order.customer_phone,
            "customer_email": order.customer_email,
            "items": [
                {
                    "name": item.name,
                    "price": item.price,
                    "quantity": item.quantity,
                    "special_instructions": item.special_instructions
                }
                for item in order.items
            ],
            "total_amount": order.payment_info.total if order.payment_info else 0,
            "order_time": order.created_at.isoformat(),
            "delivery_type": order.delivery_type,
            "notes": order.special_instructions
        }
        
        # Add delivery address if applicable
        if order.delivery_address:
            base_data["delivery_address"] = {
                "street": order.delivery_address.street,
                "city": order.delivery_address.city,
                "state": order.delivery_address.state,
                "zip_code": order.delivery_address.zip_code
            }
        
        return base_data
    
    @staticmethod
    async def _send_to_pos_system(
        settings: PosSettings, 
        order_data: Dict[str, Any]
    ) -> tuple[bool, Optional[str], Optional[str]]:
        """Send order data to specific POS system"""
        try:
            url = f"{settings.api_endpoint}/orders"
            headers = {"Content-Type": "application/json"}
            
            # Add authentication headers
            if settings.system_type == PosSystemType.SQUARE:
                headers["Authorization"] = f"Bearer {settings.access_token}"
                headers["Square-Version"] = "2023-10-18"
                # Format for Square API
                payload = PosSettingsService._format_for_square(order_data, settings)
                
            elif settings.system_type == PosSystemType.TOAST:
                headers["Authorization"] = f"Bearer {settings.access_token}"
                headers["Toast-Restaurant-External-ID"] = settings.location_id or ""
                # Format for Toast API  
                payload = PosSettingsService._format_for_toast(order_data, settings)
                
            elif settings.system_type == PosSystemType.CLOVER:
                headers["Authorization"] = f"Bearer {settings.access_token}"
                # Format for Clover API
                payload = PosSettingsService._format_for_clover(order_data, settings)
                
            elif settings.system_type == PosSystemType.SHOPIFY_POS:
                headers["X-Shopify-Access-Token"] = settings.access_token or ""
                # Format for Shopify API
                payload = PosSettingsService._format_for_shopify(order_data, settings)
                
            else:  # Generic API
                headers["Authorization"] = f"Bearer {settings.api_key}"
                headers["X-API-Key"] = settings.api_key
                payload = order_data
            
            async with aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=settings.timeout_seconds)
            ) as session:
                async with session.post(url, headers=headers, json=payload) as response:
                    if response.status < 400:
                        response_data = await response.json()
                        pos_order_id = PosSettingsService._extract_pos_order_id(
                            settings.system_type, response_data
                        )
                        return True, pos_order_id, None
                    else:
                        error_text = await response.text()
                        return False, None, f"HTTP {response.status}: {error_text}"
                        
        except Exception as e:
            return False, None, str(e)
    
    @staticmethod
    def _format_for_square(order_data: Dict, settings: PosSettings) -> Dict:
        """Format order for Square POS API"""
        return {
            "location_id": settings.location_id,
            "order": {
                "state": "OPEN",
                "line_items": [
                    {
                        "name": item["name"],
                        "quantity": str(item["quantity"]),
                        "base_price_money": {
                            "amount": int(item["price"] * 100),  # Convert to cents
                            "currency": "KWD"
                        }
                    }
                    for item in order_data["items"]
                ]
            }
        }
    
    @staticmethod
    def _format_for_toast(order_data: Dict, settings: PosSettings) -> Dict:
        """Format order for Toast POS API"""
        return {
            "restaurantExternalId": settings.location_id,
            "order": {
                "externalId": order_data["id"],
                "customer": {
                    "firstName": order_data["customer_name"].split(" ")[0] if order_data["customer_name"] else "",
                    "lastName": " ".join(order_data["customer_name"].split(" ")[1:]) if order_data["customer_name"] else "",
                    "phone": order_data["customer_phone"]
                },
                "selections": [
                    {
                        "itemName": item["name"],
                        "quantity": item["quantity"],
                        "unitPrice": item["price"]
                    }
                    for item in order_data["items"]
                ]
            }
        }
    
    @staticmethod
    def _format_for_clover(order_data: Dict, settings: PosSettings) -> Dict:
        """Format order for Clover POS API"""
        return {
            "state": "open",
            "title": f"Order {order_data['order_number']}",
            "note": order_data.get("notes", ""),
            "lineItems": [
                {
                    "name": item["name"],
                    "price": int(item["price"] * 100),  # Convert to cents
                    "quantity": item["quantity"]
                }
                for item in order_data["items"]
            ]
        }
    
    @staticmethod
    def _format_for_shopify(order_data: Dict, settings: PosSettings) -> Dict:
        """Format order for Shopify POS API"""
        return {
            "order": {
                "line_items": [
                    {
                        "title": item["name"],
                        "quantity": item["quantity"],
                        "price": str(item["price"])
                    }
                    for item in order_data["items"]
                ],
                "customer": {
                    "first_name": order_data["customer_name"].split(" ")[0] if order_data["customer_name"] else "",
                    "last_name": " ".join(order_data["customer_name"].split(" ")[1:]) if order_data["customer_name"] else "",
                    "phone": order_data["customer_phone"]
                }
            }
        }
    
    @staticmethod
    def _extract_pos_order_id(system_type: PosSystemType, response_data: Dict) -> Optional[str]:
        """Extract POS order ID from API response"""
        try:
            if system_type == PosSystemType.SQUARE:
                return response_data.get("order", {}).get("id")
            elif system_type == PosSystemType.TOAST:
                return response_data.get("order", {}).get("guid")
            elif system_type == PosSystemType.CLOVER:
                return response_data.get("id")
            elif system_type == PosSystemType.SHOPIFY_POS:
                return response_data.get("order", {}).get("id")
            else:
                return response_data.get("id") or response_data.get("order_id")
        except:
            return None
    
    @staticmethod
    async def get_sync_logs(
        business_id: PydanticObjectId, 
        limit: int = 100
    ) -> List[PosOrderSyncLog]:
        """Get POS sync logs for a business"""
        return await PosOrderSyncLog.find(
            PosOrderSyncLog.business_id == business_id
        ).sort(-PosOrderSyncLog.sync_timestamp).limit(limit).to_list()
    
    @staticmethod
    async def update_connection_status(
        business_id: PydanticObjectId,
        status: bool,
        error_message: Optional[str] = None
    ):
        """Update connection status after test"""
        settings = await PosSettingsService.get_business_pos_settings(business_id)
        if settings:
            settings.last_connection_test = datetime.utcnow()
            settings.last_connection_status = status
            settings.last_error_message = error_message
            await PosSettingsService.save_business_pos_settings(business_id, settings)
