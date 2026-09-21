output "db_cluster_endpoint" {
  description = "Writer endpoint of the application's Aurora cluster."
  value       = module.rds.cluster_endpoint
}

output "db_cluster_reader_endpoint" {
  description = "Reader endpoint of the application's Aurora cluster."
  value       = module.rds.cluster_reader_endpoint
}

output "db_cluster_port" {
  description = "Port of the application's Aurora cluster."
  value       = module.rds.cluster_port
}

output "db_name" {
  description = "Initial database name."
  value       = module.rds.database_name
}

output "db_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the database credentials."
  value       = module.rds.master_user_secret_arn
  sensitive   = true
}

output "app_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the application credentials."
  value       = module.app_secrets.secret_arn
}

output "hostname" {
  description = "Hostname the application is served on."
  value       = module.acm.hostname
}

output "certificate_arn" {
  description = "ARN of the validated ACM certificate for the application hostname."
  value       = module.acm.certificate_arn
}
