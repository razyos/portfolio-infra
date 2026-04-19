output "subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = local.subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = local.private_subnet_cidrs
}

output "final_azs" {
  description = "List of Availability Zones used for subnets"
  value       = local.final_azs
}
