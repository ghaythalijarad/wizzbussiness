#!/bin/bash

# Deployment Status Monitor
# This script checks the status of deployments across all environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🔍 Checking Deployment Status"
echo "============================"

# Function to check CloudFormation stack status
check_stack_status() {
    local stack_name=$1
    local env=$2
    
    echo -e "${BLUE}Checking $env environment...${NC}"
    
    if aws cloudformation describe-stacks --stack-name $stack_name &> /dev/null; then
        local status=$(aws cloudformation describe-stacks \
            --stack-name $stack_name \
            --query 'Stacks[0].StackStatus' \
            --output text)
            
        case $status in
            "CREATE_COMPLETE"|"UPDATE_COMPLETE")
                echo -e "${GREEN}✅ $env: $status${NC}"
                ;;
            "CREATE_IN_PROGRESS"|"UPDATE_IN_PROGRESS")
                echo -e "${YELLOW}⏳ $env: $status${NC}"
                ;;
            *"FAILED"*|*"ROLLBACK"*)
                echo -e "${RED}❌ $env: $status${NC}"
                ;;
            *)
                echo -e "${YELLOW}⚠️  $env: $status${NC}"
                ;;
        esac
        
        # Get API Gateway URL if available
        local api_url=$(aws cloudformation describe-stacks \
            --stack-name $stack_name \
            --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
            --output text 2>/dev/null || echo "N/A")
            
        if [ "$api_url" != "N/A" ] && [ "$api_url" != "" ]; then
            echo -e "   API URL: ${BLUE}$api_url${NC}"
            
            # Test health endpoint
            if curl -s -f "$api_url/health" > /dev/null 2>&1; then
                echo -e "   Health Check: ${GREEN}✅ Healthy${NC}"
            else
                echo -e "   Health Check: ${RED}❌ Unhealthy${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ $env: Stack not found${NC}"
    fi
    echo ""
}

# Function to check GitHub Actions status
check_github_actions() {
    echo -e "${BLUE}Checking GitHub Actions...${NC}"
    
    if command -v gh &> /dev/null; then
        local runs=$(gh run list --limit 5 --json status,conclusion,workflowName,createdAt)
        
        if [ "$runs" != "[]" ]; then
            echo "$runs" | jq -r '.[] | "\(.workflowName): \(.status) - \(.conclusion // "running") (\(.createdAt | split("T")[0]))"' | while read line; do
                if [[ $line == *"success"* ]]; then
                    echo -e "${GREEN}✅ $line${NC}"
                elif [[ $line == *"failure"* ]]; then
                    echo -e "${RED}❌ $line${NC}"
                elif [[ $line == *"running"* ]] || [[ $line == *"in_progress"* ]]; then
                    echo -e "${YELLOW}⏳ $line${NC}"
                else
                    echo -e "${YELLOW}⚠️  $line${NC}"
                fi
            done
        else
            echo -e "${YELLOW}No recent workflow runs found${NC}"
        fi
    else
        echo -e "${YELLOW}GitHub CLI not installed - skipping workflow status${NC}"
    fi
    echo ""
}

# Main function
main() {
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS CLI not configured or no permissions${NC}"
        exit 1
    fi
    
    echo -e "Current AWS Account: ${BLUE}$(aws sts get-caller-identity --query 'Account' --output text)${NC}"
    echo -e "Current AWS Region: ${BLUE}$(aws configure get region)${NC}"
    echo ""
    
    # Check stack statuses
    check_stack_status "order-receiver-dev" "Development"
    check_stack_status "order-receiver-staging" "Staging"
    check_stack_status "order-receiver-production" "Production"
    
    # Check GitHub Actions
    check_github_actions
    
    echo -e "${GREEN}Status check complete!${NC}"
}

# Run main function
main "$@"
