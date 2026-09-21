variable "name" {
  description = "Short unique name for this runner (used in IAM role names)."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_arn" {
  description = "EKS cluster ARN (for eks:DescribeCluster scoping)."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster IAM OIDC provider."
  type        = string
}

variable "oidc_issuer" {
  description = "OIDC issuer URL of the cluster."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository the runner pushes to."
  type        = string
}

variable "extra_ecr_repository_arns" {
  description = "Additional ECR repository ARNs the runner may push to."
  type        = list(string)
  default     = []
}

variable "ssm_parameter_path" {
  description = "SSM parameter path prefix the runner may read (empty disables SSM access)."
  type        = string
  default     = ""
}

variable "github_config_url" {
  description = "GitHub repository URL the runner registers to."
  type        = string
}

variable "github_secret_secret_name" {
  description = "Name of the Kubernetes secret ARC reads for GitHub App credentials (created by modules/arc)."
  type        = string
  default     = "arc-github-app"
}

variable "runner_namespace" {
  description = "Namespace for the runner pods (created by modules/arc)."
  type        = string
  default     = "arc-runners"
}

variable "runner_scale_set_name" {
  description = "Runner scale set name, used as runs-on in workflows."
  type        = string
}

variable "release_name" {
  description = "Helm release name for the runner scale set."
  type        = string
}

variable "service_account_name" {
  description = "Service account used by the runner pods (IRSA)."
  type        = string
}

variable "chart_version" {
  description = "Pinned ARC Helm chart version."
  type        = string
  default     = "0.14.2"
}

variable "min_runners" {
  description = "Minimum idle runners."
  type        = number
  default     = 0
}

variable "max_runners" {
  description = "Maximum runners."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
