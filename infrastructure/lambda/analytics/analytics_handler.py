"""
Analytics and reporting Lambda function for Order Receiver.
Handles business analytics, performance metrics, and reporting.
"""
import json
import os
import logging
from typing import Dict, Any, Optional, List
import boto3
from botocore.exceptions import ClientError
from datetime import datetime, timezone, timedelta
from decimal import Decimal
import statistics

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize services
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'order-receiver-data')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """Main analytics handler"""
    
    try:
        http_method = event.get('httpMethod', '')
        resource_path = event.get('resource', '')
        path_params = event.get('pathParameters') or {}
        query_params = event.get('queryStringParameters') or {}
        
        logger.info(f"Analytics: {http_method} {resource_path}")
        
        # Route analytics requests
        if resource_path == '/analytics/{business_id}/daily' and http_method == 'GET':
            return handle_daily_analytics(path_params, query_params)
        
        elif resource_path == '/analytics/{business_id}/weekly' and http_method == 'GET':
            return handle_weekly_analytics(path_params, query_params)
        
        elif resource_path == '/analytics/{business_id}/monthly' and http_method == 'GET':
            return handle_monthly_analytics(path_params, query_params)
        
        elif resource_path == '/analytics/{business_id}/orders-summary' and http_method == 'GET':
            return handle_orders_summary(path_params, query_params)
        
        elif resource_path == '/analytics/{business_id}/performance' and http_method == 'GET':
            return handle_performance_metrics(path_params, query_params)
        
        elif resource_path == '/analytics/{business_id}/trends' and http_method == 'GET':
            return handle_trends_analysis(path_params, query_params)
        
        elif resource_path == '/analytics/system/overview' and http_method == 'GET':
            return handle_system_overview(query_params)
        
        else:
            return create_response(404, {'error': 'Analytics endpoint not found'})
    
    except Exception as e:
        logger.error(f"Analytics error: {str(e)}")
        return create_response(500, {'error': 'Internal server error'})

def handle_daily_analytics(path_params: Dict[str, Any], query_params: Dict[str, Any]) -> Dict[str, Any]:
    """Get daily analytics for a business"""
    try:
        business_id = path_params.get('business_id')
        if not business_id:
            return create_response(400, {'error': 'Missing business_id'})
        
        # Parse date parameter or use today
        date_str = query_params.get('date')
        if date_str:
            target_date = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
        else:
            target_date = datetime.now(timezone.utc)
        
        # Get start and end of day
        start_of_day = target_date.replace(hour=0, minute=0, second=0, microsecond=0)
        end_of_day = start_of_day + timedelta(days=1)
        
        # Query orders for the day
        orders = get_orders_in_date_range(business_id, start_of_day, end_of_day)
        
        # Calculate metrics
        analytics = calculate_daily_metrics(orders, target_date)
        
        logger.info(f"Daily analytics calculated for business {business_id} on {target_date.date()}")
        
        return create_response(200, analytics)
        
    except Exception as e:
        logger.error(f"Daily analytics error: {str(e)}")
        return create_response(500, {'error': 'Failed to calculate daily analytics'})

def handle_weekly_analytics(path_params: Dict[str, Any], query_params: Dict[str, Any]) -> Dict[str, Any]:
    """Get weekly analytics for a business"""
    try:
        business_id = path_params.get('business_id')
        if not business_id:
            return create_response(400, {'error': 'Missing business_id'})
        
        # Parse week parameter or use current week
        week_start_str = query_params.get('week_start')
        if week_start_str:
            week_start = datetime.fromisoformat(week_start_str.replace('Z', '+00:00'))
        else:
            today = datetime.now(timezone.utc)
            week_start = today - timedelta(days=today.weekday())
        
        week_start = week_start.replace(hour=0, minute=0, second=0, microsecond=0)
        week_end = week_start + timedelta(days=7)
        
        # Query orders for the week
        orders = get_orders_in_date_range(business_id, week_start, week_end)
        
        # Calculate metrics
        analytics = calculate_weekly_metrics(orders, week_start)
        
        logger.info(f"Weekly analytics calculated for business {business_id}")
        
        return create_response(200, analytics)
        
    except Exception as e:
        logger.error(f"Weekly analytics error: {str(e)}")
        return create_response(500, {'error': 'Failed to calculate weekly analytics'})

def handle_monthly_analytics(path_params: Dict[str, Any], query_params: Dict[str, Any]) -> Dict[str, Any]:
    """Get monthly analytics for a business"""
    try:
        business_id = path_params.get('business_id')
        if not business_id:
            return create_response(400, {'error': 'Missing business_id'})
        
        # Parse month parameter or use current month
        month_str = query_params.get('month')
        if month_str:
            target_date = datetime.fromisoformat(month_str + '-01T00:00:00+00:00')
        else:
            target_date = datetime.now(timezone.utc)
        
        # Get start and end of month
        month_start = target_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        if month_start.month == 12:
            month_end = month_start.replace(year=month_start.year + 1, month=1)
        else:
            month_end = month_start.replace(month=month_start.month + 1)
        
        # Query orders for the month
        orders = get_orders_in_date_range(business_id, month_start, month_end)
        
        # Calculate metrics
        analytics = calculate_monthly_metrics(orders, month_start)
        
        logger.info(f"Monthly analytics calculated for business {business_id}")
        
        return create_response(200, analytics)
        
    except Exception as e:
        logger.error(f"Monthly analytics error: {str(e)}")
        return create_response(500, {'error': 'Failed to calculate monthly analytics'})

def handle_orders_summary(path_params: Dict[str, Any], query_params: Dict[str, Any]) -> Dict[str, Any]:
    """Get orders summary for a business"""
    try:
        business_id = path_params.get('business_id')
        if not business_id:
            return create_response(400, {'error': 'Missing business_id'})
        
        # Query recent orders
        response = table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1_PK = :pk',
            FilterExpression='entity_type = :entity_type',
            ExpressionAttributeValues={
                ':pk': f'BUSINESS#{business_id}',
                ':entity_type': 'ORDER'
            },
            ScanIndexForward=False,
            Limit=100
        )
        
        orders = response.get('Items', [])
        
        # Calculate summary metrics
        summary = {
            'total_orders': len(orders),
            'status_breakdown': {},
            'recent_orders': orders[:10],  # Last 10 orders
            'average_order_value': 0,
            'total_revenue': 0
        }
        
        if orders:
            # Status breakdown
            status_counts = {}
            total_amount = 0
            
            for order in orders:
                status = order.get('status', 'unknown')
                status_counts[status] = status_counts.get(status, 0) + 1
                
                amount = float(order.get('total_amount', 0))
                total_amount += amount
            
            summary['status_breakdown'] = status_counts
            summary['total_revenue'] = round(total_amount, 2)
            summary['average_order_value'] = round(total_amount / len(orders), 2)
        
        logger.info(f"Orders summary calculated for business {business_id}")
        
        return create_response(200, summary)
        
    except Exception as e:
        logger.error(f"Orders summary error: {str(e)}")
        return create_response(500, {'error': 'Failed to calculate orders summary'})

def handle_performance_metrics(path_params: Dict[str, Any], query_params: Dict[str, Any]) -> Dict[str, Any]:
    """Get performance metrics for a business"""
    try:
        business_id = path_params.get('business_id')
        if not business_id:
            return create_response(400, {'error': 'Missing business_id'})
        
        # Get orders from last 30 days
        end_date = datetime.now(timezone.utc)
        start_date = end_date - timedelta(days=30)
        
        orders = get_orders_in_date_range(business_id, start_date, end_date)
        
        if not orders:
            return create_response(200, {
                'order_acceptance_rate': 0,
                'average_preparation_time': 0,
                'customer_satisfaction_score': 0,
                'on_time_delivery_rate': 0,
                'order_completion_rate': 0,
                'peak_hours': [],
                'busiest_days': []
            })
        
        # Calculate performance metrics
        metrics = calculate_performance_metrics(orders)
        
        logger.info(f"Performance metrics calculated for business {business_id}")
        
        return create_response(200, metrics)
        
    except Exception as e:
        logger.error(f"Performance metrics error: {str(e)}")
        return create_response(500, {'error': 'Failed to calculate performance metrics'})

def handle_trends_analysis(path_params: Dict[str, Any], query_params: Dict[str, Any]) -> Dict[str, Any]:
    """Get trends analysis for a business"""
    try:
        business_id = path_params.get('business_id')
        if not business_id:
            return create_response(400, {'error': 'Missing business_id'})
        
        # Get orders from last 90 days for trend analysis
        end_date = datetime.now(timezone.utc)
        start_date = end_date - timedelta(days=90)
        
        orders = get_orders_in_date_range(business_id, start_date, end_date)
        
        # Calculate trends
        trends = calculate_trends(orders, start_date, end_date)
        
        logger.info(f"Trends analysis calculated for business {business_id}")
        
        return create_response(200, trends)
        
    except Exception as e:
        logger.error(f"Trends analysis error: {str(e)}")
        return create_response(500, {'error': 'Failed to calculate trends analysis'})

def handle_system_overview(query_params: Dict[str, Any]) -> Dict[str, Any]:
    """Get system-wide overview (admin function)"""
    try:
        # This would typically be restricted to admin users
        
        # Query recent system metrics
        end_date = datetime.now(timezone.utc)
        start_date = end_date - timedelta(days=1)  # Last 24 hours
        
        # Get system-wide statistics
        overview = {
            'total_businesses': 0,
            'total_orders_today': 0,
            'total_revenue_today': 0,
            'active_merchants': 0,
            'system_health': 'healthy',
            'error_rate': 0
        }
        
        # In a real implementation, you would scan across businesses
        # For now, return mock data
        overview.update({
            'total_businesses': 15,
            'total_orders_today': 234,
            'total_revenue_today': 4567.89,
            'active_merchants': 12,
            'system_health': 'healthy',
            'error_rate': 0.02
        })
        
        logger.info("System overview calculated")
        
        return create_response(200, overview)
        
    except Exception as e:
        logger.error(f"System overview error: {str(e)}")
        return create_response(500, {'error': 'Failed to get system overview'})

def get_orders_in_date_range(business_id: str, start_date: datetime, end_date: datetime) -> List[Dict[str, Any]]:
    """Query orders for a business within a date range"""
    try:
        # Convert dates to ISO strings for comparison
        start_str = start_date.isoformat()
        end_str = end_date.isoformat()
        
        # Query orders from DynamoDB
        response = table.query(
            IndexName='GSI1',
            KeyConditionExpression='GSI1_PK = :pk',
            FilterExpression='entity_type = :entity_type AND created_at BETWEEN :start_date AND :end_date',
            ExpressionAttributeValues={
                ':pk': f'BUSINESS#{business_id}',
                ':entity_type': 'ORDER',
                ':start_date': start_str,
                ':end_date': end_str
            }
        )
        
        return response.get('Items', [])
        
    except Exception as e:
        logger.error(f"Error querying orders: {str(e)}")
        return []

def calculate_daily_metrics(orders: List[Dict[str, Any]], target_date: datetime) -> Dict[str, Any]:
    """Calculate daily metrics from orders"""
    if not orders:
        return {
            'date': target_date.date().isoformat(),
            'total_orders': 0,
            'total_revenue': 0,
            'average_order_value': 0,
            'completed_orders': 0,
            'cancelled_orders': 0,
            'pending_orders': 0,
            'hourly_breakdown': []
        }
    
    # Calculate basic metrics
    total_orders = len(orders)
    total_revenue = sum(float(order.get('total_amount', 0)) for order in orders)
    average_order_value = total_revenue / total_orders if total_orders > 0 else 0
    
    # Status breakdown
    completed_orders = len([o for o in orders if o.get('status') == 'completed'])
    cancelled_orders = len([o for o in orders if o.get('status') == 'cancelled'])
    pending_orders = len([o for o in orders if o.get('status') in ['pending', 'preparing', 'ready']])
    
    # Hourly breakdown
    hourly_counts = {}
    for order in orders:
        created_at = datetime.fromisoformat(order['created_at'].replace('Z', '+00:00'))
        hour = created_at.hour
        hourly_counts[hour] = hourly_counts.get(hour, 0) + 1
    
    hourly_breakdown = [{'hour': h, 'orders': hourly_counts.get(h, 0)} for h in range(24)]
    
    return {
        'date': target_date.date().isoformat(),
        'total_orders': total_orders,
        'total_revenue': round(total_revenue, 2),
        'average_order_value': round(average_order_value, 2),
        'completed_orders': completed_orders,
        'cancelled_orders': cancelled_orders,
        'pending_orders': pending_orders,
        'hourly_breakdown': hourly_breakdown
    }

def calculate_weekly_metrics(orders: List[Dict[str, Any]], week_start: datetime) -> Dict[str, Any]:
    """Calculate weekly metrics from orders"""
    if not orders:
        return {
            'week_start': week_start.date().isoformat(),
            'total_orders': 0,
            'total_revenue': 0,
            'daily_breakdown': [],
            'growth_rate': 0
        }
    
    # Daily breakdown
    daily_counts = {}
    daily_revenue = {}
    
    for order in orders:
        created_at = datetime.fromisoformat(order['created_at'].replace('Z', '+00:00'))
        date_key = created_at.date().isoformat()
        
        daily_counts[date_key] = daily_counts.get(date_key, 0) + 1
        daily_revenue[date_key] = daily_revenue.get(date_key, 0) + float(order.get('total_amount', 0))
    
    # Create daily breakdown for 7 days
    daily_breakdown = []
    for i in range(7):
        day = week_start + timedelta(days=i)
        date_key = day.date().isoformat()
        daily_breakdown.append({
            'date': date_key,
            'orders': daily_counts.get(date_key, 0),
            'revenue': round(daily_revenue.get(date_key, 0), 2)
        })
    
    total_orders = len(orders)
    total_revenue = sum(float(order.get('total_amount', 0)) for order in orders)
    
    return {
        'week_start': week_start.date().isoformat(),
        'total_orders': total_orders,
        'total_revenue': round(total_revenue, 2),
        'daily_breakdown': daily_breakdown,
        'growth_rate': 0  # Would calculate based on previous week
    }

def calculate_monthly_metrics(orders: List[Dict[str, Any]], month_start: datetime) -> Dict[str, Any]:
    """Calculate monthly metrics from orders"""
    if not orders:
        return {
            'month': month_start.strftime('%Y-%m'),
            'total_orders': 0,
            'total_revenue': 0,
            'weekly_breakdown': [],
            'top_items': [],
            'growth_rate': 0
        }
    
    # Weekly breakdown
    weekly_breakdown = []
    current_week_start = month_start
    
    while current_week_start.month == month_start.month:
        week_end = min(current_week_start + timedelta(days=7), 
                      month_start.replace(month=month_start.month+1) if month_start.month < 12 
                      else month_start.replace(year=month_start.year+1, month=1))
        
        week_orders = [o for o in orders 
                      if current_week_start <= datetime.fromisoformat(o['created_at'].replace('Z', '+00:00')) < week_end]
        
        weekly_breakdown.append({
            'week_start': current_week_start.date().isoformat(),
            'orders': len(week_orders),
            'revenue': round(sum(float(o.get('total_amount', 0)) for o in week_orders), 2)
        })
        
        current_week_start = week_end
        if current_week_start.month != month_start.month:
            break
    
    total_orders = len(orders)
    total_revenue = sum(float(order.get('total_amount', 0)) for order in orders)
    
    return {
        'month': month_start.strftime('%Y-%m'),
        'total_orders': total_orders,
        'total_revenue': round(total_revenue, 2),
        'weekly_breakdown': weekly_breakdown,
        'top_items': [],  # Would analyze items if available
        'growth_rate': 0  # Would calculate based on previous month
    }

def calculate_performance_metrics(orders: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Calculate performance metrics from orders"""
    if not orders:
        return {
            'order_acceptance_rate': 0,
            'average_preparation_time': 0,
            'customer_satisfaction_score': 0,
            'on_time_delivery_rate': 0,
            'order_completion_rate': 0
        }
    
    total_orders = len(orders)
    completed_orders = len([o for o in orders if o.get('status') == 'completed'])
    cancelled_orders = len([o for o in orders if o.get('status') == 'cancelled'])
    
    # Calculate metrics
    order_acceptance_rate = ((total_orders - cancelled_orders) / total_orders * 100) if total_orders > 0 else 0
    order_completion_rate = (completed_orders / total_orders * 100) if total_orders > 0 else 0
    
    return {
        'order_acceptance_rate': round(order_acceptance_rate, 2),
        'average_preparation_time': 25,  # Mock data - would calculate from order timestamps
        'customer_satisfaction_score': 4.2,  # Mock data - would get from customer feedback
        'on_time_delivery_rate': 85.5,  # Mock data - would calculate from delivery times
        'order_completion_rate': round(order_completion_rate, 2)
    }

def calculate_trends(orders: List[Dict[str, Any]], start_date: datetime, end_date: datetime) -> Dict[str, Any]:
    """Calculate trend analysis from orders"""
    if not orders:
        return {
            'revenue_trend': 'stable',
            'order_volume_trend': 'stable',
            'average_order_value_trend': 'stable',
            'predictions': {}
        }
    
    # Group by week for trend analysis
    weekly_data = {}
    
    for order in orders:
        created_at = datetime.fromisoformat(order['created_at'].replace('Z', '+00:00'))
        week_start = created_at - timedelta(days=created_at.weekday())
        week_key = week_start.date().isoformat()
        
        if week_key not in weekly_data:
            weekly_data[week_key] = {'orders': 0, 'revenue': 0}
        
        weekly_data[week_key]['orders'] += 1
        weekly_data[week_key]['revenue'] += float(order.get('total_amount', 0))
    
    # Simple trend calculation (would use more sophisticated analysis in production)
    weeks = sorted(weekly_data.keys())
    if len(weeks) >= 2:
        first_half = weeks[:len(weeks)//2]
        second_half = weeks[len(weeks)//2:]
        
        first_half_avg_revenue = sum(weekly_data[w]['revenue'] for w in first_half) / len(first_half)
        second_half_avg_revenue = sum(weekly_data[w]['revenue'] for w in second_half) / len(second_half)
        
        if second_half_avg_revenue > first_half_avg_revenue * 1.1:
            revenue_trend = 'increasing'
        elif second_half_avg_revenue < first_half_avg_revenue * 0.9:
            revenue_trend = 'decreasing'
        else:
            revenue_trend = 'stable'
    else:
        revenue_trend = 'insufficient_data'
    
    return {
        'revenue_trend': revenue_trend,
        'order_volume_trend': 'stable',  # Similar calculation
        'average_order_value_trend': 'stable',  # Similar calculation
        'weekly_data': weekly_data,
        'predictions': {
            'next_week_orders': 45,  # Mock prediction
            'next_week_revenue': 1250.00  # Mock prediction
        }
    }

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
