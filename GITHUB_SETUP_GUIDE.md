# GitHub Repository Setup Guide

This guide will help you set up the GitHub repository and configure the CI/CD pipeline for your serverless order receiver application.

## 📋 Prerequisites

- [x] All code and tests implemented locally
- [x] Tests passing (unit tests and data validation)
- [ ] GitHub account ready
- [ ] AWS CLI configured locally
- [ ] Git repository initialized

## 🚀 Step 1: Initialize Git Repository

```bash
# Navigate to your project directory
cd /Users/ghaythallaheebi/order-receiver-app-2

# Initialize git repository (if not already done)
git init

# Add all files to git
git add .

# Make initial commit
git commit -m "feat: Initial implementation with complete CI/CD pipeline

- FastAPI backend with authentication and order processing
- Flutter frontend for business management
- Comprehensive GitHub Actions CI/CD workflows
- Unit and integration test suites
- Security scanning with multiple tools
- Performance testing with Locust and Lighthouse
- Infrastructure as code with Terraform
- Development and deployment scripts"
```

## 🌐 Step 2: Create GitHub Repository

1. **Go to GitHub:** https://github.com/new
2. **Repository Details:**
   - Repository name: `order-receiver-app` (or your preferred name)
   - Description: `Serverless order receiver application with FastAPI backend and Flutter frontend`
   - Visibility: `Public` or `Private` (your choice)
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)

3. **Copy the repository URL** (you'll need this for the next step)

## 🔗 Step 3: Connect Local Repository to GitHub

```bash
# Add GitHub remote (replace with your actual repository URL)
git remote add origin https://github.com/YOUR_USERNAME/order-receiver-app.git

# Verify remote is added
git remote -v

# Push to GitHub
git branch -M main
git push -u origin main
```

## 🔑 Step 4: Configure GitHub Secrets

In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions** and add these secrets:

### Required AWS Secrets
```
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=us-east-1
```

### Deployment Bucket Secrets
```
DEV_BUCKET_NAME=order-receiver-dev-frontend
STAGING_BUCKET_NAME=order-receiver-staging-frontend
PROD_BUCKET_NAME=order-receiver-prod-frontend
```

### Optional Secrets (for enhanced features)
```
SLACK_WEBHOOK_URL=your_slack_webhook_for_notifications
CODECOV_TOKEN=your_codecov_token_for_coverage_reports
```

## 🏗️ Step 5: Set Up AWS Resources

Run the setup script to create required AWS resources:

```bash
# Make script executable (if not already done)
chmod +x scripts/setup-cicd.sh

# Run setup script
./scripts/setup-cicd.sh
```

This script will create:
- S3 buckets for frontend hosting
- IAM users and policies for CI/CD
- Access keys for GitHub Actions

## 🌍 Step 6: Configure GitHub Environments

Go to **Settings** → **Environments** and create:

### Development Environment
- Name: `development`
- No protection rules needed
- Add environment secrets if different from repository secrets

### Staging Environment  
- Name: `staging`
- Protection rules:
  - ✅ Required reviewers: 1 reviewer
  - ✅ Wait timer: 5 minutes
- Add staging-specific secrets

### Production Environment
- Name: `production`
- Protection rules:
  - ✅ Required reviewers: 2 reviewers
  - ✅ Wait timer: 10 minutes
  - ✅ Deployment branches: Only main branch
- Add production-specific secrets

## ✅ Step 7: Test the CI/CD Pipeline

1. **Trigger First Build:**
   ```bash
   # Make a small change to test the pipeline
   echo "# Test Change" >> README.md
   git add README.md
   git commit -m "test: Trigger initial CI/CD pipeline"
   git push origin main
   ```

2. **Monitor the Build:**
   - Go to **Actions** tab in your GitHub repository
   - Watch the "CI/CD Pipeline" workflow run
   - Verify all jobs complete successfully

3. **Check Deployment:**
   - Development environment should deploy automatically
   - Staging deployment will wait for approval
   - Production deployment will wait for approval

## 🔍 Step 8: Verify Deployments

### Check Frontend Deployments
```bash
# Check if S3 buckets were created and files uploaded
aws s3 ls s3://order-receiver-dev-frontend/
aws s3 ls s3://order-receiver-staging-frontend/
aws s3 ls s3://order-receiver-prod-frontend/
```

### Check Backend API
```bash
# Test deployed backend (replace with actual API Gateway URL)
curl https://your-api-gateway-url.amazonaws.com/health
```

### Run Deployment Status Check
```bash
# Use our status check script
./scripts/check-deployment-status.sh
```

## 🛠️ Step 9: Local Development Workflow

Use the local development script for testing:

```bash
# Start local development environment
./scripts/local-dev.sh

# In another terminal, run tests
cd backend
python3.9 -m pytest tests/test_unit.py -v

# Test Flutter frontend
cd frontend
flutter test
```

## 📊 Step 10: Monitor and Maintain

### Automated Monitoring
- **Dependabot:** Automatically creates PRs for dependency updates
- **Security Scanning:** Runs on every push and PR
- **Performance Testing:** Runs on releases
- **Infrastructure Drift:** Monitors Terraform state

### Manual Monitoring
- Check GitHub Actions for build status
- Monitor AWS CloudWatch for application metrics
- Review security scan results regularly
- Update dependencies when Dependabot creates PRs

## 🐛 Troubleshooting

### Common Issues

1. **AWS Credentials Error:**
   - Verify secrets are correctly set in GitHub
   - Check IAM permissions for the CI/CD user

2. **S3 Bucket Exists Error:**
   - S3 bucket names must be globally unique
   - Update bucket names in secrets and scripts

3. **Tests Failing:**
   - Integration tests will skip/fail if API is not running (expected)
   - Unit tests should always pass
   - Check test logs for specific errors

4. **Deployment Failures:**
   - Check CloudFormation/Terraform logs in AWS console
   - Verify all required secrets are set
   - Check IAM permissions

### Getting Help

1. **Check workflow logs** in GitHub Actions
2. **Review AWS CloudWatch logs** for runtime errors
3. **Run local tests** to verify code changes
4. **Use deployment status script** to check resource states

## 🎉 Success Criteria

Your CI/CD pipeline is successfully set up when:

- ✅ All GitHub Actions workflows run without errors
- ✅ Unit tests pass consistently
- ✅ Security scans complete without critical issues
- ✅ Frontend deploys to S3 buckets
- ✅ Backend deploys to AWS Lambda/ECS
- ✅ Environment promotions require proper approvals
- ✅ Performance tests provide useful metrics
- ✅ Infrastructure is managed via Terraform

## 📚 Next Steps

1. **Domain Setup:** Configure custom domains for environments
2. **Monitoring:** Set up CloudWatch dashboards and alerts
3. **Backup Strategy:** Implement database and configuration backups
4. **Documentation:** Keep README and documentation updated
5. **Team Onboarding:** Share repository access and workflows

---

🚀 **Your serverless order receiver application is now ready for production with a complete CI/CD pipeline!**
