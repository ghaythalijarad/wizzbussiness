#!/bin/bash

# Check business photo URLs in DynamoDB
echo "🔍 Checking Business Photo URLs in DynamoDB..."
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not installed. Please install it first."
    echo "   brew install awscli"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run:"
    echo "   aws configure"
    exit 1
fi

echo "✅ AWS CLI configured. Checking business photo URLs..."
echo ""

# Scan businesses table for photo URLs
echo "📊 Business Photo URLs in Database:"
echo "=================================="

aws dynamodb scan \
    --table-name order-receiver-businesses-dev \
    --region eu-north-1 \
    --projection-expression 'businessId, business_name, business_photo_url' \
    --output table 2>/dev/null || {
    echo "❌ Error accessing DynamoDB table. Possible issues:"
    echo "   • Table doesn't exist yet"
    echo "   • Wrong region (current: eu-north-1)"
    echo "   • Insufficient permissions"
    echo ""
    echo "🔍 Try checking available tables:"
    echo "   aws dynamodb list-tables --region eu-north-1"
}

echo ""
echo "🔗 To test if URLs are accessible:"
echo "   curl -I '<photo_url_from_above>'"
echo ""
echo "💡 Expected result: 404 Not Found (because they're mock URLs)"
