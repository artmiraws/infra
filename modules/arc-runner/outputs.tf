output "runner_role_name" {
  description = "Name of the runner's IRSA role (attach extra policies here)."
  value       = aws_iam_role.runner.name
}

output "runner_role_arn" {
  description = "ARN of the runner's IRSA role."
  value       = aws_iam_role.runner.arn
}

output "runner_scale_set_name" {
  description = "Runner scale set name, used as runs-on in workflows."
  value       = var.runner_scale_set_name
}
