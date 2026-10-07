resource "aws_route_table" "default" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = var.cidr_block
    gateway_id     = var.gateway_id
    nat_gateway_id = var.nat_gateway_id
  }

  tags = {
    Name = var.route_name
  }
}

# subnet-association-with-route-table-public1
resource "aws_route_table_association" "default" {
  subnet_id      = var.subnet_id
  route_table_id = aws_route_table.default.id
}
