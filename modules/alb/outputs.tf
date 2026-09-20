output "role_arn" {
  description = "ARN of the controller IRSA role."
  value       = aws_iam_role.this.arn
}

output "namespace" {
  description = "Namespace of the controller."
  value       = var.namespace
}

output "service_account_name" {
  description = "Service account used by the controller."
  value       = var.service_account_name
}

output "chart_version" {
  description = "Installed chart version."
  value       = var.chart_version
}
