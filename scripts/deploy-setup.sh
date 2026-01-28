#!/bin/bash
# StartTech Infrastructure Deployment Setup Script
# This script guides you through the deployment process step-by-step

set -e

echo "🚀 StartTech Infrastructure Deployment Setup"
echo "============================================"
echo ""

# Step 1: Verify AWS Credentials
echo "Step 1: Verifying AWS Credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS credentials not configured. Run: aws configure"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
echo "✅ AWS Account ID: $ACCOUNT_ID"
echo "✅ Region: $AWS_REGION"
echo ""

# Step 2: Create S3 bucket for Terraform state
echo "Step 2: Setting up Terraform State Bucket..."
TFSTATE_BUCKET="starttech-tfstate-$ACCOUNT_ID"

if aws s3 ls s3://$TFSTATE_BUCKET 2>/dev/null; then
    echo "✅ State bucket exists: $TFSTATE_BUCKET"
else
    echo "📦 Creating state bucket: $TFSTATE_BUCKET"
    aws s3 mb s3://$TFSTATE_BUCKET --region $AWS_REGION
    aws s3api put-bucket-versioning --bucket $TFSTATE_BUCKET --versioning-configuration Status=Enabled
    aws s3api put-bucket-encryption --bucket $TFSTATE_BUCKET --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}
        }]
    }'
    echo "✅ State bucket created with versioning and encryption"
fi
echo ""

# Step 3: Create DynamoDB lock table
echo "Step 3: Setting up Terraform Lock Table..."
if aws dynamodb describe-table --table-name terraform-lock --region $AWS_REGION 2>/dev/null; then
    echo "✅ Lock table exists: terraform-lock"
else
    echo "📦 Creating lock table: terraform-lock"
    aws dynamodb create-table \
        --table-name terraform-lock \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region $AWS_REGION
    echo "✅ Lock table created"
    sleep 5
fi
echo ""

# Step 4: Check for terraform.tfvars
echo "Step 4: Checking Terraform Variables..."
cd terraform
if [ ! -f terraform.tfvars ]; then
    echo "⚠️  terraform.tfvars not found. Creating from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "📝 Please edit terraform.tfvars and add:"
    echo "   - mongodb_atlas_public_key"
    echo "   - mongodb_atlas_private_key"
    echo "   - mongodb_atlas_org_id"
    echo "   - mongodb_atlas_password"
    echo ""
    echo "Press Enter when ready, or Ctrl+C to edit now..."
    read
fi
echo "✅ terraform.tfvars found"
echo ""

# Step 5: Terraform Init
echo "Step 5: Initializing Terraform..."
terraform init -backend-config="bucket=$TFSTATE_BUCKET" -input=false
echo "✅ Terraform initialized"
echo ""

# Step 6: Terraform Validate
echo "Step 6: Validating Terraform Configuration..."
terraform validate
echo "✅ Configuration is valid"
echo ""

# Step 7: Terraform Plan
echo "Step 7: Planning Infrastructure Changes..."
terraform plan -out=tfplan
echo "✅ Plan created (tfplan)"
echo ""

# Step 8: Show summary
echo "📊 Deployment Summary"
echo "===================="
echo "Account ID: $ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo "State Bucket: $TFSTATE_BUCKET"
echo "Lock Table: terraform-lock"
echo ""

# Step 9: Apply
echo "🎯 Ready to Deploy?"
echo "Review the plan above. Type 'yes' to deploy, or 'no' to cancel:"
read -p "Deploy infrastructure? (yes/no): " DEPLOY

if [ "$DEPLOY" == "yes" ]; then
    echo "🚀 Deploying infrastructure..."
    terraform apply tfplan
    
    echo ""
    echo "✅ Infrastructure deployed successfully!"
    echo ""
    echo "📤 Saving outputs..."
    terraform output -json > ../outputs.json
    
    echo ""
    echo "🎉 Deployment Complete!"
    echo "========================"
    echo "Outputs saved to: outputs.json"
    echo ""
    echo "Next steps:"
    echo "1. Review outputs.json for resource details"
    echo "2. Set GitHub Actions secrets:"
    cat ../outputs.json | jq '{
        AWS_ACCOUNT_ID: .data.aws_caller_identity | "\($ACCOUNT_ID)",
        TFSTATE_BUCKET: "\($TFSTATE_BUCKET)",
        FRONTEND_S3_BUCKET: .frontend_bucket_name.value,
        CLOUDFRONT_DISTRIBUTION_ID: .cloudfront_distribution_id.value,
        ASG_NAME: .autoscaling_group_name.value
    }' 2>/dev/null || echo "   AWS_ACCOUNT_ID=$ACCOUNT_ID"
    echo ""
    echo "3. Test health endpoint:"
    echo "   ALB_DNS=\$(terraform output -raw alb_dns_name)"
    echo "   curl http://\$ALB_DNS/health"
else
    echo "Deployment cancelled."
    exit 0
fi
