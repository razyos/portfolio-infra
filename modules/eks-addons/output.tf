output "vpc_cni_addon_id" {
  description = "ID of the VPC CNI add-on"
  value       = var.enable_vpc_cni_addon ? aws_eks_addon.vpc_cni[0].id : null
}

output "vpc_cni_addon_arn" {
  description = "ARN of the VPC CNI add-on"
  value       = var.enable_vpc_cni_addon ? aws_eks_addon.vpc_cni[0].arn : null
}

output "vpc_cni_addon_version" {
  description = "Version of the VPC CNI add-on"
  value       = var.enable_vpc_cni_addon ? aws_eks_addon.vpc_cni[0].addon_version : null
}

output "coredns_addon_id" {
  description = "ID of the CoreDNS add-on"
  value       = var.enable_coredns_addon ? aws_eks_addon.coredns[0].id : null
}

output "coredns_addon_arn" {
  description = "ARN of the CoreDNS add-on"
  value       = var.enable_coredns_addon ? aws_eks_addon.coredns[0].arn : null
}

output "coredns_addon_version" {
  description = "Version of the CoreDNS add-on"
  value       = var.enable_coredns_addon ? aws_eks_addon.coredns[0].addon_version : null
}

output "kube_proxy_addon_id" {
  description = "ID of the kube-proxy add-on"
  value       = var.enable_kube_proxy_addon ? aws_eks_addon.kube_proxy[0].id : null
}

output "kube_proxy_addon_arn" {
  description = "ARN of the kube-proxy add-on"
  value       = var.enable_kube_proxy_addon ? aws_eks_addon.kube_proxy[0].arn : null
}

output "kube_proxy_addon_version" {
  description = "Version of the kube-proxy add-on"
  value       = var.enable_kube_proxy_addon ? aws_eks_addon.kube_proxy[0].addon_version : null
}

output "vpc_cni_role_arn" {
  description = "ARN of the IAM role for VPC CNI"
  value       = var.enable_vpc_cni_addon ? aws_iam_role.vpc_cni[0].arn : null
}

output "vpc_cni_role_name" {
  description = "Name of the IAM role for VPC CNI"
  value       = var.enable_vpc_cni_addon ? aws_iam_role.vpc_cni[0].name : null
}