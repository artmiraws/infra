variable "cluster_name" {
  description = "EKS cluster name."
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

variable "github_config_url" {
  description = "GitHub repository URL the infra runners register to."
  type        = string
}

variable "github_secret_secret_name" {
  description = "Kubernetes secret ARC reads for GitHub App credentials (shared with the app runner)."
  type        = string
  default     = "arc-github-app"
}

variable "runner_namespace" {
  description = "Namespace for the runner pods."
  type        = string
  default     = "arc-runners"
}

variable "runner_scale_set_name" {
  description = "Infra runner scale set name (runs-on)."
  type        = string
  default     = "arc-infra-runner"
}

variable "service_account_name" {
  description = "Service account used by the infra runner pods (IRSA)."
  type        = string
  default     = "arc-infra-runner"
}

variable "chart_version" {
  description = "Pinned ARC runner scale set chart version."
  type        = string
  default     = "0.14.2"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
