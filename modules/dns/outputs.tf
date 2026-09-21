output "external_dns_role_arn" {
  description = "ARN of the ExternalDNS IRSA role."
  value       = aws_iam_role.external_dns.arn
}

output "chart_version" {
  description = "Installed ExternalDNS chart version."
  value       = var.chart_version
}
