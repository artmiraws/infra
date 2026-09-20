output "certificate_arn" {
  description = "ARN of the validated ACM certificate."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "hostname" {
  description = "Hostname covered by the certificate."
  value       = var.hostname
}
