output "runner_role_arn" {
  description = "ARN of the runner IRSA role."
  value       = aws_iam_role.runner.arn
}

output "runner_scale_set_name" {
  description = "Runner scale set name (runs-on)."
  value       = var.runner_scale_set_name
}

output "service_account_name" {
  description = "Runner service account name."
  value       = var.service_account_name
}

output "controller_namespace" {
  description = "Namespace of the ARC controller."
  value       = var.controller_namespace
}

output "runner_namespace" {
  description = "Namespace of the runner pods."
  value       = var.runner_namespace
}

output "chart_version" {
  description = "Installed ARC chart version."
  value       = var.chart_version
}
