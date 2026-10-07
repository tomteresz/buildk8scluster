# create-public-subnet-1a
resource "aws_subnet" "main_subnet" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr
  availability_zone = var.subnet_az

  tags = merge(
    {
      Name = var.subnet_name
    },
    var.lb_tag
  )
}