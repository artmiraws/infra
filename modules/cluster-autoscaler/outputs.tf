output "role_arn" {
  description = "ARN of the Cluster Autoscaler IRSA role."
  value       = aws_iam_role.this.arn
}

output "chart_version" {
  description = "Installed cluster-autoscaler chart version."
  value       = var.chart_version
}

output "image_tag" {
  description = "Cluster Autoscaler image tag."
  value       = var.image_tag
}
