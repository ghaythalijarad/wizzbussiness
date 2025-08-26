#!/bin/bash

echo "🗑️  AWS CloudFormation Stack Deletion Script"
echo "==========================================="
echo ""
echo "⚠️  WARNING: This will delete all deployed AWS resources!"
echo "Make sure you want to proceed before running these commands."
echo ""

# Set AWS region
AWS_REGION="us-east-1"

# List of stacks to delete (based on workflow files)
STACKS=(
    "order-receiver-api-dev"
    "order-receiver-api-staging" 
    "order-receiver-api-prod"
    "order-receiver-dev"
    "order-receiver-staging"
    "order-receiver-production"
)

echo "Checking for existing stacks..."
echo ""

# Check which stacks exist
for stack in "${STACKS[@]}"; do
    echo "Checking stack: $stack"
    if aws cloudformation describe-stacks --stack-name "$stack" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo "✅ Stack exists: $stack"
        echo "To delete: aws cloudformation delete-stack --stack-name \"$stack\" --region \"$AWS_REGION\""
        echo ""
    else
        echo "❌ Stack not found: $stack"
        echo ""
    fi
done

# Check for frontend hosting stacks (they have account ID in the name)
echo "Checking for frontend hosting stacks..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "UNKNOWN")

if [ "$ACCOUNT_ID" != "UNKNOWN" ]; then
    FRONTEND_STACKS=(
        "order-receiver-frontend-dev-$ACCOUNT_ID"
        "order-receiver-frontend-staging-$ACCOUNT_ID"
        "order-receiver-frontend-prod-$ACCOUNT_ID"
    )
    
    for stack in "${FRONTEND_STACKS[@]}"; do
        echo "Checking frontend stack: $stack"
        if aws cloudformation describe-stacks --stack-name "$stack" --region "$AWS_REGION" >/dev/null 2>&1; then
            echo "✅ Frontend stack exists: $stack"
            echo "To delete: aws cloudformation delete-stack --stack-name \"$stack\" --region \"$AWS_REGION\""
            echo ""
        else
            echo "❌ Frontend stack not found: $stack"
            echo ""
        fi
    done
else
    echo "Could not determine AWS Account ID. Please check frontend stacks manually:"
    echo "aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --region $AWS_REGION | grep order-receiver-frontend"
fi

echo ""
echo "📋 To delete ALL stacks at once, run:"
echo ""
echo "# Delete backend API stacks"
for stack in "${STACKS[@]}"; do
    echo "aws cloudformation delete-stack --stack-name \"$stack\" --region \"$AWS_REGION\""
done

echo ""
echo "# Check for and delete frontend hosting stacks"
echo "aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --region $AWS_REGION --query 'StackSummaries[?contains(StackName, \`order-receiver-frontend\`)].StackName' --output text | xargs -I {} aws cloudformation delete-stack --stack-name {} --region $AWS_REGION"

echo ""
echo "📊 To monitor deletion progress:"
echo "watch 'aws cloudformation list-stacks --stack-status-filter DELETE_IN_PROGRESS --region $AWS_REGION --query \"StackSummaries[?contains(StackName, \\`order-receiver\\`)].{Name:StackName,Status:StackStatus}\" --output table'"

echo ""
echo "✅ Script completed. Review the commands above and run them if you want to delete the stacks."
