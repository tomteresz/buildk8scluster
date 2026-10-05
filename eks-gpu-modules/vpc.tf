# thevpc
resource "aws_vpc" "main_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.project}"
  }
}

# dhcp options - external dns 
/* resource "aws_vpc_dhcp_options" "myaws-lab-dhcp" {
  domain_name          = "myaws.lab"
  domain_name_servers  = ["192.168.100.121", "192.168.100.134"]
  ntp_servers          = ["192.168.100.121"]
  netbios_name_servers = ["192.168.100.121", "192.168.100.134"]

  tags = {
    "Name" = "myaws.lab"
  }
} */

# dhcp options - aws dns
resource "aws_vpc_dhcp_options" "main_vpc_dhcp" {
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = "${local.project}"
  }
}

# dhcp options - aws dns - association with vpc
resource "aws_vpc_dhcp_options_association" "main_vpc_dhcp_dns" {
  vpc_id          = aws_vpc.main_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.main_vpc_dhcp.id
}

# create-public-subnet-1a
resource "aws_subnet" "main_public1_a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_public_1
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "main-public1-a"
  }
}

# create-public-subnet-2b
resource "aws_subnet" "main_public2_b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_public_2
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "main-public2-b"
  }
}

# create-public-subnet-3c
resource "aws_subnet" "main_public3_c" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_public_3
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "main-public3-c"
  }
}

# create-public-subnet-4a
resource "aws_subnet" "main_public4_a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_public_4
  availability_zone = "${var.aws_region}a"

  tags = {
    Name                     = "main-public4-a"
    "kubernetes.io/role/elb" = "1"
  }
}

# create-public-subnet-5b
resource "aws_subnet" "main_public5_b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_public_5
  availability_zone = "${var.aws_region}b"

  tags = {
    Name                     = "main-public5-b"
    "kubernetes.io/role/elb" = "1"
  }
}

# create-public-subnet-6c
resource "aws_subnet" "main_public6_c" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_public_6
  availability_zone = "${var.aws_region}c"

  tags = {
    Name                     = "main-public6-c"
    "kubernetes.io/role/elb" = "1"
  }
}

# create-private-subnet-1a
resource "aws_subnet" "main_private1_a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_private_1
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "main-private1-a"
  }
}

# create-private-subnet-2b
resource "aws_subnet" "main_private2_b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_private_2
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "main-private2-b"
  }
}

# create-private-subnet-3c
resource "aws_subnet" "main_private3_c" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_private_3
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "main-private3-c"
  }
}

# create-private-subnet-4a
resource "aws_subnet" "main_private4_a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_private_4
  availability_zone = "${var.aws_region}a"

  tags = {
    Name                              = "main-private4-a"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# create-private-subnet-5b
resource "aws_subnet" "main_private5_b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_private_5
  availability_zone = "${var.aws_region}b"

  tags = {
    Name                              = "main-private5-b"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# create-private-subnet-6c
resource "aws_subnet" "main_private6_c" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.subnet_private_6
  availability_zone = "${var.aws_region}c"

  tags = {
    Name                              = "main-private6-c"
    "kubernetes.io/role/internal-elb" = "1"
  }
}