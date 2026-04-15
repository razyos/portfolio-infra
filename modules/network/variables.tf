# variables.tf
variable "subnet_cidrs" {
  description = "List of subnet CIDR blocks calculated by the calculation module"
  type        = list(string)
}

variable "final_azs" {
  description = "List of Availability Zones selected by the calculation module"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "base_tags" {
  description = "Base tags to apply to all resources"
  type        = map(string)
}
