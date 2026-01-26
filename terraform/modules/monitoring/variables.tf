variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}