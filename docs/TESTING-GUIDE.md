# Infrastructure Testing Guide

This document provides strategies to validate and test all infrastructure resources.

## Level 1: Pre-Deployment Validation

### 1.1 Terraform Format & Validation

```bash
cd terraform

# Check formatting
terraform fmt -recursive -check

# Fix formatting issues
terraform fmt -recursive

# Validate syntax
terraform validate

# Plan without applying (dry-run)
terraform plan -out=tfplan
```

### 1.2 Terraform Linting (Optional but recommended)

Install TFLint:
```bash
brew install tflint  # macOS
# or visit https://github.com/terraform-linters/tflint
```

Run linter:
```bash
cd terraform
tflint --init
tflint
```

## Level 2: Deployment Testing

### 2.1 Deploy to Staging/Dev Environment

```bash
# Create a separate tfvars for dev
cp terraform.tfvars terraform.tfvars.dev

# Edit with smaller resource sizes for testing
# - min_size = 1, desired_capacity = 1
# - node_type = cache.t3.micro (already set)
# - instance_type = t3.micro (already set)

# Deploy
terraform plan -var-file=terraform.tfvars.dev -out=tfplan.dev
terraform apply tfplan.dev

# Save outputs
terraform output -json > outputs-dev.json
```

### 2.2 Check Terraform State

```bash
# List all resources
terraform state list

# Show specific resource details
terraform state show 'module.networking.aws_vpc.main'
terraform state show 'module.compute.aws_lb.main'
terraform state show 'module.storage.aws_s3_bucket.frontend'

# Get all outputs
terraform output
```

## Level 3: AWS Console Verification

### 3.1 Networking Resources

Check in AWS Console:
```
VPC → VPCs
  ✓ VPC CIDR: 10.0.0.0/16
  ✓ DNS hostnames enabled
  ✓ DNS resolution enabled

VPC → Subnets
  ✓ Public subnets (2): 10.0.1.0/24, 10.0.2.0/24
  ✓ Private subnets (2): 10.0.10.0/24, 10.0.20.0/24
  ✓ All in correct AZs

VPC → Internet Gateways
  ✓ IGW attached to VPC

VPC → Route Tables
  ✓ Public routes: 0.0.0.0/0 → IGW
  ✓ Private routes: NAT Gateway configured
```

### 3.2 Compute Resources

```
EC2 → Instances
  ✓ Instances running (min_size count)
  ✓ Security groups attached
  ✓ Correct instance type (t3.micro)
  ✓ CloudWatch agent installed (user_data)

EC2 → Load Balancers
  ✓ ALB created and active
  ✓ Target group registered
  ✓ Health checks: /health endpoint
  ✓ Listener on port 80

EC2 → Auto Scaling Groups
  ✓ ASG created with correct min/max/desired
  ✓ Launch template configured
  ✓ Health check grace period set
```

### 3.3 Storage Resources

```
S3
  ✓ Frontend bucket created (starttech-frontend-starttech-ACCOUNT_ID)
  ✓ Bucket is private (block all public access)
  ✓ CloudFront OAC configured
  ✓ Bucket policy allows CloudFront

CloudFront
  ✓ Distribution created
  ✓ Origin points to S3
  ✓ Default root object: index.html
  ✓ Custom error response (404→index.html for SPA)
  ✓ HTTPS enabled
```

### 3.4 Caching & Database

```
ElastiCache
  ✓ Redis cluster created (cache.t3.micro)
  ✓ Subnet group configured
  ✓ Security group allows port 6379 from backend
  ✓ Encryption at rest enabled
  ✓ Encryption in transit enabled

MongoDB Atlas
  ✓ Project created
  ✓ Replica set cluster deployed (3 nodes)
  ✓ Database user created (admin)
  ✓ Network access configured
```

### 3.5 Monitoring

```
CloudWatch
  ✓ Log group created: /aws/starttech/application
  ✓ Retention: 14 days
  ✓ Dashboard created with ALB/EC2 metrics
  ✓ Alarms created (CPU high/low thresholds)

IAM
  ✓ EC2 instance role created
  ✓ Role policy allows CloudWatch logs
  ✓ GitHub Actions role created with OIDC
```

## Level 4: Functional Testing

### 4.1 Test ALB & Backend Health

```bash
# Get ALB DNS
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test health check endpoint
curl -v http://$ALB_DNS/health

# Expected response: 200 OK with JSON
# {"status":"healthy","timestamp":"...","service":"starttech-backend"}

# Test multiple times (ALB balances across instances)
for i in {1..5}; do
  echo "Request $i:"
  curl http://$ALB_DNS/health | jq .
  sleep 2
done
```

### 4.2 Test Redis Connectivity

From an EC2 instance in the same VPC:

```bash
# SSH into EC2 instance
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=starttech-backend-instance" \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)

aws ssm start-session --target $INSTANCE_ID

# Inside instance:
# Install redis-cli
sudo yum install -y redis

# Get Redis endpoint
REDIS_ENDPOINT=$(terraform output -raw redis_endpoint)

# Test connection
redis-cli -h $REDIS_ENDPOINT -p 6379 ping
# Expected: PONG
```

### 4.3 Test MongoDB Connectivity

```bash
# From backend instance or locally (if on VPN)
mongosh "mongodb+srv://admin:PASSWORD@starttech-cluster.mongodb.net/admin"

# Expected: Successfully connected
# Test read/write
db.test.insertOne({message: "Hello StartTech"})
db.test.findOne()
```

### 4.4 Test S3 & CloudFront

```bash
# Upload test file to S3
echo "<h1>StartTech Frontend</h1>" > index.html
aws s3 cp index.html s3://starttech-frontend-starttech-ACCOUNT_ID/index.html

# Test via CloudFront
CLOUDFRONT_URL=$(terraform output -raw cloudfront_domain_name)
curl https://$CLOUDFRONT_URL/

# Expected: HTML response with "StartTech Frontend"
```

## Level 5: Load & Stress Testing

### 5.1 Test Auto Scaling

```bash
# Generate load on ALB
ALB_DNS=$(terraform output -raw alb_dns_name)

# Using Apache Bench (ab)
ab -n 10000 -c 100 http://$ALB_DNS/health

# Monitor auto scaling in real-time
watch -n 5 "aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names starttech-backend-asg \
  --query 'AutoScalingGroups[0].{Desired:DesiredCapacity,Current:length(Instances),Min:MinSize,Max:MaxSize}' \
  --output table"

# Expected: Instance count increases when CPU > 80%
```

### 5.2 Monitor CloudWatch Metrics

```bash
# CPU Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=starttech-backend-asg \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# ALB Request Count
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=app/starttech-alb/xxxxx \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## Level 6: Security Testing

### 6.1 Test Security Groups

```bash
# Verify ALB is accessible from internet
nmap -p 80 $ALB_DNS

# Verify backend is NOT accessible from internet
# (should fail if security configured correctly)
nmap -p 8080 $(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=starttech-backend-instance" \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

# Should fail: Port closed or filtered
```

### 6.2 Test Encryption

```bash
# Redis: Check encryption in transit
redis-cli -h $REDIS_ENDPOINT --tls -p 6379 ping

# MongoDB: Check encryption
mongosh --tls "mongodb+srv://admin:PASSWORD@..."

# S3 → CloudFront: Verify HTTPS
curl -I https://$CLOUDFRONT_URL/
# Expected: HTTP/2 200, with security headers
```

## Level 7: Destroy & Cleanup Test

```bash
# Destroy all resources (after testing)
cd terraform
terraform destroy

# Verify cleanup in AWS Console
# - VPC, subnets, IGW gone
# - EC2 instances terminated
# - S3 bucket (empty, then delete manually if persistent)
# - RDS, ElastiCache, ALB all removed
```

## Quick Test Checklist

Run this minimal test suite:

```bash
#!/bin/bash
set -e

echo "=== Terraform Validation ==="
terraform validate

echo "=== Planning Deployment ==="
terraform plan -out=tfplan

echo "=== Checking State ==="
terraform state list

echo "=== Verifying Outputs ==="
terraform output

echo "=== All checks passed! Ready to apply ==="
```

Save as `test.sh` and run:
```bash
chmod +x test.sh
./test.sh
```

## Automated Testing with CI/CD

Your GitHub Actions workflows already include:
- ✅ Terraform fmt check
- ✅ Terraform validate
- ✅ Go tests (backend)
- ✅ npm tests (frontend)
- ✅ Trivy security scanning
- ✅ gosec Go security scan

These run automatically on push!
