variable "name" {
  description = "Name of the Argo CD Application."
  type        = string
}

variable "argocd_namespace" {
  description = "Namespace Argo CD runs in (where the Application lives)."
  type        = string
  default     = "argocd"
}

variable "namespace" {
  description = "Destination namespace for the application's Kubernetes objects."
  type        = string
}

variable "project" {
  description = "Argo CD project the Application belongs to."
  type        = string
  default     = "default"
}

variable "repo_url" {
  description = "Git repository holding the Helm chart."
  type        = string
}

variable "target_revision" {
  description = "Git revision (branch, tag, or commit) Argo CD tracks."
  type        = string
  default     = "main"
}

variable "chart_path" {
  description = "Path to the Helm chart inside the repository."
  type        = string
}

variable "value_files" {
  description = "Helm value files committed in the repository (relative to chart_path)."
  type        = list(string)
  default     = []
}

variable "values_object" {
  description = "Inline Helm values injected by OpenTofu (non-secret wiring; never committed)."
  type        = any
  default     = {}
}

variable "automated_sync" {
  description = "Enable Argo CD automated sync (prune + self-heal)."
  type        = bool
  default     = true
}

variable "destination_server" {
  description = "Destination cluster API server (in-cluster by default)."
  type        = string
  default     = "https://kubernetes.default.svc"
}
