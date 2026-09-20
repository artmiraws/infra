output "certificate_arn" {
  description = "ARN of the validated ACM certificate."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "hostname" {
  description = "Hostname covered by the certificate."
  value       = var.hostname
}

output "external_dns_role_arn" {
  description = "ARN of the ExternalDNS IRSA role."
  value       = aws_iam_role.external_dns.arn
}

output "chart_version" {
  description = "Installed ExternalDNS chart version."
  value       = var.chart_version
}
