# EKS Cluster
# This resource creates the main EKS cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  # VPC configuration for the cluster
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids      = [var.eks_cluster_sg_id]
  }

  # Logging configuration for the cluster
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  # Tags for the cluster
  tags = merge(
    var.base_tags, 
    { 
      Name = "${var.env}-${var.cluster_name}-Cluster" 
    }
  )

  # Ensure IAM role is created before the cluster
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# IAM Role for EKS Cluster
# This role allows the EKS service to manage resources on your behalf
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-eks-cluster-role"

  # Trust relationship policy
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.base_tags, 
    { 
      Name = "${var.env}-${var.cluster_name}-ClusterRole" 
    }
  )
}

# Attach the EKS cluster policy to the IAM role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# EKS Node Group
# This resource creates a managed node group for the EKS cluster
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.subnet_ids

  # Scaling configuration for the node group
  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = [var.instance_type]

  # Update strategy for the node group
  update_config {
    max_unavailable = 1
  }

  # Tags for the node group
  tags = merge(
    var.base_tags,
    {
      Name = "${var.env}-${var.cluster_name}-NodeGroup",
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )

  # Ensure IAM roles and policies are created before the node group
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_read_only,
    aws_iam_role_policy_attachment.ebs_volume_policy_attachment,  # Add this line
  ]
}

# IAM Role for EKS Nodes
# This role allows the EKS nodes to interact with other AWS services
resource "aws_iam_role" "eks_nodes" {
  name = "${var.cluster_name}-eks-node-group-role"

  # Trust relationship policy
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.base_tags, 
    { 
      Name = "${var.env}-${var.cluster_name}-NodeRole" 
    }
  )
}

# Attach necessary policies to the EKS Node IAM role
# Policy for EKS worker nodes
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

# Policy for Container Networking Interface (CNI)
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

# Policy for read-only access to EC2 Container Registry
resource "aws_iam_role_policy_attachment" "eks_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# Policy for managing EBS volumes
resource "aws_iam_policy" "ebs_volume_policy" {
  name        = "${var.cluster_name}-ebs-volume-policy"
  description = "Policy for allowing EKS nodes to manage EBS volumes"
 
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:CreateVolume",
          "ec2:AttachVolume",
          "ec2:DeleteVolume",
          "ec2:DescribeVolumes",
          "ec2:DetachVolume",
          "ec2:CreateTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the EBS volume management policy to the EKS Node IAM role
resource "aws_iam_role_policy_attachment" "ebs_volume_policy_attachment" {
  policy_arn = aws_iam_policy.ebs_volume_policy.arn
  role       = aws_iam_role.eks_nodes.name
}
