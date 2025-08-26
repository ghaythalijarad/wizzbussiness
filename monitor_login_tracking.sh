#!/bin/bash

# Monitor DynamoDB table for LOGIN# tracking entries during testing
echo "🔍 MONITORING DynamoDB for LOGIN# tracking entries..."
echo "======================================================"
echo ""

check_login_entries() {
    echo "⏰ $(date '+%H:%M:%S') - Checking for LOGIN# entries..."
    
    # Scan for items with PK starting with LOGIN#
    local result=$(AWS_PROFILE=wizz-merchants-dev aws dynamodb scan \
        --table-name wizzgo-dev-wss-onconnect \
        --filter-expression "begins_with(PK, :loginPrefix)" \
        --expression-attribute-values '{":loginPrefix":{"S":"LOGIN#"}}' \
        --select "ALL_ATTRIBUTES" 2>/dev/null)
    
    local count=$(echo "$result" | jq -r '.Count // 0')
    
    if [ "$count" -gt 0 ]; then
        echo "✅ Found $count LOGIN# tracking entries:"
        echo "$result" | jq -r '.Items[] | "  - PK: \(.PK.S), businessId: \(.businessId.S // "N/A"), userId: \(.userId.S // "N/A"), isLoginTracking: \(.isLoginTracking.BOOL // false)"'
    else
        echo "❌ No LOGIN# tracking entries found"
    fi
    echo ""
}

echo "🚀 Starting monitoring... (Press Ctrl+C to stop)"
echo "   Now login with business user in Flutter app"
echo ""

# Initial check
check_login_entries

# Monitor every 5 seconds
while true; do
    sleep 5
    check_login_entries
done
