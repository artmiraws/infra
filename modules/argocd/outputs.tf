output "namespace" {
  description = "Namespace Argo CD is installed into."
  value       = var.namespace
}

output "chart_version" {
  description = "Installed argo-cd chart version."
  value       = var.chart_version
}

output "server_service_name" {
  description = "In-cluster service for the Argo CD API/UI (reach it with kubectl port-forward)."
  value       = "argocd-server"
}
