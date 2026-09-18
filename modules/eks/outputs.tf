output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "API server endpoint of the EKS cluster."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 certificate authority data for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version of the cluster."
  value       = aws_eks_cluster.this.version
}

output "cluster_security_group_id" {
  description = "Cluster security group ID created by EKS."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for IRSA."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_issuer" {
  description = "OIDC issuer URL of the cluster."
  value       = local.oidc_issuer
}

output "node_role_arn" {
  description = "ARN of the worker node IAM role."
  value       = aws_iam_role.node.arn
}

output "ebs_csi_role_arn" {
  description = "ARN of the EBS CSI driver IRSA role."
  value       = aws_iam_role.ebs_csi.arn
}

output "node_group_id" {
  description = "ID of the managed node group."
  value       = aws_eks_node_group.this.id
}
