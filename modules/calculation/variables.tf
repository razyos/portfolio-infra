variable "instance_type" {
  description = "The instance type to check for availability"
  type        = string
}

variable "number_of_subnets" {
  description = "The number of subnets to create"
  type        = number
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}
