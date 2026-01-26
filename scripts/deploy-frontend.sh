#!/bin/bash

set -e

FRONTEND_REPO=${1:-"https://github.com/username/starttech-frontend"}
BUILD_DIR="frontend-build"

echo "🚀 Deploying Frontend to S3..."

# Check if outputs.json exists
if [ ! -f "outputs.json" ]; then
    echo "❌ outputs.json not found. Please run deploy-infrastructure.sh first."
    exit 1
fi

# Extract S3 bucket name and CloudFront distribution ID
BUCKET_NAME=$(jq -r '.frontend_bucket_name.value' outputs.json)
DISTRIBUTION_ID=$(jq -r '.cloudfront_distribution_id.value' outputs.json)

if [ "$BUCKET_NAME" = "null" ] || [ "$DISTRIBUTION_ID" = "null" ]; then
    echo "❌ Could not extract bucket name or distribution ID from outputs.json"
    exit 1
fi

echo "📦 S3 Bucket: $BUCKET_NAME"
echo "🌐 CloudFront Distribution: $DISTRIBUTION_ID"

# Clone frontend repository if provided
if [ "$FRONTEND_REPO" != "local" ]; then
    echo "📥 Cloning frontend repository..."
    rm -rf $BUILD_DIR
    git clone $FRONTEND_REPO $BUILD_DIR
    cd $BUILD_DIR
else
    echo "📁 Using local frontend code..."
    cd frontend
fi

# Install dependencies and build
echo "📦 Installing dependencies..."
npm install

echo "🧪 Running tests..."
npm test -- --coverage --watchAll=false

echo "🔨 Building application..."
npm run build

# Deploy to S3
echo "☁️ Deploying to S3..."
aws s3 sync build/ s3://$BUCKET_NAME --delete

# Invalidate CloudFront cache
echo "🔄 Invalidating CloudFront cache..."
aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"

echo "✅ Frontend deployment complete!"
echo "🌍 Your application will be available at the CloudFront URL shortly."