variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS control plane (public)"
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "List of subnet IDs for the EKS worker nodes (private)"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for the EKS nodes"
  type        = string
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
}

variable "endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
}

variable "endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the EKS public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_cluster_sg_id" {
  description = "Security group ID for the EKS cluster"
  type        = string
}

variable "base_tags" {
  description = "Base tags to apply to all resources"
  type        = map(string)
}

variable "env" {
  description = "Environment name"
  type        = string
}
