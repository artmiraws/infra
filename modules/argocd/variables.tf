variable "namespace" {
  description = "Namespace for Argo CD."
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Pinned argo-cd Helm chart version."
  type        = string
  default     = "10.9.2"
}

variable "server_insecure" {
  description = "Run the Argo CD server in insecure (HTTP) mode so TLS terminates at the ingress/ALB."
  type        = bool
  default     = true
}

variable "ingress_enabled" {
  description = "Publish the Argo CD UI/API through an Ingress."
  type        = bool
  default     = false
}

variable "ingress_class_name" {
  description = "IngressClass for the Argo CD ingress (alb in this platform)."
  type        = string
  default     = "alb"
}

variable "ingress_host" {
  description = "Hostname for the Argo CD ingress (for example argocd.<base_domain>)."
  type        = string
  default     = ""
}

variable "ingress_annotations" {
  description = "Annotations for the Argo CD ingress (ALB scheme, certificate ARN, inbound CIDRs)."
  type        = map(string)
  default     = {}
}
