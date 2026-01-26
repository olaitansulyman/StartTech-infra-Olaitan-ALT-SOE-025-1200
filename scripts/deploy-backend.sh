#!/bin/bash

set -e

BACKEND_REPO=${1:-"https://github.com/username/starttech-backend"}
BUILD_DIR="backend-build"

echo "🚀 Deploying Backend to EC2..."

# Check if outputs.json exists
if [ ! -f "outputs.json" ]; then
    echo "❌ outputs.json not found. Please run deploy-infrastructure.sh first."
    exit 1
fi

# Extract Auto Scaling Group name and ALB DNS
ASG_NAME=$(jq -r '.autoscaling_group_name.value' outputs.json 2>/dev/null || echo "starttech-backend-asg")
ALB_DNS=$(jq -r '.alb_dns_name.value' outputs.json)

if [ "$ALB_DNS" = "null" ]; then
    echo "❌ Could not extract ALB DNS from outputs.json"
    exit 1
fi

echo "🎯 Auto Scaling Group: $ASG_NAME"
echo "🌐 Load Balancer: $ALB_DNS"

# Clone backend repository if provided
if [ "$BACKEND_REPO" != "local" ]; then
    echo "📥 Cloning backend repository..."
    rm -rf $BUILD_DIR
    git clone $BACKEND_REPO $BUILD_DIR
    cd $BUILD_DIR
else
    echo "📁 Using local backend code..."
    cd backend
fi

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t starttech-backend:latest .

# Get ECR login
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com

# Create ECR repository if it doesn't exist
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/starttech-backend"

aws ecr describe-repositories --repository-names starttech-backend 2>/dev/null || \
aws ecr create-repository --repository-name starttech-backend

# Tag and push image
echo "📤 Pushing to ECR..."
docker tag starttech-backend:latest $ECR_URI:latest
docker push $ECR_URI:latest

# Trigger rolling deployment
echo "🔄 Triggering rolling deployment..."
aws autoscaling start-instance-refresh \
    --auto-scaling-group-name $ASG_NAME \
    --preferences MinHealthyPercentage=50,InstanceWarmup=300

echo "⏳ Waiting for deployment to complete..."
aws autoscaling wait instance-refresh-successful --auto-scaling-group-name $ASG_NAME

# Health check
echo "🏥 Performing health check..."
for i in {1..10}; do
    if curl -f "http://$ALB_DNS/health"; then
        echo "✅ Health check passed!"
        break
    fi
    echo "⏳ Health check attempt $i failed, retrying in 30s..."
    sleep 30
done

echo "✅ Backend deployment complete!"
echo "🌍 API available at: http://$ALB_DNS"