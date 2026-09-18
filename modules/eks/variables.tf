variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.36"
}

variable "subnet_ids" {
  description = "Private subnet IDs for the control plane and nodes."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 1
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_disk_size" {
  description = "Worker node root volume size in GiB."
  type        = number
  default     = 20
}

variable "cluster_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint. Empty disables public access."
  type        = list(string)
  default     = []
}

variable "cluster_enabled_log_types" {
  description = "Control plane log types to send to CloudWatch Logs."
  type        = list(string)
  default     = []
}

variable "admin_principal_arns" {
  description = "IAM principals granted cluster-admin access through EKS access entries."
  type        = list(string)
  default     = []
}

variable "addon_vpc_cni_version" {
  description = "Pinned version of the vpc-cni managed add-on."
  type        = string
  default     = "v1.22.4-eksbuild.3"
}

variable "addon_coredns_version" {
  description = "Pinned version of the coredns managed add-on."
  type        = string
  default     = "v1.14.3-eksbuild.23"
}

variable "addon_kube_proxy_version" {
  description = "Pinned version of the kube-proxy managed add-on."
  type        = string
  default     = "v1.36.0-eksbuild.25"
}

variable "addon_ebs_csi_version" {
  description = "Pinned version of the aws-ebs-csi-driver managed add-on."
  type        = string
  default     = "v1.66.0-eksbuild.1"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
