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
  default     = "1.23"
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
