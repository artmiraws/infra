variable "name" {
  description = "Cluster identifier and name prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the database security group."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the database subnet group."
  type        = list(string)
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version."
  type        = string
  default     = "18.4"
}

variable "database_name" {
  description = "Initial database name."
  type        = string
  default     = "todolist"
}

variable "master_username" {
  description = "Master username for the cluster."
  type        = string
  default     = "todolist"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to PostgreSQL."
  type        = list(string)
  default     = []
}

variable "min_capacity" {
  description = "Minimum Aurora Serverless v2 capacity in ACUs."
  type        = number
  default     = 0.5

  validation {
    condition     = var.min_capacity >= 0
    error_message = "min_capacity must be greater than or equal to 0."
  }
}

variable "max_capacity" {
  description = "Maximum Aurora Serverless v2 capacity in ACUs."
  type        = number
  default     = 2
}

variable "backup_retention_period" {
  description = "Number of days to retain backups."
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot when the cluster is destroyed."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Protect the cluster from deletion."
  type        = bool
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Log types exported to CloudWatch Logs."
  type        = list(string)
  default     = []
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during the maintenance window."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
