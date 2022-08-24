################################################################################
# EKS
################################################################################

output "eks_cluster_name" {
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = module.eks.cluster_id
}
