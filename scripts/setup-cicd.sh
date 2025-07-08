#!/bin/bash

# GitHub Actions CI/CD Setup Script
# This script helps set up the required AWS resources and GitHub secrets for the CI/CD pipeline

set -e

echo "🚀 Setting up GitHub Actions CI/CD for Order Receiver App"
echo "======================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if required tools are installed
check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    
    for cmd in aws gh jq terraform; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}❌ $cmd is not installed${NC}"
            exit 1
        else
            echo -e "${GREEN}✅ $cmd is available${NC}"
        fi
    done
}

# Function to create S3 buckets
create_s3_buckets() {
    local env=$1
    local region=${2:-us-east-1}
    
    echo -e "${BLUE}Creating S3 buckets for $env environment...${NC}"
    
    # SAM deployment bucket
    local sam_bucket="order-receiver-sam-deployments-${env}-$(date +%s)"
    aws s3 mb s3://$sam_bucket --region $region
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket $sam_bucket \
        --versioning-configuration Status=Enabled
        
    echo -e "${GREEN}✅ Created SAM deployment bucket: $sam_bucket${NC}"
    echo "SAM_DEPLOYMENT_BUCKET_${env^^}=$sam_bucket"
    
    # Web hosting bucket (only for production)
    if [ "$env" = "prod" ]; then
        local web_bucket="order-receiver-web-${env}-$(date +%s)"
        aws s3 mb s3://$web_bucket --region $region
        
        # Configure for static website hosting
        aws s3 website s3://$web_bucket \
            --index-document index.html \
            --error-document error.html
            
        echo -e "${GREEN}✅ Created web hosting bucket: $web_bucket${NC}"
        echo "WEB_S3_BUCKET=$web_bucket"
    fi
}

# Function to create Terraform state bucket
create_terraform_state_bucket() {
    local region=${1:-us-east-1}
    
    echo -e "${BLUE}Creating Terraform state bucket...${NC}"
    
    local tf_bucket="order-receiver-terraform-state-$(date +%s)"
    aws s3 mb s3://$tf_bucket --region $region
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket $tf_bucket \
        --versioning-configuration Status=Enabled
        
    # Enable server-side encryption
    aws s3api put-bucket-encryption \
        --bucket $tf_bucket \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
        
    echo -e "${GREEN}✅ Created Terraform state bucket: $tf_bucket${NC}"
    echo "TERRAFORM_STATE_BUCKET=$tf_bucket"
}

# Function to create IAM user for GitHub Actions
create_github_actions_user() {
    echo -e "${BLUE}Creating GitHub Actions IAM user...${NC}"
    
    # Create IAM user
    aws iam create-user --user-name github-actions-order-receiver
    
    # Create and attach policy
    cat > github-actions-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:*",
                "s3:*",
                "lambda:*",
                "apigateway:*",
                "iam:*",
                "dynamodb:*",
                "cognito-idp:*",
                "logs:*",
                "events:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF

    aws iam put-user-policy \
        --user-name github-actions-order-receiver \
        --policy-name GitHubActionsPolicy \
        --policy-document file://github-actions-policy.json
        
    # Create access keys
    local credentials=$(aws iam create-access-key --user-name github-actions-order-receiver --output json)
    local access_key=$(echo $credentials | jq -r '.AccessKey.AccessKeyId')
    local secret_key=$(echo $credentials | jq -r '.AccessKey.SecretAccessKey')
    
    echo -e "${GREEN}✅ Created GitHub Actions user${NC}"
    echo "AWS_ACCESS_KEY_ID=$access_key"
    echo "AWS_SECRET_ACCESS_KEY=$secret_key"
    
    # Clean up policy file
    rm github-actions-policy.json
}

# Function to generate secrets
generate_secrets() {
    echo -e "${BLUE}Generating application secrets...${NC}"
    
    for env in dev staging prod; do
        local secret=$(openssl rand -base64 32)
        echo "SECRET_KEY_${env^^}=$secret"
    done
    
    echo "CORS_ORIGINS_DEV=http://localhost:3000,http://localhost:8080"
    echo "CORS_ORIGINS_STAGING=https://staging.yourdomain.com"
    echo "CORS_ORIGINS_PROD=https://yourdomain.com"
}

# Function to set up GitHub repository
setup_github_repo() {
    echo -e "${BLUE}Setting up GitHub repository...${NC}"
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        echo -e "${YELLOW}Initializing git repository...${NC}"
        git init
        git add .
        git commit -m "Initial commit with CI/CD setup"
    fi
    
    # Create GitHub repository if it doesn't exist
    if ! gh repo view &> /dev/null; then
        echo -e "${YELLOW}Creating GitHub repository...${NC}"
        gh repo create order-receiver-app-2 --public --source=. --remote=origin --push
    fi
    
    # Create environments
    echo -e "${BLUE}Creating GitHub environments...${NC}"
    for env in development staging production; do
        gh api repos/:owner/:repo/environments/$env -X PUT
        echo -e "${GREEN}✅ Created environment: $env${NC}"
    done
}

# Main setup function
main() {
    echo -e "${YELLOW}⚠️  This script will create AWS resources that may incur costs.${NC}"
    echo -e "${YELLOW}⚠️  Make sure you have the necessary permissions and understand the billing implications.${NC}"
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
    
    check_dependencies
    
    echo ""
    echo -e "${GREEN}🏗️  Creating AWS Resources...${NC}"
    echo "================================"
    
    # Create S3 buckets
    create_s3_buckets "dev"
    create_s3_buckets "staging" 
    create_s3_buckets "prod"
    
    # Create Terraform state bucket
    create_terraform_state_bucket
    
    # Create IAM user (optional)
    echo ""
    read -p "Create GitHub Actions IAM user? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_github_actions_user
    fi
    
    echo ""
    echo -e "${GREEN}🔐 Generated Secrets:${NC}"
    echo "===================="
    generate_secrets
    
    echo ""
    echo -e "${GREEN}📝 Next Steps:${NC}"
    echo "=============="
    echo "1. Add the above secrets to your GitHub repository:"
    echo "   Go to Settings > Secrets and variables > Actions"
    echo ""
    echo "2. Update the repository URLs in the README badges"
    echo ""
    echo "3. Configure your domain names in the CORS_ORIGINS secrets"
    echo ""
    echo "4. Set up GitHub environments with protection rules:"
    echo "   - development: No protection"
    echo "   - staging: Require review from team"
    echo "   - production: Require review from admin + manual approval"
    echo ""
    echo "5. Test the pipeline by pushing to the develop branch"
    echo ""
    echo -e "${GREEN}✅ Setup complete!${NC}"
}

# Run main function
main "$@"
