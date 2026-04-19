variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "base_tags" {
  description = "Tags to apply to resources"
  type = map(string)
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "number_of_subnets" {
  description = "The number of subnets"
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name of the key pair to use for instances"
  type        = string
}

variable "env" {
  description = "Environment"
  type        = string
}

# EKS Cluster Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
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

# EKS Node Group Variables
variable "node_group_name" {
  description = "Name of the EKS node group"
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

# EKS Add-ons Variables
variable "enable_vpc_cni_addon" {
  description = "Enable VPC CNI add-on"
  type        = bool
}

variable "enable_coredns_addon" {
  description = "Enable CoreDNS add-on"
  type        = bool
}

variable "enable_kube_proxy_addon" {
  description = "Enable kube-proxy add-on"
  type        = bool
}

variable "vpc_cni_addon_version" {
  description = "Version of VPC CNI add-on"
  type        = string
}

variable "coredns_addon_version" {
  description = "Version of CoreDNS add-on"
  type        = string
}

variable "kube_proxy_addon_version" {
  description = "Version of kube-proxy add-on"
  type        = string
}

variable "enable_ebs_csi_driver_addon" {
  description = "Enable EBS CSI Driver add-on"
  type        = bool
}

variable "ebs_csi_driver_addon_version" {
  description = "Version of EBS CSI Driver add-on"
  type        = string
}

variable "argocd_namespace" {
  description = "Namespace to deploy ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Version of the ArgoCD Helm chart to install"
  type        = string
  default     = "7.7.0"
}

variable "argocd_values" {
  description = "Values to pass to the ArgoCD Helm chart"
  type        = any
  default     = {}
}

variable "github_repo_url" {
  description = "SSH URL of the GitHub charts repository"
  type        = string
}

variable "github_ssh_key_secret_name" {
  description = "Name of the AWS Secrets Manager secret containing the GitHub SSH key"
  type        = string
}

variable "github_repo_revision" {
  description = "GitHub repository revision (branch) to track"
  type        = string
  default     = "main"
}

variable "infra_apps_path" {
  description = "Path inside the GitHub repo that contains the ArgoCD ApplicationSets"
  type        = string
  default     = "sets"
}

