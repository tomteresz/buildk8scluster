# main_route-table
resource "aws_route_table" "default" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "default-route"
  }
}

resource "aws_main_route_table_association" "default" {
  vpc_id         = module.vpc.vpc_id
  route_table_id = aws_route_table.default.id
}

module "route_table_public1_a" {
  source = "./modules/routes"

  cidr_block = "0.0.0.0/0"
  vpc_id     = module.vpc.vpc_id
  gateway_id = module.vpc.main_igw_id
  subnet_id  = module.main_public1_a.subnet_id
  route_name = "main-rtb-public1-a"
}

module "route_table_public2_b" {
  source = "./modules/routes"

  cidr_block = "0.0.0.0/0"
  vpc_id     = module.vpc.vpc_id
  gateway_id = module.vpc.main_igw_id
  subnet_id  = module.main_public2_b.subnet_id
  route_name = "main-rtb-public2-b"
}

module "route_table_public3_c" {
  source = "./modules/routes"

  cidr_block = "0.0.0.0/0"
  vpc_id     = module.vpc.vpc_id
  gateway_id = module.vpc.main_igw_id
  subnet_id  = module.main_public3_c.subnet_id
  route_name = "main-rtb-public3-c"
}

module "route_table_public4_a" {
  source = "./modules/routes"

  cidr_block = "0.0.0.0/0"
  vpc_id     = module.vpc.vpc_id
  gateway_id = module.vpc.main_igw_id
  subnet_id  = module.main_public4_a.subnet_id
  route_name = "main-rtb-public4-a"
}

module "route_table_public5_b" {
  source = "./modules/routes"

  cidr_block = "0.0.0.0/0"
  vpc_id     = module.vpc.vpc_id
  gateway_id = module.vpc.main_igw_id
  subnet_id  = module.main_public5_b.subnet_id
  route_name = "main-rtb-public5-b"
}

module "route_table_public6_c" {
  source = "./modules/routes"

  cidr_block = "0.0.0.0/0"
  vpc_id     = module.vpc.vpc_id
  gateway_id = module.vpc.main_igw_id
  subnet_id  = module.main_public6_c.subnet_id
  route_name = "main-rtb-public6-c"
}

module "route_table_private1_a" {
  source = "./modules/routes"

  cidr_block     = "0.0.0.0/0"
  vpc_id         = module.vpc.vpc_id
  nat_gateway_id = module.vpc.vpc_nat_id
  subnet_id      = module.main_private1_a.subnet_id
  route_name     = "main-rtb-private1-a"
}

module "route_table_private2_b" {
  source = "./modules/routes"

  cidr_block     = "0.0.0.0/0"
  vpc_id         = module.vpc.vpc_id
  nat_gateway_id = module.vpc.vpc_nat_id
  subnet_id      = module.main_private2_b.subnet_id
  route_name     = "main-rtb-private2-b"
}

module "route_table_private3_c" {
  source = "./modules/routes"

  cidr_block     = "0.0.0.0/0"
  vpc_id         = module.vpc.vpc_id
  nat_gateway_id = module.vpc.vpc_nat_id
  subnet_id      = module.main_private3_c.subnet_id
  route_name     = "main-rtb-private3-c"
}

module "route_table_private4_a" {
  source = "./modules/routes"

  cidr_block     = "0.0.0.0/0"
  vpc_id         = module.vpc.vpc_id
  nat_gateway_id = module.vpc.vpc_nat_id
  subnet_id      = module.main_private4_a.subnet_id
  route_name     = "main-rtb-private4-a"
}

module "route_table_private5_b" {
  source = "./modules/routes"

  cidr_block     = "0.0.0.0/0"
  vpc_id         = module.vpc.vpc_id
  nat_gateway_id = module.vpc.vpc_nat_id
  subnet_id      = module.main_private5_b.subnet_id
  route_name     = "main-rtb-private5-b"
}

module "route_table_private6_c" {
  source = "./modules/routes"

  cidr_block     = "0.0.0.0/0"
  vpc_id         = module.vpc.vpc_id
  nat_gateway_id = module.vpc.vpc_nat_id
  subnet_id      = module.main_private6_c.subnet_id
  route_name     = "main-rtb-private6-c"
}