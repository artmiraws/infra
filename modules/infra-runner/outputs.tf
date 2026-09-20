output "role_arn" {
  description = "ARN of the infra runner IRSA role."
  value       = aws_iam_role.this.arn
}

output "runner_scale_set_name" {
  description = "Infra runner scale set name (runs-on)."
  value       = var.runner_scale_set_name
}
