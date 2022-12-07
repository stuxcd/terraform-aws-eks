################################################################################
# GLOBAL LOCALS
################################################################################

locals {
  name            = var.cluster_name
  cluster_version = var.cluster_version

  partition = data.aws_partition.current.partition

  tags = var.tags
}

################################################################################
# EKS
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  enable_irsa = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  # Encryption key
  create_kms_key = true
  cluster_encryption_config = [{
    resources = ["secrets"]
  }]
  kms_key_deletion_window_in_days = 7
  enable_kms_key_rotation         = true

  node_security_group_additional_rules = {
    # Control plane invoke Karpenter webhook
    ingress_karpenter_webhook_tcp = {
      description                   = "Control plane invoke Karpenter webhook"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = "true"
    }
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery/${local.name}" = local.name
  }

  eks_managed_node_groups = {
    karpenter = {
      instance_types        = ["t3.medium"]
      create_security_group = false

      min_size     = 1
      max_size     = 1
      desired_size = 1

      iam_role_additional_policies = [
        "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.node_volume_size
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            kms_key_id            = data.aws_kms_key.aws_ebs.arn
            delete_on_termination = true
          }
        }
      }
    }
  }

  tags = merge(local.tags, {
    "karpenter.sh/discovery/${local.name}" = local.name
  })
}

################################################################################
# IAM
################################################################################

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = ">= 5.3"

  role_name             = "ebs-csi-${local.name}"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

module "karpenter_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = ">= 5.3"

  role_name = "karpenter-controller-${local.name}"

  attach_karpenter_controller_policy = true
  karpenter_controller_cluster_id    = module.eks.cluster_id
  karpenter_subnet_account_id        = data.aws_caller_identity.current.account_id
  karpenter_tag_key                  = "karpenter.sh/discovery/${local.name}"
  karpenter_controller_node_iam_role_arns = [
    module.eks.eks_managed_node_groups["karpenter"].iam_role_arn
  ]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }

  tags = local.tags
}

################################################################################
# KARPENTER
################################################################################

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${local.name}"
  role = module.eks.eks_managed_node_groups["karpenter"].iam_role_name
}

resource "aws_iam_service_linked_role" "spot" {
  count = var.create_spot_service_linked_role ? 1 : 0

  aws_service_name = "spot.amazonaws.com"
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "v0.19.3"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_irsa_role.iam_role_arn
  }

  set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_id
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }

  set {
    name  = "replicas"
    value = 1
  }

  set {
    name  = "loglevel"
    value = "info"
  }
}

resource "kubectl_manifest" "karpenter_provisioner" {
  count = var.deploy_karpenter_provisioner ? 1 : 0

  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: default
  spec:
    consolidation:
      enabled: true
    ttlSecondsUntilExpired: 2592000 # 30 Days
    requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot", "on_demand"]
    limits:
      resources:
        cpu: ${var.karpenter_provisioner_max_cpu}
        memory: ${var.karpenter_provisioner_max_memory}
    kubeletConfiguration:
      systemReserved:
        cpu: 100m
        memory: 100Mi
        ephemeral-storage: 1Gi
      kubeReserved:
        cpu: 200m
        memory: 100Mi
        ephemeral-storage: 3Gi
      evictionHard:
        memory.available: 5%
        nodefs.available: 5%
        nodefs.inodesFree: 5%
      evictionSoft:
        memory.available: 10%
        nodefs.available: 10%
        nodefs.inodesFree: 10%
      evictionSoftGracePeriod:
        memory.available: 1m
        nodefs.available: 1m30s
        nodefs.inodesFree: 2m
      evictionMaxPodGracePeriod: 180
      podsPerCore: 2
      maxPods: 20
    provider:
      subnetSelector:
        "karpenter.sh/discovery/${local.name}": ${local.name}
      securityGroupSelector:
        "karpenter.sh/discovery/${local.name}": ${local.name}
      tags:
        "karpenter.sh/discovery/${local.name}": ${local.name}
        Name: karpenter/${local.name}/default
        karpenter.sh/provisioner-name: default
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: "${var.node_volume_size}Gi"
            volumeType: gp3
            iops: 3000
            encrypted: true
            kmsKeyID: ${data.aws_kms_key.aws_ebs.arn}
            deleteOnTermination: true
            throughput: 125
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

################################################################################
# STORAGE CLASS
################################################################################

resource "kubernetes_storage_class" "gp2_encrypted" {
  metadata {
    name = "gp2-encrypted"
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    encrypted = "true"
    kmsKeyId  = data.aws_kms_key.aws_ebs.arn
  }
}
