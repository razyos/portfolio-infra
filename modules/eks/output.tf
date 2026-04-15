# Cluster Outputs
output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS Kubernetes API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_security_group_id" {
  description = "The cluster security group that was created by Amazon EKS for the cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.eks_cluster.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.eks_cluster.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

# Node Group Outputs
output "node_group_id" {
  description = "EKS Node Group ID"
  value       = aws_eks_node_group.main.id
}

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "Status of the EKS Node Group"
  value       = aws_eks_node_group.main.status
}

output "node_group_resources" {
  description = "List of objects containing information about underlying resources of the EKS Node Group"
  value       = aws_eks_node_group.main.resources
}

output "node_group_scaling_config" {
  description = "Scaling configuration of the Node Group"
  value       = aws_eks_node_group.main.scaling_config
}

output "node_group_iam_role_name" {
  description = "IAM role name of the EKS Node Group"
  value       = aws_iam_role.eks_nodes.name
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS Node Group"
  value       = aws_iam_role.eks_nodes.arn
}

# OIDC Provider
output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading https://)"
  value       = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

# Additional Outputs
output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_platform_version" {
  description = "Platform version of the cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = aws_eks_cluster.main.status
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}