################################################################################
# EKS
################################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Version of the EKS cluster"
  type        = string
  default     = "1.24"
}

variable "cluster_endpoint_private_access" {
  description = "Expose Kubernetes API in private subnets"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Expose Kubernetes API publicly"
  type        = bool
  default     = false
}

variable "node_group_instance_type" {
  description = "Set the instance type of the initial node group that karpenter runs on"
  type        = string
  default     = "t3.medium"
}

################################################################################
# NETWORKING
################################################################################

variable "vpc_id" {
  description = "ID of vpc to deploy cluster into"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of subnets to deploy cluster into"
  type        = list(string)
}

################################################################################
# KARPENTER
################################################################################

variable "deploy_karpenter_provisioner" {
  description = "Wether to deploy the a default Karpenter provisioner"
  type        = bool
  default     = true
}

variable "node_volume_size" {
  description = "Volume size of nodes in the cluster in GB"
  type        = number
  default     = 40
}

variable "karpenter_provisioner_max_cpu" {
  description = "The max number of cpu's the default provisioner will deploy"
  type        = number
  default     = 40
}

variable "karpenter_provisioner_max_memory" {
  description = "The max memory the default provisioner will deploy"
  type        = number
  default     = 80
}

################################################################################
# IAM
################################################################################

variable "create_spot_service_linked_role" {
  description = "Indicates whether or not to create the spot.amazonaws.com service linked role"
  type        = bool
  default     = true
}

################################################################################
# GENERAL
################################################################################

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
