# thevpc
resource "aws_vpc" "main_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  enable_dns_support   = var.dns_support
  enable_dns_hostnames = var.dns_hostname

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

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${local.project}-igw"
  }
}

resource "aws_nat_gateway" "vpc_nat" {
  vpc_id            = aws_vpc.main_vpc.id
  availability_mode = "regional"
  depends_on        = [aws_internet_gateway.main_igw]
  tags = {
    Name = "${local.project}-nat"
  }
}


