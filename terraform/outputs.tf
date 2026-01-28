output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.compute.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.compute.alb_zone_id
}

output "frontend_bucket_name" {
  description = "Name of the S3 bucket for frontend"
  value       = module.storage.bucket_name
}

output "frontend_bucket_domain" {
  description = "Domain name of the S3 bucket"
  value       = module.storage.bucket_domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.storage.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.storage.cloudfront_domain_name
}

output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = module.storage.redis_endpoint
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = module.monitoring.log_group_name
}