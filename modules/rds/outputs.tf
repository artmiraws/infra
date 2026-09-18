output "cluster_id" {
  description = "Aurora cluster identifier."
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the Aurora cluster."
  value       = aws_rds_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster."
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster."
  value       = aws_rds_cluster.this.reader_endpoint
}

output "cluster_port" {
  description = "Port of the Aurora cluster."
  value       = aws_rds_cluster.this.port
}

output "database_name" {
  description = "Initial database name."
  value       = aws_rds_cluster.this.database_name
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master credentials."
  value       = try(aws_rds_cluster.this.master_user_secret[0].secret_arn, null)
  sensitive   = true
}

output "security_group_id" {
  description = "Security group ID of the database."
  value       = aws_security_group.this.id
}

output "subnet_group_name" {
  description = "Name of the database subnet group."
  value       = aws_db_subnet_group.this.name
}
