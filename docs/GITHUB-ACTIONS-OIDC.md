# GitHub Actions OIDC Setup Guide

This guide explains how to set up GitHub Actions with AWS OIDC for secure, keyless authentication.

## Prerequisites

- AWS account with appropriate permissions
- GitHub repository with admin access
- Terraform installed locally

## Automatic Setup via Terraform

The `terraform/modules/github-oidc/` module creates:
- **OIDC Provider**: Connects GitHub to your AWS account
- **IAM Role**: Allows GitHub Actions to assume a role with specific permissions
- **Trust Policy**: Restricts access to your specific repository

### Variables Required

Add these to your `terraform.tfvars`:

```hcl
github_org  = "olaitansulyman"    # Your GitHub org/username
github_repo = "StartTech-infra-Olaitan-ALT-SOE-025-1200"  # Your infra repo name
```

### Deploy

```bash
cd terraform
terraform plan
terraform apply
```

The Terraform output will show the IAM role ARN.

## GitHub Secrets Configuration

Set these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

1. `AWS_ACCOUNT_ID`: Your AWS account ID (12 digits)
2. `TFSTATE_BUCKET`: Name of your S3 bucket for Terraform state
3. `FRONTEND_S3_BUCKET`: S3 bucket for frontend deployment
4. `CLOUDFRONT_DISTRIBUTION_ID`: CloudFront distribution ID
5. `ASG_NAME`: Auto Scaling Group name

## How It Works

1. **GitHub Actions requests token** from GitHub OIDC provider
2. **Token is passed to AWS STS** via `aws-actions/configure-aws-credentials@v2`
3. **AWS validates token** against the OIDC provider configuration
4. **STS returns temporary credentials** (valid for ~1 hour)
5. **GitHub Actions uses credentials** to deploy infrastructure and applications

## Security Benefits

✅ No long-lived AWS access keys stored as secrets  
✅ Short-lived credentials (~1 hour expiration)  
✅ Role-based access control (least privilege)  
✅ Audit trail via CloudTrail logs  
✅ Credential rotation automatic  

## Troubleshooting

**Error: "Not authorized to perform: sts:AssumeRoleWithWebIdentity"**
- Check that the OIDC provider thumbprint is correct
- Verify the trust policy in the IAM role
- Ensure GitHub repo matches `repo:org/repo:*` in the trust policy

**Error: "The role defined for the session does not have permission..."**
- Check IAM role policy has required permissions
- Add missing service permissions to the policy

## Additional Security Considerations

For production:
1. Narrow IAM role permissions (remove `"*"` resource)
2. Add resource-specific ARNs to the policy
3. Enable MFA delete on S3 bucket containing Terraform state
4. Enable S3 bucket versioning for state
5. Add DynamoDB lock table encryption
