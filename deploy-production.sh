#!/bin/bash

# Production Deployment Script for Heroku
# This script adds Redis, updates environment variables, and deploys the production version

set -e  # Exit on any error

echo "🚀 Starting Production Deployment to Heroku..."

# Check if we're in the right directory
if [ ! -f "Procfile" ]; then
    echo "❌ Error: Procfile not found. Make sure you're in the project root directory."
    exit 1
fi

# Check if logged into Heroku
if ! heroku auth:whoami &>/dev/null; then
    echo "❌ Error: Not logged into Heroku. Please run 'heroku login' first."
    exit 1
fi

APP_NAME="wizz"
echo "📱 Deploying to Heroku app: $APP_NAME"

# Step 1: Add Redis add-on if not already present
echo "📦 Checking for Redis add-on..."
if heroku addons --app $APP_NAME | grep -q "heroku-redis"; then
    echo "✅ Redis add-on already exists"
else
    echo "➕ Adding Redis add-on..."
    heroku addons:create heroku-redis:premium-0 --app $APP_NAME
    echo "✅ Redis add-on added successfully"
fi

# Step 2: Set production environment variables
echo "🔧 Setting production environment variables..."

heroku config:set \
    ENVIRONMENT=production \
    USE_SIMPLIFIED_NOTIFICATIONS=true \
    --app $APP_NAME

# Check if MONGODB_URI exists
if heroku config:get MONGODB_URI --app $APP_NAME | grep -q "mongodb"; then
    echo "✅ MONGODB_URI already configured"
else
    echo "⚠️  MONGODB_URI not found. Please set it manually:"
    echo "   heroku config:set MONGODB_URI='your-mongodb-connection-string' --app $APP_NAME"
fi

# Step 3: Update Procfile to use production application
echo "📝 Updating Procfile for production..."
cat > Procfile << 'EOF'
web: cd backend && python -m uvicorn app.production_application:app --host 0.0.0.0 --port $PORT --workers 1
EOF

echo "✅ Procfile updated"

# Step 4: Commit changes
echo "📤 Committing production changes..."
git add .
if git diff --staged --quiet; then
    echo "ℹ️  No changes to commit"
else
    git commit -m "feat: add production application with Redis support

- Add Redis service for caching and real-time notifications
- Implement production database configuration with multiple TLS strategies
- Add comprehensive health checks and monitoring
- Include rate limiting and error handling middleware
- Update dependencies for Redis and SSL support"
    echo "✅ Changes committed"
fi

# Step 5: Deploy to Heroku
echo "🚀 Deploying to Heroku..."
git push heroku main

# Step 6: Wait for deployment and check health
echo "⏳ Waiting for deployment to complete..."
sleep 10

echo "🔍 Checking application health..."
HEALTH_URL="https://$APP_NAME-9fa6547f0499.herokuapp.com/health/detailed"

# Check health endpoint
if curl -s -f "$HEALTH_URL" > /dev/null; then
    echo "✅ Application deployed successfully!"
    echo "🌐 Health check: $HEALTH_URL"
    
    # Show detailed health status
    echo "📊 Health Status:"
    curl -s "$HEALTH_URL" | python3 -m json.tool
else
    echo "❌ Health check failed. Checking logs..."
    heroku logs --tail --app $APP_NAME
fi

# Step 7: Show application info
echo ""
echo "📋 Deployment Summary:"
echo "=================="
echo "🌐 Application URL: https://$APP_NAME-9fa6547f0499.herokuapp.com/"
echo "📖 API Documentation: https://$APP_NAME-9fa6547f0499.herokuapp.com/docs"
echo "🔍 Health Check: https://$APP_NAME-9fa6547f0499.herokuapp.com/health/detailed"
echo "📊 Metrics: https://$APP_NAME-9fa6547f0499.herokuapp.com/metrics"
echo ""
echo "🛠️  Useful Commands:"
echo "heroku logs --tail --app $APP_NAME  # View logs"
echo "heroku ps --app $APP_NAME            # Check dyno status"
echo "heroku config --app $APP_NAME        # View environment variables"
echo "heroku addons --app $APP_NAME        # View add-ons"
echo ""

# Step 8: Optional - open application
read -p "🌐 Open application in browser? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    heroku open --app $APP_NAME
fi

echo "🎉 Production deployment complete!"

# Step 9: Show next steps
echo ""
echo "🚀 Next Steps for Scaling to Production:"
echo "========================================"
echo "1. 🔍 Monitor application performance and errors"
echo "2. 📊 Set up proper monitoring (consider Heroku metrics add-ons)"
echo "3. 🔒 Configure proper CORS origins for your frontend"
echo "4. 📱 Update your Flutter app to use the new production API"
echo "5. 🌍 Consider migrating to AWS/GCP for better control and scaling"
echo "6. 💾 Set up database read replicas for better performance"
echo "7. 🔐 Implement proper authentication and authorization"
echo "8. 🚀 Add comprehensive monitoring and alerting"
echo ""
echo "📖 See PRODUCTION_IMPLEMENTATION_GUIDE.md for detailed next steps"
