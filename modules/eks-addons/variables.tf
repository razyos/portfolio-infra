variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "base_tags" {
  description = "Base tags to apply to all resources"
  type        = map(string)
}

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

variable "oidc_provider" {
  description = "The OIDC Provider URL for EKS"
  type        = string
}

# Variables for enabling/disabling EBS CSI Driver add-on and specifying its version
variable "enable_ebs_csi_driver_addon" {
  description = "Enable EBS CSI Driver add-on"
  type        = bool
}

variable "ebs_csi_driver_addon_version" {
  description = "Version of EBS CSI Driver add-on"
  type        = string
}
