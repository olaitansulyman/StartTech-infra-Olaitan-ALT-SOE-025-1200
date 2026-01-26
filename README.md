# StartTech Infrastructure - CI/CD Pipeline

## 🎯 Project Overview

Complete CI/CD pipeline infrastructure for StartTech's full-stack application using Terraform, GitHub Actions, and AWS services.

## 🏗️ Architecture

- **Frontend**: React → S3 + CloudFront
- **Backend**: Golang → EC2 Auto Scaling + ALB
- **Cache**: ElastiCache Redis
- **Database**: MongoDB Atlas
- **Infrastructure**: Terraform modules
- **CI/CD**: GitHub Actions

## 📋 Prerequisites

- AWS CLI configured
- Terraform v1.0+
- GitHub repository access
- MongoDB Atlas account

## 🚀 Quick Start

1. **Configure AWS credentials:**
   ```bash
   aws configure
   ```

2. **Initialize Terraform:**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Deploy via GitHub Actions:**
   - Push to main branch triggers infrastructure deployment
   - Application repositories trigger app deployments

## 📁 Repository Structure

```
starttech-infra/
├── .github/workflows/     # CI/CD pipelines
├── terraform/            # Infrastructure as Code
├── scripts/             # Deployment scripts
├── monitoring/          # CloudWatch configs
└── docs/               # Documentation
```

## 🔧 Infrastructure Components

- **Networking**: VPC, subnets, security groups
- **Compute**: EC2 Auto Scaling Group, ALB
- **Storage**: S3 bucket for frontend
- **CDN**: CloudFront distribution
- **Cache**: ElastiCache Redis cluster
- **Monitoring**: CloudWatch logs and metrics
- **Security**: IAM roles and policies

## 📊 Monitoring

- CloudWatch Logs for centralized logging
- Application metrics and alarms
- Health check endpoints
- Performance monitoring

## 🔒 Security

- IAM least-privilege policies
- Security group restrictions
- Secrets management
- Vulnerability scanning

## 🚨 Operations

See `RUNBOOK.md` for operational procedures and troubleshooting.