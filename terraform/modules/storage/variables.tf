variable "bucket_name" {
  description = "Name of the S3 bucket for frontend"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Redis"
  type        = list(string)
}

variable "backend_security_group_id" {
  description = "ID of the backend SG to allow access to Redis"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
