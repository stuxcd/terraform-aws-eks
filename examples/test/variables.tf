variable "aws_region" {
  description = "Allow tests to set AWS Region"
  type        = string
  default     = "eu-west-2"
}

variable "cluster_name" {
  description = "Allow tests to set cluster name"
  type        = string
}

variable "node_group_instance_type" {
  description = "Allow tests to set the instance type of initial node group"
  type        = string
  default     = "t3.medium"
}
