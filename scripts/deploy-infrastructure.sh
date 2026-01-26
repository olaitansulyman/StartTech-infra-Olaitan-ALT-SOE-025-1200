#!/bin/bash

set -e

echo "🚀 Deploying StartTech Infrastructure..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform first."
    exit 1
fi

cd terraform

echo "📋 Initializing Terraform..."
terraform init

echo "🔍 Validating Terraform configuration..."
terraform validate

echo "📊 Planning infrastructure changes..."
terraform plan -out=tfplan

echo "🏗️ Applying infrastructure changes..."
terraform apply tfplan

echo "📤 Infrastructure outputs:"
terraform output

echo "✅ Infrastructure deployment complete!"

# Save outputs to file for other scripts
terraform output -json > ../outputs.json

echo "💾 Outputs saved to outputs.json"