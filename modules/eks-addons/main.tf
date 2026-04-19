terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.59"
    }
  }
}

# Declare the aws_caller_identity data source
data "aws_caller_identity" "current" {}

# EKS Add-ons Configuration

# VPC CNI (Container Network Interface) Add-on
# This add-on is responsible for IP address management and network interfaces in the cluster
resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni_addon ? 1 : 0 # Only create if enabled

  cluster_name = var.cluster_name
  addon_name   = "vpc-cni"

  # Use specified version or let AWS manage it
  addon_version = var.vpc_cni_addon_version

  # Automatically resolve conflicts with new versions
  resolve_conflicts_on_update = "PRESERVE"

  # Ensure proper IAM permissions are in place before creating the add-on
  depends_on = [aws_iam_role_policy_attachment.vpc_cni_policy]

  # Tags for the add-on
  tags = merge(
    var.base_tags,
    {
      "Name" = "${var.env}-${var.cluster_name}-vpc-cni-addon"
    }
  )
}

# CoreDNS Add-on
# This add-on provides DNS services within the cluster
resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns_addon ? 1 : 0 # Only create if enabled

  cluster_name = var.cluster_name
  addon_name   = "coredns"

  # Use specified version or let AWS manage it
  addon_version = var.coredns_addon_version

  # Automatically resolve conflicts with new versions
  resolve_conflicts_on_update = "PRESERVE"

  # Tags for the add-on
  tags = merge(
    var.base_tags,
    {
      "Name" = "${var.env}-${var.cluster_name}-coredns-addon"
    }
  )
}

# kube-proxy Add-on
# This add-on maintains network rules on each node for communication between pods
resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_kube_proxy_addon ? 1 : 0 # Only create if enabled

  cluster_name = var.cluster_name
  addon_name   = "kube-proxy"

  # Use specified version or let AWS manage it
  addon_version = var.kube_proxy_addon_version

  # Automatically resolve conflicts with new versions
  resolve_conflicts_on_update = "PRESERVE"

  # Tags for the add-on
  tags = merge(
    var.base_tags,
    {
      "Name" = "${var.env}-${var.cluster_name}-kube-proxy-addon"
    }
  )
}

# EBS CSI Driver Add-on
# This add-on provides the EBS CSI driver for dynamically provisioning EBS volumes
resource "aws_eks_addon" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver_addon ? 1 : 0 # Only create if enabled

  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  # Use specified version or let AWS manage it
  addon_version = var.ebs_csi_driver_addon_version

  # Automatically resolve conflicts with new versions
  resolve_conflicts_on_update = "PRESERVE"

  # Tags for the add-on
  tags = merge(
    var.base_tags,
    {
      "Name" = "${var.env}-${var.cluster_name}-ebs-csi-driver-addon"
    }
  )
}

# IAM Role for VPC CNI Add-on
# This role allows the VPC CNI add-on to manage ENIs and IP addresses
resource "aws_iam_role" "vpc_cni" {
  count = var.enable_vpc_cni_addon ? 1 : 0

  name = "${var.cluster_name}-vpc-cni-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_provider}"
      }
      Condition = {
        StringEquals = {
          "${var.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-node"
        }
      }
    }]
  })

  tags = merge(
    var.base_tags,
    {
      "Name" = "${var.env}-${var.cluster_name}-vpc-cni-role"
    }
  )
}

# Attach the necessary policy to the VPC CNI role
resource "aws_iam_role_policy_attachment" "vpc_cni_policy" {
  count = var.enable_vpc_cni_addon ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni[0].name
}

