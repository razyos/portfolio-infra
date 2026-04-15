# The for_each meta-argument allows you to create multiple instances of a resource or data source based on the elements in a set, map, or list.

# Retrieve all available availability zones in the current AWS region
data "aws_availability_zones" "available" {
  state = "available"
}

# Define a local variable to hold the list of available availability zones
locals {
  azs_to_check = data.aws_availability_zones.available.names
}

# Iterate over each availability zone in azs_to_check and retrieve the instance types available in each AZ
data "aws_ec2_instance_type_offerings" "all_instance_types" {
  # The for_each to create multiple instances of this data source, one for each available AZ. Convert local.azs_to_check (a list) to a set to ensure uniqueness.
  for_each = toset(local.azs_to_check)
  // filter block specifies the criteria for the query.
  filter {
    name   = "location"           # Filter based on location (availability zone)
    values = [each.key]           # Use the current AZ in the iteration as the filter value
  }
  location_type = "availability-zone"  # Specify that the location type is an availability zone
}

# Define local variables to filter the availability zones and calculate subnet CIDR blocks
locals {
  # Filter the availability zones to only include those that support the specified instance type
  # itrates over the AZs in local.azs_to_check and :az is the result
  supported_azs = [
    for az in local.azs_to_check : az
    if contains([for offering in data.aws_ec2_instance_type_offerings.all_instance_types[az].instance_types : offering], var.instance_type)
  ]

  # Fallback to all available AZs if none support the specified instance type
  final_azs = length(local.supported_azs) > 0 ? local.supported_azs : local.azs_to_check

  # Calculate the number of bits to add to the base CIDR block to create the desired number of subnets log2 and round up
  new_bits = ceil(log(var.number_of_subnets, 2))

  # Generate the list of subnet CIDR blocks based on the VPC CIDR block and the calculated number of bits
  subnet_cidrs = [
    for i in range(var.number_of_subnets) : cidrsubnet(var.vpc_cidr, local.new_bits, i)
  ]
}

