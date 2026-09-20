variable "cluster_name" {
  description = "EKS cluster name (also used for the autoscaler discovery tag)."
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

variable "region" {
  description = "AWS region of the cluster."
  type        = string
}

variable "namespace" {
  description = "Namespace for the Cluster Autoscaler."
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Service account used by the Cluster Autoscaler."
  type        = string
  default     = "cluster-autoscaler"
}

variable "chart_version" {
  description = "Pinned cluster-autoscaler Helm chart version."
  type        = string
  default     = "9.59.0"
}

variable "image_tag" {
  description = "Cluster Autoscaler image tag; must match the cluster minor version."
  type        = string
  default     = "v1.36.0"
}

variable "replica_count" {
  description = "Number of autoscaler replicas."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
