#!/bin/bash

set -e

echo "🏥 StartTech Health Check..."

# Check if outputs.json exists
if [ ! -f "outputs.json" ]; then
    echo "❌ outputs.json not found. Please run deploy-infrastructure.sh first."
    exit 1
fi

# Extract endpoints
ALB_DNS=$(jq -r '.alb_dns_name.value' outputs.json)
CLOUDFRONT_DOMAIN=$(jq -r '.cloudfront_domain_name.value' outputs.json)

if [ "$ALB_DNS" = "null" ] || [ "$CLOUDFRONT_DOMAIN" = "null" ]; then
    echo "❌ Could not extract endpoints from outputs.json"
    exit 1
fi

echo "🎯 Backend API: http://$ALB_DNS"
echo "🌐 Frontend: https://$CLOUDFRONT_DOMAIN"
echo ""

# Backend health check
echo "🔍 Checking backend health..."
if curl -f -s "http://$ALB_DNS/health" > /dev/null; then
    echo "✅ Backend is healthy"
    curl -s "http://$ALB_DNS/health" | jq .
else
    echo "❌ Backend health check failed"
fi

echo ""

# Frontend health check
echo "🔍 Checking frontend availability..."
if curl -f -s -I "https://$CLOUDFRONT_DOMAIN" > /dev/null; then
    echo "✅ Frontend is accessible"
else
    echo "❌ Frontend is not accessible"
fi

echo ""

# Infrastructure status
echo "🏗️ Infrastructure Status:"
echo "- VPC: $(jq -r '.vpc_id.value' outputs.json)"
echo "- S3 Bucket: $(jq -r '.frontend_bucket_name.value' outputs.json)"
echo "- Redis Endpoint: $(jq -r '.redis_endpoint.value' outputs.json)"
echo "- Log Group: $(jq -r '.log_group_name.value' outputs.json)"

echo ""
echo "✅ Health check complete!"