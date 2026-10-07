output "subnet_cidr" {
  description = "CIDR of created VPC"
  value       = aws_subnet.main_subnet.cidr_block
}

output "subnet_az" {
  description = "CIDR of created VPC"
  value       = aws_subnet.main_subnet.availability_zone
}

output "subnet_id" {
  description = "ID of created subnet"
  value       = aws_subnet.main_subnet.id
}