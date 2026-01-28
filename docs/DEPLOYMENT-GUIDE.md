# Deployment Guide

This document walks through deploying the StartTech infrastructure and applications.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- GitHub account with repository access
- Docker (for building images locally)
- Go 1.20+ (for backend development)
- Node.js 18+ (for frontend development)

## Phase 1: Infrastructure Deployment

### Step 1: Set Up Terraform State

Create an S3 bucket for Terraform state (must be globally unique):

```bash
BUCKET_NAME="starttech-tfstate-$(aws sts get-caller-identity --query Account --output text)"
aws s3 mb s3://$BUCKET_NAME --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

Create DynamoDB lock table:

```bash
aws dynamodb create-table \
  --table-name terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### Step 2: Configure Terraform Variables

Copy the example file:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set:
- `aws_region`: Your AWS region (default: us-east-1)
- `project_name`: Project identifier (default: starttech)
- `vpc_cidr`, `public_subnet_cidrs`, `private_subnet_cidrs`: Network configuration
- `mongodb_atlas_public_key`, `mongodb_atlas_private_key`, `mongodb_atlas_org_id`: MongoDB Atlas credentials
- `mongodb_atlas_password`: Secure MongoDB user password
- `github_org`, `github_repo`: For GitHub Actions OIDC
```

### Step 3: Deploy Infrastructure Locally

```bash
cd terraform
terraform init -backend-config="bucket=$BUCKET_NAME"
terraform plan
terraform apply
```

Save the outputs:

```bash
terraform output -json > ../outputs.json
```

### Step 4: Set GitHub Actions Secrets

In your GitHub repository, go to Settings → Secrets and variables → Actions:

```bash
AWS_ACCOUNT_ID = "123456789012"  # Your AWS account ID
TFSTATE_BUCKET = "starttech-tfstate-123456789012"
FRONTEND_S3_BUCKET = "starttech-frontend-starttech-123456789012"
CLOUDFRONT_DISTRIBUTION_ID = "E123ABC456DEF"  # From terraform outputs
ASG_NAME = "starttech-backend-asg"  # From terraform outputs
```

## Phase 2: Application Deployment

### Frontend Deployment

Manually trigger:

```bash
# Sync React build to S3
aws s3 sync frontend/build/ s3://$FRONTEND_S3_BUCKET --delete

# Invalidate CloudFront
aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DISTRIBUTION_ID --paths "/*"
```

Or push to `frontend/` to trigger GitHub Actions pipeline.

### Backend Deployment

Local build and push to ECR:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=us-east-1
ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/starttech-backend"

# Build
cd backend
docker build -t starttech-backend:latest .

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

# Push
docker tag starttech-backend:latest $ECR_REPO:latest
docker push $ECR_REPO:latest

# Trigger rolling update
ASG_NAME=$(jq -r '.autoscaling_group_name.value' ../outputs.json)
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name $ASG_NAME \
  --preferences MinHealthyPercentage=50,InstanceWarmup=300
```

Or push to `backend/` to trigger GitHub Actions pipeline.

## Verification

Check deployment status:

```bash
# Get ALB DNS
ALB_DNS=$(jq -r '.alb_dns_name.value' outputs.json)

# Health check
curl http://$ALB_DNS/health

# CloudFront distribution
CLOUDFRONT_URL=$(jq -r '.cloudfront_domain_name.value' outputs.json)
curl https://$CLOUDFRONT_URL/
```

Check logs:

```bash
# Backend logs
aws logs tail /aws/starttech/application --follow

# ALB access logs
aws s3 ls s3://starttech-frontend-starttech-$ACCOUNT_ID/logs/
```

## Troubleshooting

**GitHub Actions: Role not found**
- Ensure Terraform deployed the OIDC provider and role
- Check AWS account ID in GitHub secrets

**Terraform: S3 backend access denied**
- Verify IAM user has S3 and DynamoDB permissions
- Check bucket policy allows the account

**Frontend not updating after deployment**
- Check CloudFront invalidation succeeded
- Clear browser cache or use `curl -I https://cloudfront-url`

**Backend pods not starting**
- Check EC2 user data logs: `cat /var/log/cloud-init-output.log`
- Verify security groups allow traffic from ALB to backend instances

## Rollback

To rollback infrastructure:

```bash
cd terraform
terraform destroy  # Destroys all resources
```

To rollback a backend deployment:

```bash
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name $ASG_NAME \
  --desired-configuration ImageId=ami-previous-id
```
