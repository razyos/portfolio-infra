terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.59"
    }
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.base_tags, {
    Name                                        = "${var.env}-${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.base_tags, {
    Name = "${var.env}-${var.cluster_name}-igw"
  })
}

# ── Public Subnets ─────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  count                   = length(var.subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs[count.index]
  availability_zone       = var.final_azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.base_tags, {
    Name                                        = "${var.env}-${var.cluster_name}-public-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.base_tags, {
    Name = "${var.env}-${var.cluster_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ── Private Subnets ────────────────────────────────────────────────────────────

resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.final_azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.base_tags, {
    Name                                        = "${var.env}-${var.cluster_name}-private-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  })
}

# ── NAT Gateway ────────────────────────────────────────────────────────────────

resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.base_tags, {
    Name = "${var.env}-${var.cluster_name}-nat-eip"
  })
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(var.base_tags, {
    Name = "${var.env}-${var.cluster_name}-nat"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(var.base_tags, {
    Name = "${var.env}-${var.cluster_name}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ── Security Groups ────────────────────────────────────────────────────────────

resource "aws_security_group" "eks_cluster" {
  name        = "${var.env}-${var.cluster_name}-cluster-sg"
  description = "Controls access to the EKS cluster API server"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.base_tags, {
    Name = "${var.env}-${var.cluster_name}-cluster-sg"
  })
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.env}-${var.cluster_name}-node-sg"
  description = "Controls traffic between EKS worker nodes and the control plane"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.base_tags, {
    Name                                        = "${var.env}-${var.cluster_name}-node-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })
}

# Cluster SG egress: control plane can reach nodes (kubelet, metrics, logs)
resource "aws_security_group_rule" "cluster_egress_to_nodes" {
  description              = "Allow control plane to reach worker nodes"
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

# Node SG egress: HTTPS to anywhere for ECR pulls and AWS API calls
resource "aws_security_group_rule" "node_egress_https" {
  description       = "Allow nodes outbound HTTPS to AWS APIs and container registries"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_nodes.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Node SG egress: all traffic within the VPC (pod-to-pod, DNS, node-to-node)
resource "aws_security_group_rule" "node_egress_intra_vpc" {
  description       = "Allow nodes to communicate freely within the VPC"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes.id
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "node_to_node" {
  description              = "Allow worker nodes to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_outbound" {
  description              = "Allow cluster control plane to communicate with worker nodes"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  to_port                  = 65535
  type                     = "ingress"
}
