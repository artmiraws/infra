output "role_arn" {
  description = "ARN of the IRSA role used by the operator."
  value       = aws_iam_role.this.arn
}

output "namespace" {
  description = "Namespace of the operator."
  value       = var.namespace
}

output "service_account_name" {
  description = "Service account used by the operator."
  value       = var.service_account_name
}

output "secret_store_name" {
  description = "Name of the ClusterSecretStore."
  value       = var.secret_store_name
}

output "chart_version" {
  description = "Installed chart version."
  value       = var.chart_version
}
