variable "namespace" {
  description = "Namespace for metrics-server."
  type        = string
  default     = "kube-system"
}

variable "chart_version" {
  description = "Pinned metrics-server Helm chart version."
  type        = string
  default     = "3.14.0"
}
