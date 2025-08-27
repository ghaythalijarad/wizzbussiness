#!/bin/bash

echo "🔍 Monitoring WebSocket Connections for Business Testing"
echo "======================================================"

while true; do
    echo ""
    echo "⏰ $(date): Checking active WebSocket connections..."
    
    # Check for business connections
    echo "🏢 Business Connections:"
    aws dynamodb scan \
        --table-name WizzUser_websocket_connections_dev \
        --profile wizz-merchants-dev \
        --region us-east-1 \
        --filter-expression "entityType = :merchant" \
        --expression-attribute-values '{":merchant":{"S":"merchant"}}' \
        --query 'Items[*].{ConnectionId:connectionId.S,BusinessId:businessId.S,ConnectedAt:connectedAt.S}' \
        --output table 2>/dev/null || echo "No business connections found"
    
    echo ""
    echo "👥 Customer Connections:"
    aws dynamodb scan \
        --table-name WizzUser_websocket_connections_dev \
        --profile wizz-merchants-dev \
        --region us-east-1 \
        --filter-expression "entityType = :customer" \
        --expression-attribute-values '{":customer":{"S":"customer"}}' \
        --query 'Items[*].{ConnectionId:connectionId.S,UserId:userId.S,ConnectedAt:connectedAt.S}' \
        --output table 2>/dev/null || echo "No customer connections found"
    
    echo ""
    echo "📊 Total Active Connections:"
    aws dynamodb scan \
        --table-name WizzUser_websocket_connections_dev \
        --profile wizz-merchants-dev \
        --region us-east-1 \
        --select COUNT \
        --query 'Count' \
        --output text 2>/dev/null || echo "0"
    
    echo ""
    echo "Press Ctrl+C to stop monitoring..."
    sleep 10
done
