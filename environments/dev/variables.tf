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
  description = "Desired number of dev worker nodes."
  type        = number
  default     = 1
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
