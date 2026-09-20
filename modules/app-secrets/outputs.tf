output "secret_arn" {
  description = "ARN of the application credentials secret."
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  description = "Name of the application credentials secret."
  value       = aws_secretsmanager_secret.this.name
}
