################################################################################
# PROVIDER
################################################################################

provider "aws" {
  region = "eu-west-2"
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
  cluster_name = "test"
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

  ## optional
  cluster_version                  = "1.24"
  cluster_endpoint_private_access  = false
  cluster_endpoint_public_access   = true
  node_volume_size                 = 40
  deploy_karpenter_provisioner     = true
  karpenter_provisioner_max_cpu    = 40
  karpenter_provisioner_max_memory = 80
  create_spot_service_linked_role  = false
  tags                             = local.tags
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
