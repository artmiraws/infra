output "vpc_id" {
  description = "ID of the dev VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the dev VPC."
  value       = module.vpc.vpc_cidr
}

output "azs" {
  description = "Availability zones used by the dev subnets."
  value       = module.vpc.azs
}

output "public_subnet_ids" {
  description = "IDs of the dev public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the dev private subnets."
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_id" {
  description = "ID of the dev NAT gateway."
  value       = module.vpc.nat_gateway_id
}

output "cluster_name" {
  description = "Name of the dev EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "API server endpoint of the dev EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the dev EKS cluster."
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 certificate authority data for the dev EKS cluster."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Cluster security group ID created by EKS."
  value       = module.eks.cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for IRSA."
  value       = module.eks.oidc_provider_arn
}

output "node_role_arn" {
  description = "ARN of the dev worker node IAM role."
  value       = module.eks.node_role_arn
}

output "db_cluster_endpoint" {
  description = "Writer endpoint of the dev Aurora cluster."
  value       = module.rds.cluster_endpoint
}

output "db_cluster_reader_endpoint" {
  description = "Reader endpoint of the dev Aurora cluster."
  value       = module.rds.cluster_reader_endpoint
}

output "db_cluster_port" {
  description = "Port of the dev Aurora cluster."
  value       = module.rds.cluster_port
}

output "db_name" {
  description = "Initial database name of the dev Aurora cluster."
  value       = module.rds.database_name
}

output "db_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the dev database credentials."
  value       = module.rds.master_user_secret_arn
  sensitive   = true
}
