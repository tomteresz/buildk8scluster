output "vpc_id" {
  description = "ID of created VPC"
  value       = aws_vpc.main_vpc.id
}

output "vpc_cidr" {
  description = "CIDR of created VPC"
  value       = aws_vpc.main_vpc.cidr_block
}

output "main_igw_id" {
  description = "IGW id of created VPC"
  value       = aws_internet_gateway.main_igw.id
}

output "vpc_nat_id" {
  description = "NAT id of created VPC"
  value       = aws_nat_gateway.vpc_nat.id
}

