module "vpc" {
  source = "./modules/vpc"

  vpc_cidr     = var.vpc_cidr
  dns_support  = true
  dns_hostname = true

  project_name = var.project_name
  env          = var.env
}

module "main_public1_a" {
  source = "./modules/subnets"

  vpc_id      = module.vpc.vpc_id
  subnet_cidr = "192.168.10.0/24"
  subnet_az   = "eu-central-1a"
  subnet_name = "main-public1-a"
}

module "main_public2_b" {
  source = "./modules/subnets"

  vpc_id      = module.vpc.vpc_id
  subnet_cidr = "192.168.11.0/24"
  subnet_az   = "eu-central-1b"
  subnet_name = "main-public2-b"
}

module "main_public3_c" {
  source = "./modules/subnets"

  vpc_id      = module.vpc.vpc_id
  subnet_cidr = "192.168.12.0/24"
  subnet_az   = "eu-central-1c"
  subnet_name = "main-public3-c"
}

module "main_public4_a" {
  source = "./modules/subnets"

  vpc_id      = module.vpc.vpc_id
  subnet_cidr = "192.168.13.0/24"
  subnet_az   = "eu-central-1a"
  subnet_name = "main-public4-a"

  lb_tag = {
    "kubernetes.io/role/elb" = "1"
  }
}

module "main_public5_b" {
  source = "./modules/subnets"

  vpc_id      = module.vpc.vpc_id
  subnet_cidr = "192.168.14.0/24"
  subnet_az   = "eu-central-1b"
  subnet_name = "main-public5-b"

  lb_tag = {
    "kubernetes.io/role/elb" = "1"
  }
}

module "main_public6_c" {
  source = "./modules/subnets"

  vpc_id      = module.vpc.vpc_id
  subnet_cidr = "192.168.15.0/24"
  subnet_az   = "eu-central-1c"
  subnet_name = "main-public6-c"

  lb_tag = {
    "kubernetes.io/role/elb" = "1"
  }
}

module "main_private1_a" {
  source = "./modules/subnets"

  vpc_id      = module.vpc.vpc_id
  subnet_cidr = "192.168.20.0/24"
  subnet_az   = "eu-central-1a"
  subnet_name = "main-private1-a"
}

module "main_private2_b" {
  source = "./modules/subnets"

  vpc_id      = module.vpc.vpc_id
  subnet_cidr = "192.168.21.0/24"
  subnet_az   = "eu-central-1b"
  subnet_name = "main-private2-b"
}

module "main_private3_c" {
  source = "./modules/subnets"

  vpc_id      = module.vpc.vpc_id
  subnet_cidr = "192.168.22.0/24"
  subnet_az   = "eu-central-1c"
  subnet_name = "main-private3-c"
}

module "main_private4_a" {
  source = "./modules/subnets"

  vpc_id      = module.vpc.vpc_id
  subnet_cidr = "192.168.23.0/24"
  subnet_az   = "eu-central-1a"
  subnet_name = "main-private4-a"

  lb_tag = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

module "main_private5_b" {
  source = "./modules/subnets"

  vpc_id      = module.vpc.vpc_id
  subnet_cidr = "192.168.24.0/24"
  subnet_az   = "eu-central-1b"
  subnet_name = "main-private5-b"

  lb_tag = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

module "main_private6_c" {
  source = "./modules/subnets"

  vpc_id      = module.vpc.vpc_id
  subnet_cidr = "192.168.25.0/24"
  subnet_az   = "eu-central-1c"
  subnet_name = "main-private6-c"

  lb_tag = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}