variable "bucket_name" {
  description = "Name of the S3 bucket for frontend"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}