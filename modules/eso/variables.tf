variable "cluster_name" {
  description = "EKS cluster name, used to name the IRSA role and policy."
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

variable "namespace" {
  description = "Namespace for the External Secrets Operator."
  type        = string
  default     = "external-secrets"
}

variable "service_account_name" {
  description = "Service account used by the operator."
  type        = string
  default     = "external-secrets"
}

variable "chart_version" {
  description = "Pinned external-secrets Helm chart version."
  type        = string
  default     = "2.10.0"
}

variable "secret_arns" {
  description = "Secrets Manager secret ARNs the operator may read."
  type        = list(string)
}

variable "secret_store_name" {
  description = "Name of the ClusterSecretStore."
  type        = string
  default     = "aws-secrets-manager"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
