################################################################################
# PROVIDER
################################################################################

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      terraform = "true"
    }
  }
}

################################################################################
# COMMON
################################################################################

locals {
  cluster_name = var.cluster_name
  tags = {
    project_code = "PO-1234"
    environment  = "shared"
  }
}

################################################################################
# EKS
################################################################################

module "eks" {
  source = "../.."

  ## required
  cluster_name = local.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets

  # optional
  node_group_instance_type        = var.node_group_instance_type
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true
  tags                            = local.tags
}

################################################################################
# SUPPORTING RESOURCES
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.cluster_name
  cidr = "10.0.0.0/16"

  azs             = ["${data.aws_region.current.name}a", "${data.aws_region.current.name}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery/${local.cluster_name}" = local.cluster_name
  }

  tags = local.tags
}
