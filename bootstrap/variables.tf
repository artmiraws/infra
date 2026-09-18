variable "project" {
  description = "Project name used as a prefix for resource names."
  type        = string
  default     = "todolist"
}

variable "aws_region" {
  description = "AWS region for the state bucket."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_prefix" {
  description = "Prefix for the state bucket name; the account ID is appended for global uniqueness."
  type        = string
  default     = "todolist-tfstate"
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which noncurrent object versions expire."
  type        = number
  default     = 90
}
