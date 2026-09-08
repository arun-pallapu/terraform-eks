locals {
  name = "${var.environment}-${var.cluster_name}"

  tags = {
    Environment = var.environment
    Project     = "terraform-eks"
    Terraform   = "true"
  }
}

# ------------------------------------------------------------
# VPC
# ------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.0"

  name = "${local.name}-vpc"
  cidr = "10.0.0.0/16"

  azs = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c"
  ]

  public_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24"
  ]

  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.tags
}

# ------------------------------------------------------------
# EKS Cluster
# ------------------------------------------------------------

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.25.0"

  name               = local.name
  kubernetes_version = var.eks_cluster_version

  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  # ----------------------------------------------------------
  # EKS Managed Node Group
  # ----------------------------------------------------------

  eks_managed_node_groups = {
    general = {
      name = "${local.name}-nodes"

      instance_types = var.eks_node_instance_types

      min_size     = var.eks_node_min_size
      max_size     = var.eks_node_max_size
      desired_size = var.eks_node_desired_size

      capacity_type = "ON_DEMAND"

      labels = {
        Environment = var.environment
        NodeGroup   = "general"
      }

      tags = {
        Name = "${local.name}-nodes"
      }
    }
  }

  # ----------------------------------------------------------
  # EKS Add-ons
  # ----------------------------------------------------------

  addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }

    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  # ----------------------------------------------------------
  # Networking
  # ----------------------------------------------------------

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  tags = local.tags
}

