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

variable "vpc_id" {
  description = "VPC ID where the load balancers are created."
  type        = string
}

variable "region" {
  description = "AWS region of the cluster."
  type        = string
}

variable "namespace" {
  description = "Namespace for the AWS Load Balancer Controller."
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Service account used by the controller."
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "chart_version" {
  description = "Pinned aws-load-balancer-controller Helm chart version."
  type        = string
  default     = "3.5.0"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
