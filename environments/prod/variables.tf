variable "project" {
  description = "Project name used as a prefix for resource names."
  type        = string
  default     = "todolist"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region for the dev environment."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the prod VPC (distinct from dev to keep routing unambiguous)."
  type        = string
  default     = "10.1.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones for subnets."
  type        = number
  default     = 2
}

variable "cluster_name" {
  description = "EKS cluster name used for Kubernetes subnet discovery tags."
  type        = string
  default     = "todolist-prod"
}

variable "budget_limit_usd" {
  description = "Monthly cost budget limit in USD."
  type        = number
  default     = 50
}

variable "budget_alert_emails" {
  description = "Email addresses that receive AWS Budget alerts."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the dev EKS cluster."
  type        = string
  default     = "1.36"
}

variable "node_instance_types" {
  description = "Instance types for the dev managed node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  description = "Desired number of dev worker nodes (2 for pod-density headroom on t3.small)."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of dev worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of dev worker nodes."
  type        = number
  default     = 2
}

variable "cluster_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. Empty keeps it private-only."
  type        = list(string)
  default     = []
}

variable "cluster_enabled_log_types" {
  description = "EKS control plane log types sent to CloudWatch Logs."
  type        = list(string)
  default     = []
}

variable "admin_principal_arns" {
  description = "IAM principals granted cluster-admin through EKS access entries."
  type        = list(string)
  default     = []
}

variable "db_engine_version" {
  description = "Aurora PostgreSQL engine version."
  type        = string
  default     = "18.4"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "todolist"
}

variable "db_master_username" {
  description = "Aurora master username."
  type        = string
  default     = "todolist"
}

variable "db_min_capacity" {
  description = "Minimum Aurora Serverless v2 capacity in ACUs."
  type        = number
  default     = 0.5
}

variable "db_max_capacity" {
  description = "Maximum Aurora Serverless v2 capacity in ACUs."
  type        = number
  default     = 2
}

variable "db_backup_retention_period" {
  description = "Aurora backup retention in days (longer than dev)."
  type        = number
  default     = 14
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot on destroy (prod takes a final snapshot)."
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Protect the Aurora cluster from deletion."
  type        = bool
  default     = true
}

variable "db_cloudwatch_logs_exports" {
  description = "Aurora log types exported to CloudWatch Logs."
  type        = list(string)
  default     = []
}

variable "base_domain" {
  description = "Base domain managed in Route53 (the hosted zone name)."
  type        = string
}

variable "app_subdomain" {
  description = "Subdomain prefix for the application hostname."
  type        = string
  default     = "prod.todolist"
}

variable "github_config_url" {
  description = "GitHub repository URL the self-hosted runners register to."
  type        = string
  default     = "https://github.com/artmiraws/todolist-app"
}

variable "github_app_secret_name" {
  description = "Secrets Manager secret name holding the GitHub App credentials (the app is repo-scoped and shared across environments)."
  type        = string
  default     = "todolist-dev/github-app"
}

variable "runner_scale_set_name" {
  description = "ARC runner scale set name used as runs-on in the environment's workflows."
  type        = string
  default     = "arc-runner-set-prod"
}

variable "app_namespace" {
  description = "Namespace for the application (owned by Argo CD)."
  type        = string
  default     = "todolist"
}

variable "app_repo_url" {
  description = "Application repository Argo CD reads the Helm chart from."
  type        = string
  default     = "https://github.com/artmiraws/todolist-app"
}
