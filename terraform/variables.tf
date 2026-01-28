variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "starttech"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 6
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
  default     = "/aws/starttech/application"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "StartTech"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

variable "mongodb_atlas_public_key" {
  description = "MongoDB Atlas Public Key"
  type        = string
  sensitive   = true
}

variable "mongodb_atlas_private_key" {
  description = "MongoDB Atlas Private Key"
  type        = string
  sensitive   = true
}

variable "mongodb_atlas_org_id" {
  description = "MongoDB Atlas Organization ID"
  type        = string
}

variable "mongodb_atlas_password" {
  description = "MongoDB Atlas Database User Password"
  type        = string
  sensitive   = true
}

variable "use_secrets_manager" {
  description = "Whether to store/read MongoDB credentials from AWS Secrets Manager"
  type        = bool
  default     = false
}

variable "mongodb_secret_name" {
  description = "Name of the Secrets Manager secret to store MongoDB credentials (if enabled)"
  type        = string
  default     = ""
}

variable "github_org" {
  description = "GitHub organization name for OIDC"
  type        = string
  default     = "olaitansulyman"
}

variable "github_repo" {
  description = "GitHub repository name for OIDC"
  type        = string
  default     = "StartTech-infra-Olaitan-ALT-SOE-025-1200"
}
