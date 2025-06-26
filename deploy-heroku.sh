#!/bin/bash

# Heroku Deployment Script for Order Receiver App with Simplified Notifications
# =============================================================================

set -e  # Exit on any error

echo "🚀 Starting Heroku deployment with simplified notification system..."

# Check if we're in the right directory
if [ ! -f "Procfile" ]; then
    echo "❌ Error: Procfile not found. Are you in the project root directory?"
    exit 1
fi

# Check if user is logged into Heroku
if ! heroku auth:whoami > /dev/null 2>&1; then
    echo "❌ Error: Please login to Heroku first using 'heroku login'"
    exit 1
fi

# Configuration
APP_NAME=${1:-"order-receiver-app-simplified"}
REGION=${2:-"us"}

echo "📋 Deployment Configuration:"
echo "   App Name: $APP_NAME"
echo "   Region: $REGION"
echo ""

# Check if app exists
if heroku apps:info $APP_NAME > /dev/null 2>&1; then
    echo "✅ App '$APP_NAME' exists. Updating existing app..."
    DEPLOY_TYPE="update"
else
    echo "🆕 Creating new Heroku app '$APP_NAME'..."
    heroku create $APP_NAME --region $REGION
    DEPLOY_TYPE="create"
fi

# Set required environment variables
echo "⚙️ Setting environment variables..."

# Database - MongoDB Atlas (required)
if [ -z "$MONGODB_URI" ]; then
    echo "⚠️  Warning: MONGODB_URI not set. Please set it manually:"
    echo "   heroku config:set MONGODB_URI=\"your-mongodb-atlas-uri\" --app $APP_NAME"
else
    heroku config:set MONGODB_URI="$MONGODB_URI" --app $APP_NAME
fi

# JWT Secret
JWT_SECRET=$(openssl rand -hex 32)
heroku config:set JWT_SECRET="$JWT_SECRET" --app $APP_NAME

# Other essential config
heroku config:set \
    PYTHONPATH="/app/backend" \
    DEBUG="false" \
    CORS_ORIGINS="*" \
    USE_SIMPLIFIED_NOTIFICATIONS="true" \
    --app $APP_NAME

echo "✅ Environment variables configured"

# Set Python runtime
echo "🐍 Setting Python runtime..."
echo "python-3.11.0" > runtime.txt

# Ensure Procfile is correct for backend-only deployment
echo "📄 Checking Procfile..."
if [ ! -f "Procfile" ] || ! grep -q "uvicorn" Procfile; then
    echo "web: cd backend && uvicorn app.main:app --host 0.0.0.0 --port \$PORT" > Procfile
    echo "✅ Procfile created/updated"
fi

# Ensure we have the backend requirements.txt in the root
echo "📦 Preparing dependencies..."
cp backend/requirements.txt ./requirements.txt

# Add .gitignore for unnecessary files
cat > .slugignore << EOF
# Frontend files (not needed for backend-only deployment)
frontend/
android/
ios/
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
pubspec.lock

# Development files
*.md
docs/
tests/
.vscode/
.idea/

# Large files
*.log
*.cache
uploads/
EOF

echo "✅ Build configuration prepared"

# Commit changes if any
if [ -n "$(git status --porcelain)" ]; then
    echo "📝 Committing deployment configuration..."
    git add .
    git commit -m "Configure for Heroku deployment with simplified notifications"
fi

# Deploy to Heroku
echo "🚀 Deploying to Heroku..."
git push heroku main

# Open the app
echo "🌐 Opening deployed app..."
heroku open --app $APP_NAME

# Show logs
echo "📊 Showing recent logs..."
heroku logs --tail --app $APP_NAME &
LOGS_PID=$!

echo ""
echo "🎉 Deployment Complete!"
echo ""
echo "App URL: https://$APP_NAME.herokuapp.com"
echo "Health Check: https://$APP_NAME.herokuapp.com/health"
echo "API Docs: https://$APP_NAME.herokuapp.com/docs"
echo ""
echo "📋 Post-deployment checklist:"
echo "   1. ✅ App deployed successfully"
echo "   2. ⏳ Check health endpoint: curl https://$APP_NAME.herokuapp.com/health"
echo "   3. ⏳ Set up MongoDB Atlas if not done"
echo "   4. ⏳ Test notification endpoints"
echo "   5. ⏳ Configure frontend to use Heroku backend URL"
echo ""
echo "🔧 Useful commands:"
echo "   View logs: heroku logs --tail --app $APP_NAME"
echo "   Check config: heroku config --app $APP_NAME"
echo "   Restart app: heroku restart --app $APP_NAME"
echo "   Open shell: heroku run bash --app $APP_NAME"
echo ""
echo "📱 Frontend Configuration:"
echo "   Update the baseUrl in your Flutter app:"
echo "   const String baseUrl = 'https://$APP_NAME.herokuapp.com';"
echo ""

# Wait a bit before stopping logs
sleep 30
kill $LOGS_PID 2>/dev/null || true

echo "✅ Deployment script completed successfully!"
