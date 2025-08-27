#!/bin/bash
echo "🚀 Deploying working hours fix..."

cd /Users/ghaythallaheebi/order-receiver-app-2/backend

echo "📦 Building SAM application..."
sam build --no-cached

echo "🌩️ Deploying to AWS..."
AWS_PROFILE=wizz-merchants-dev sam deploy --no-confirm-changeset

echo "✅ Deployment complete!"
