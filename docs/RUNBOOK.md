# StartTech Operations Runbook

## Quick Reference

### Emergency Contacts
- **DevOps Team**: devops@starttech.com
- **On-Call Engineer**: +1-XXX-XXX-XXXX
- **AWS Support**: Enterprise Support Plan

### Critical Endpoints
- **Frontend**: https://CLOUDFRONT_DOMAIN
- **Backend API**: http://ALB_DNS_NAME
- **Health Check**: http://ALB_DNS_NAME/health
- **CloudWatch Dashboard**: [Dashboard URL]

## Common Operations

### 1. Deployment Procedures

#### Infrastructure Deployment
```bash
# Deploy infrastructure
./scripts/deploy-infrastructure.sh

# Verify deployment
./scripts/health-check.sh
```

#### Frontend Deployment
```bash
# Deploy from repository
./scripts/deploy-frontend.sh https://github.com/username/starttech-frontend

# Deploy local code
./scripts/deploy-frontend.sh local
```

#### Backend Deployment
```bash
# Deploy from repository
./scripts/deploy-backend.sh https://github.com/username/starttech-backend

# Deploy local code
./scripts/deploy-backend.sh local
```

### 2. Monitoring and Alerting

#### Check System Health
```bash
# Run comprehensive health check
./scripts/health-check.sh

# Check specific components
curl http://ALB_DNS_NAME/health
curl -I https://CLOUDFRONT_DOMAIN
```

#### CloudWatch Logs
```bash
# View application logs
aws logs tail /aws/starttech/application --follow

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/starttech/application \
  --filter-pattern "ERROR"
```

#### Metrics and Alarms
- **Dashboard**: CloudWatch Dashboard for real-time metrics
- **Alarms**: Automated alerts for critical thresholds
- **Log Insights**: Use predefined queries in `monitoring/log-insights-queries.txt`

### 3. Scaling Operations

#### Manual Scaling
```bash
# Scale up backend instances
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name starttech-backend-asg \
  --desired-capacity 4

# Scale down
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name starttech-backend-asg \
  --desired-capacity 2
```

#### Auto Scaling Configuration
```bash
# Update scaling policies
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name starttech-backend-asg \
  --policy-name starttech-scale-up \
  --scaling-adjustment 2 \
  --adjustment-type ChangeInCapacity
```

## Troubleshooting Guide

### 1. Frontend Issues

#### Site Not Loading
1. **Check CloudFront Status**
   ```bash
   aws cloudfront get-distribution --id DISTRIBUTION_ID
   ```

2. **Verify S3 Bucket**
   ```bash
   aws s3 ls s3://BUCKET_NAME
   aws s3 website s3://BUCKET_NAME
   ```

3. **Check DNS Resolution**
   ```bash
   nslookup CLOUDFRONT_DOMAIN
   curl -I https://CLOUDFRONT_DOMAIN
   ```

#### Slow Loading Times
1. **CloudFront Cache Analysis**
   - Check cache hit ratio in CloudWatch
   - Review cache behaviors and TTL settings

2. **S3 Performance**
   - Monitor S3 request metrics
   - Check for request rate limiting

### 2. Backend Issues

#### API Not Responding
1. **Check Load Balancer Health**
   ```bash
   aws elbv2 describe-target-health \
     --target-group-arn TARGET_GROUP_ARN
   ```

2. **Verify EC2 Instances**
   ```bash
   aws autoscaling describe-auto-scaling-groups \
     --auto-scaling-group-names starttech-backend-asg
   ```

3. **Check Application Logs**
   ```bash
   aws logs tail /aws/starttech/application --follow
   ```

#### High Response Times
1. **CPU and Memory Analysis**
   - Check CloudWatch EC2 metrics
   - Review application performance logs

2. **Database Performance**
   - Monitor MongoDB Atlas metrics
   - Check Redis cache hit rates

3. **Network Issues**
   - Verify security group rules
   - Check NAT Gateway performance

### 3. Database Issues

#### Redis Connection Problems
1. **Check ElastiCache Status**
   ```bash
   aws elasticache describe-replication-groups \
     --replication-group-id starttech-redis
   ```

2. **Network Connectivity**
   ```bash
   # From EC2 instance
   telnet REDIS_ENDPOINT 6379
   ```

#### MongoDB Atlas Issues
1. **Check Atlas Dashboard**
   - Monitor connection counts
   - Review performance metrics

2. **Connection String Validation**
   - Verify credentials and network access
   - Check IP whitelist settings

### 4. Infrastructure Issues

#### Auto Scaling Problems
1. **Check Scaling Activities**
   ```bash
   aws autoscaling describe-scaling-activities \
     --auto-scaling-group-name starttech-backend-asg
   ```

2. **Review Launch Template**
   ```bash
   aws ec2 describe-launch-templates \
     --launch-template-names starttech-backend-template
   ```

#### Network Connectivity
1. **VPC and Subnet Analysis**
   ```bash
   aws ec2 describe-vpcs
   aws ec2 describe-subnets
   aws ec2 describe-route-tables
   ```

2. **Security Group Rules**
   ```bash
   aws ec2 describe-security-groups \
     --group-names starttech-*
   ```

## Incident Response

### 1. Severity Levels

#### Critical (P1)
- Complete service outage
- Data loss or corruption
- Security breach

**Response Time**: 15 minutes
**Escalation**: Immediate

#### High (P2)
- Partial service degradation
- Performance issues affecting users
- Failed deployments

**Response Time**: 1 hour
**Escalation**: 2 hours

#### Medium (P3)
- Minor functionality issues
- Non-critical component failures

**Response Time**: 4 hours
**Escalation**: 24 hours

### 2. Incident Response Steps

1. **Acknowledge**: Confirm receipt of alert
2. **Assess**: Determine severity and impact
3. **Communicate**: Notify stakeholders
4. **Investigate**: Identify root cause
5. **Mitigate**: Implement temporary fix
6. **Resolve**: Apply permanent solution
7. **Document**: Create incident report

### 3. Rollback Procedures

#### Backend Rollback
```bash
# Rollback to previous version
./scripts/rollback.sh backend
```

#### Frontend Rollback
```bash
# Rollback frontend deployment
./scripts/rollback.sh frontend
```

#### Infrastructure Rollback
```bash
# Revert infrastructure changes
cd terraform
git checkout HEAD~1
terraform plan
terraform apply
```

## Maintenance Procedures

### 1. Regular Maintenance

#### Weekly Tasks
- Review CloudWatch alarms and metrics
- Check for security updates
- Validate backup procedures
- Review cost optimization opportunities

#### Monthly Tasks
- Update dependencies and packages
- Review and rotate secrets
- Analyze performance trends
- Update documentation

### 2. Security Maintenance

#### Patch Management
```bash
# Update EC2 instances
aws ssm send-command \
  --document-name "AWS-RunPatchBaseline" \
  --targets "Key=tag:Environment,Values=Production"
```

#### Certificate Management
- Monitor SSL certificate expiration
- Rotate access keys and secrets
- Review IAM policies and permissions

### 3. Performance Optimization

#### Resource Right-Sizing
- Analyze CloudWatch metrics
- Review instance utilization
- Optimize Auto Scaling policies

#### Cost Optimization
- Review AWS Cost Explorer
- Identify unused resources
- Implement Reserved Instances

## Backup and Recovery

### 1. Backup Procedures

#### Infrastructure Backup
- Terraform state files in S3
- Configuration files in version control
- AMI snapshots for EC2 instances

#### Application Backup
- MongoDB Atlas automated backups
- Application code in Git repositories
- Configuration and secrets backup

### 2. Recovery Procedures

#### Infrastructure Recovery
```bash
# Recreate infrastructure
cd terraform
terraform init
terraform plan
terraform apply
```

#### Application Recovery
```bash
# Redeploy applications
./scripts/deploy-backend.sh
./scripts/deploy-frontend.sh
```

## Contact Information

### Team Contacts
- **DevOps Lead**: devops-lead@starttech.com
- **Backend Team**: backend@starttech.com
- **Frontend Team**: frontend@starttech.com
- **Security Team**: security@starttech.com

### External Contacts
- **AWS Support**: [Support Case URL]
- **MongoDB Atlas**: [Atlas Support]
- **GitHub Support**: [GitHub Support]

## Additional Resources

- **AWS Documentation**: https://docs.aws.amazon.com/
- **Terraform Documentation**: https://registry.terraform.io/
- **GitHub Actions**: https://docs.github.com/en/actions
- **MongoDB Atlas**: https://docs.atlas.mongodb.com/