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

variable "zone_id" {
  description = "Route53 hosted zone ID."
  type        = string
}

variable "base_domain" {
  description = "Base domain managed in Route53."
  type        = string
}

variable "hostname" {
  description = "Hostname for the application certificate and DNS record."
  type        = string
}

variable "region" {
  description = "AWS region of the cluster."
  type        = string
}

variable "namespace" {
  description = "Namespace for ExternalDNS."
  type        = string
  default     = "external-dns"
}

variable "service_account_name" {
  description = "Service account used by ExternalDNS."
  type        = string
  default     = "external-dns"
}

variable "chart_version" {
  description = "Pinned external-dns Helm chart version."
  type        = string
  default     = "1.22.0"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
