################################################################################
# EKS
################################################################################

output "cluster_id" {
  value       = module.eks.cluster_id
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
}
