# StartTech CI/CD Pipeline - Setup Guide

## 🎯 Project Overview

This guide will help you set up a complete CI/CD pipeline for StartTech's full-stack application with:

- **Frontend**: React application deployed to S3 + CloudFront
- **Backend**: Golang API deployed to EC2 with Auto Scaling
- **Infrastructure**: Terraform-managed AWS resources
- **CI/CD**: GitHub Actions automation
- **Monitoring**: CloudWatch logs and metrics

## 📁 Repository Structure

You'll create two repositories:

1. **starttech-infra-olaitansulyman-3316**: Infrastructure and deployment automation
2. **starttech-olaitansulyman-3316**: Application code (frontend + backend)

## 🚀 Quick Setup

### Step 1: Create GitHub Repositories

1. Create two new repositories on GitHub:
   - `starttech-infra-olaitansulyman-3316` (Infrastructure)
   - `starttech-olaitansulyman-3316` (Application)

2. Clone and push the generated code:

```bash
# Infrastructure repository
cd /tmp/starttech-infra-olaitansulyman-3316
git init
git add .
git commit -m "Initial infrastructure setup"
git remote add origin https://github.com/YOUR_USERNAME/starttech-infra-olaitansulyman-3316.git
git push -u origin main

# Application repository
cd /tmp/starttech-olaitansulyman-3316
git init
git add .
git commit -m "Initial application setup"
git remote add origin https://github.com/YOUR_USERNAME/starttech-olaitansulyman-3316.git
git push -u origin main
```

### Step 2: Configure AWS Credentials

1. Create an IAM user with the following policies:
   - `AmazonEC2FullAccess`
   - `AmazonS3FullAccess`
   - `AmazonVPCFullAccess`
   - `ElastiCacheFullAccess`
   - `CloudFrontFullAccess`
   - `CloudWatchFullAccess`
   - `AutoScalingFullAccess`
   - `ElasticLoadBalancingFullAccess`
   - `IAMFullAccess`

2. Generate access keys for the IAM user

### Step 3: Configure GitHub Secrets

Add the following secrets to both repositories:

#### Infrastructure Repository Secrets:
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

#### Application Repository Secrets:
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `S3_BUCKET_NAME`: Will be set after infrastructure deployment
- `CLOUDFRONT_DISTRIBUTION_ID`: Will be set after infrastructure deployment
- `ASG_NAME`: Will be set after infrastructure deployment
- `ALB_DNS_NAME`: Will be set after infrastructure deployment
- `REACT_APP_API_URL`: Will be set after infrastructure deployment

### Step 4: Deploy Infrastructure

1. Update `terraform/terraform.tfvars.example` with your values:

```hcl
aws_region = "us-east-1"
project_name = "starttech"
environment = "prod"
frontend_bucket_name = "starttech-frontend-bucket-unique-12345"  # Must be globally unique
```

2. Rename to `terraform.tfvars` and deploy:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

3. Note the outputs and update GitHub secrets in the application repository

### Step 5: Set Up MongoDB Atlas

1. Create a MongoDB Atlas account
2. Create a new cluster
3. Get the connection string
4. Add to your backend environment variables

### Step 6: Test Deployments

1. Push changes to trigger CI/CD pipelines
2. Monitor GitHub Actions workflows
3. Verify deployments using health check scripts

## 🔧 Configuration Details

### Infrastructure Configuration

The infrastructure includes:

- **VPC**: Custom VPC with public/private subnets
- **EC2**: Auto Scaling Group with Application Load Balancer
- **S3**: Static website hosting for frontend
- **CloudFront**: CDN for global distribution
- **ElastiCache**: Redis cluster for caching
- **CloudWatch**: Centralized logging and monitoring

### Application Configuration

#### Frontend (React)
- Environment variables in `.env` files
- Build optimization for production
- Health check endpoints
- CORS configuration

#### Backend (Golang)
- RESTful API with health endpoints
- Graceful shutdown handling
- Request logging middleware
- Docker containerization

### CI/CD Pipeline Features

- **Automated Testing**: Unit tests and security scans
- **Multi-stage Builds**: Optimized Docker images
- **Rolling Deployments**: Zero-downtime deployments
- **Health Checks**: Automated verification
- **Rollback Support**: Quick recovery mechanisms

## 📊 Monitoring and Observability

### CloudWatch Integration
- Application logs centralized in CloudWatch
- Custom metrics and dashboards
- Automated alarms for critical thresholds
- Log Insights queries for analysis

### Health Monitoring
- Frontend: Nginx health endpoint
- Backend: `/health` API endpoint
- Infrastructure: AWS service health checks
- End-to-end: Automated health verification

## 🔒 Security Best Practices

### Network Security
- Private subnets for backend services
- Security groups with minimal access
- NAT Gateways for secure internet access

### Application Security
- HTTPS enforcement via CloudFront
- Container vulnerability scanning
- Secrets management via GitHub Secrets
- IAM roles with least-privilege access

### CI/CD Security
- Automated security audits
- Dependency vulnerability scanning
- Container image security scanning
- Secure artifact handling

## 🚨 Troubleshooting

### Common Issues

1. **Terraform Apply Fails**
   - Check AWS credentials and permissions
   - Verify S3 bucket name is globally unique
   - Ensure region consistency

2. **GitHub Actions Fail**
   - Verify all required secrets are set
   - Check AWS service limits
   - Review CloudWatch logs for errors

3. **Application Not Accessible**
   - Verify security group rules
   - Check Auto Scaling Group health
   - Validate DNS resolution

4. **Health Checks Fail**
   - Check application logs in CloudWatch
   - Verify load balancer target health
   - Test endpoints manually

### Debug Commands

```bash
# Check infrastructure status
./scripts/health-check.sh

# View Terraform outputs
cd terraform && terraform output

# Check AWS resources
aws elbv2 describe-load-balancers
aws autoscaling describe-auto-scaling-groups
aws s3 ls

# View application logs
aws logs tail /aws/starttech/application --follow
```

## 📚 Additional Resources

### Documentation
- [Architecture Overview](docs/ARCHITECTURE.md)
- [Operations Runbook](docs/RUNBOOK.md)
- [AWS Best Practices](https://aws.amazon.com/architecture/well-architected/)

### Monitoring
- CloudWatch Dashboard: Available after deployment
- Log Insights: Pre-configured queries in `monitoring/`
- Alarms: Automated alerts for critical metrics

### Scripts
- `deploy-infrastructure.sh`: Deploy AWS infrastructure
- `deploy-frontend.sh`: Deploy React application
- `deploy-backend.sh`: Deploy Golang API
- `health-check.sh`: Verify system health
- `rollback.sh`: Emergency rollback procedures

## ✅ Verification Checklist

After setup, verify:

- [ ] Both repositories created and code pushed
- [ ] AWS credentials configured with proper permissions
- [ ] GitHub secrets configured in both repositories
- [ ] Infrastructure deployed successfully via Terraform
- [ ] MongoDB Atlas cluster created and accessible
- [ ] Frontend accessible via CloudFront URL
- [ ] Backend API responding to health checks
- [ ] CI/CD pipelines triggering on code changes
- [ ] Monitoring dashboards showing metrics
- [ ] Log aggregation working in CloudWatch

## 🎉 Success Criteria

Your CI/CD pipeline is successful when:

1. **Infrastructure**: All AWS resources provisioned and healthy
2. **Frontend**: React app accessible globally via CloudFront
3. **Backend**: Golang API responding with proper health status
4. **CI/CD**: Automated deployments working on code changes
5. **Monitoring**: Logs and metrics flowing to CloudWatch
6. **Security**: All security scans passing in pipelines
7. **Performance**: Applications responding within acceptable limits

## 📞 Support

For issues or questions:
- Review the troubleshooting section
- Check CloudWatch logs for detailed error information
- Consult the operations runbook for common procedures
- Review AWS documentation for service-specific issues

---

**🚀 You now have a production-ready CI/CD pipeline for your full-stack application!**