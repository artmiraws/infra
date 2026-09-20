variable "project" {
  description = "Project name used as a prefix for resource names."
  type        = string
  default     = "todolist"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for the dev environment."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the dev VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones for subnets."
  type        = number
  default     = 2
}

variable "cluster_name" {
  description = "EKS cluster name used for Kubernetes subnet discovery tags."
  type        = string
  default     = "todolist-dev"
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
  description = "Aurora backup retention in days."
  type        = number
  default     = 7
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot on destroy (dev data is disposable)."
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Protect the Aurora cluster from deletion."
  type        = bool
  default     = false
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
  default     = "dev.todolist"
}

variable "github_config_url" {
  description = "GitHub repository URL the application's self-hosted runners register to."
  type        = string
  default     = "https://github.com/artmiraws/todolist-app"
}

variable "infra_repo_url" {
  description = "GitHub repository URL the platform pipeline runner registers to."
  type        = string
  default     = "https://github.com/artmiraws/platform"
}

variable "github_app_secret_name" {
  description = "Secrets Manager secret name holding the GitHub App credentials."
  type        = string
  default     = "todolist-dev/github-app"
}

variable "runner_scale_set_name" {
  description = "ARC runner scale set name used as runs-on in the environment's workflows."
  type        = string
  default     = "arc-runner-set"
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

variable "platform_docs_subdomain" {
  description = "Subdomain for the platform handbook (platform-docs)."
  type        = string
  default     = "platform-docs"
}

variable "platform_docs_repo_url" {
  description = "Repository holding the platform-docs Helm chart."
  type        = string
  default     = "https://github.com/artmiraws/platform-docs"
}

variable "platform_docs_namespace" {
  description = "Namespace for the platform handbook."
  type        = string
  default     = "platform-docs"
}

variable "platform_docs_enabled" {
  description = "Create the Argo CD Application for the platform handbook (requires the platform-docs repository)."
  type        = bool
  default     = false
}
