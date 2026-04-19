output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster"
  value       = module.eks.cluster_version
}

output "oidc_provider" {
  description = "OIDC provider URL (without https://) — used for IRSA trust policies"
  value       = module.eks.oidc_provider
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "argocd_namespace" {
  description = "Namespace where ArgoCD is deployed"
  value       = module.argocd.argocd_namespace
}
