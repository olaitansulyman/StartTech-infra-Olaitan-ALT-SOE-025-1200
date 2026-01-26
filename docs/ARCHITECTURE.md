# StartTech System Architecture

## Overview

StartTech is a modern full-stack application deployed on AWS using Infrastructure as Code (Terraform) and automated CI/CD pipelines (GitHub Actions).

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          Internet                                │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                 CloudFront CDN                                  │
│              (Global Distribution)                              │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                    S3 Bucket                                    │
│               (Static Frontend)                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          Internet                                │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│              Application Load Balancer                          │
│                 (Public Subnets)                               │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                Auto Scaling Group                               │
│              (EC2 Instances - Private)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   EC2-1     │  │   EC2-2     │  │   EC2-N     │            │
│  │ (Backend)   │  │ (Backend)   │  │ (Backend)   │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                ElastiCache Redis                                │
│                 (Private Subnet)                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   MongoDB Atlas                                 │
│                 (External Service)                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                  CloudWatch Logs                                │
│              (Centralized Logging)                              │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### Frontend (React Application)
- **Hosting**: Amazon S3 with static website hosting
- **CDN**: CloudFront for global content delivery
- **Build Process**: Node.js build pipeline with npm
- **Deployment**: Automated via GitHub Actions

### Backend (Golang API)
- **Compute**: EC2 instances in Auto Scaling Group
- **Load Balancing**: Application Load Balancer
- **Container**: Docker containerization with ECR
- **Scaling**: Auto Scaling based on CPU utilization
- **Health Checks**: ALB health checks on `/health` endpoint

### Database
- **Primary**: MongoDB Atlas (managed service)
- **Cache**: ElastiCache Redis cluster
- **Persistence**: EBS volumes for EC2 instances

### Networking
- **VPC**: Custom VPC with public and private subnets
- **Availability Zones**: Multi-AZ deployment for high availability
- **Security Groups**: Restrictive security group rules
- **NAT Gateways**: For private subnet internet access

### Monitoring & Logging
- **Logs**: CloudWatch Logs with structured logging
- **Metrics**: CloudWatch metrics and custom dashboards
- **Alarms**: Automated alerting for critical metrics
- **Health Monitoring**: Application and infrastructure health checks

## Security

### Network Security
- Private subnets for backend and database
- Security groups with least-privilege access
- NAT Gateways for secure outbound internet access

### Application Security
- HTTPS enforcement via CloudFront
- IAM roles with minimal required permissions
- Secrets management for sensitive configuration
- Container image vulnerability scanning

### Data Security
- Encryption at rest for ElastiCache Redis
- Encryption in transit for all communications
- MongoDB Atlas with built-in security features

## Scalability

### Horizontal Scaling
- Auto Scaling Group for EC2 instances
- CloudFront for global content distribution
- ElastiCache Redis for session management

### Vertical Scaling
- Configurable instance types
- EBS volume optimization
- Database scaling via MongoDB Atlas

## High Availability

### Multi-AZ Deployment
- Resources distributed across multiple AZs
- Load balancer health checks
- Auto Scaling Group maintains desired capacity

### Fault Tolerance
- Rolling deployments with zero downtime
- Health check endpoints for all services
- Automated failover mechanisms

## CI/CD Pipeline

### Infrastructure Pipeline
- Terraform for Infrastructure as Code
- Automated validation and planning
- Environment-specific configurations

### Application Pipelines
- Separate pipelines for frontend and backend
- Automated testing and security scanning
- Rolling deployments with health checks

## Monitoring Strategy

### Application Monitoring
- Request/response metrics
- Error rate tracking
- Performance monitoring
- User session analytics

### Infrastructure Monitoring
- Resource utilization metrics
- Network performance
- Storage metrics
- Cost optimization insights

## Disaster Recovery

### Backup Strategy
- MongoDB Atlas automated backups
- Infrastructure state in Terraform
- Application code in version control

### Recovery Procedures
- Automated rollback mechanisms
- Infrastructure recreation via Terraform
- Database point-in-time recovery

## Cost Optimization

### Resource Optimization
- Right-sized EC2 instances
- Auto Scaling based on demand
- CloudFront caching to reduce origin load
- Reserved instances for predictable workloads

### Monitoring
- Cost allocation tags
- Budget alerts
- Resource utilization tracking