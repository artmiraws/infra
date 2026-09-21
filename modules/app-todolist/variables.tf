variable "name" {
  description = "Name prefix for the application's resources (for example project-environment)."
  type        = string
}

variable "vpc_id" {
  description = "VPC the database lives in (owned by the platform)."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the database (owned by the platform)."
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the database."
  type        = list(string)
}

variable "db_engine_version" {
  description = "Aurora PostgreSQL engine version."
  type        = string
}

variable "database_name" {
  description = "Initial database name."
  type        = string
}

variable "master_username" {
  description = "Aurora master username."
  type        = string
}

variable "db_min_capacity" {
  description = "Minimum Aurora Serverless v2 capacity in ACUs."
  type        = number
}

variable "db_max_capacity" {
  description = "Maximum Aurora Serverless v2 capacity in ACUs."
  type        = number
}

variable "db_backup_retention_period" {
  description = "Aurora backup retention in days."
  type        = number
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot on destroy."
  type        = bool
}

variable "db_deletion_protection" {
  description = "Protect the Aurora cluster from deletion."
  type        = bool
}

variable "db_cloudwatch_logs_exports" {
  description = "Aurora log types exported to CloudWatch Logs."
  type        = list(string)
}

variable "app_secret_name" {
  description = "Secrets Manager secret name for the application credentials."
  type        = string
}

variable "hostname" {
  description = "Hostname the application is served on."
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID (owned by the platform)."
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL for the application image (owned by the platform)."
  type        = string
}

variable "app_name" {
  description = "Argo CD Application name (and Helm release name)."
  type        = string
}

variable "namespace" {
  description = "Destination namespace for the application's objects."
  type        = string
}

variable "repo_url" {
  description = "Application repository Argo CD reads the chart from."
  type        = string
}

variable "target_revision" {
  description = "Git revision Argo CD tracks."
  type        = string
  default     = "main"
}

variable "chart_path" {
  description = "Path to the Helm chart in the application repository."
  type        = string
}

variable "release_name" {
  description = "Helm release name Argo CD renders with."
  type        = string
}

variable "value_files" {
  description = "Helm value files committed in the application repository (relative to the chart)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
