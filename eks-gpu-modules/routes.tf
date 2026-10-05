# main_route-table
resource "aws_route_table" "default" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "default-route"
  }
}

# public-route-table
resource "aws_route_table" "main_rtb_public" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    "Name" = "main-rtb-public"
  }
}

# private-route-table-1
resource "aws_route_table" "main_rtb_private1_a" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc-nat.id
  }

  tags = {
    Name = "main-rtb-private1-a"
  }
}

# private-route-table-2
resource "aws_route_table" "main_rtb_private2_b" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc-nat.id
  }

  tags = {
    Name = "main-rtb-private2-b"
  }
}

# private-route-table-3
resource "aws_route_table" "main_rtb_private3_c" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc-nat.id
  }

  tags = {
    Name = "main-rtb-private3-c"
  }
}

# private-route-table-4
resource "aws_route_table" "main_rtb_private4_a" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc-nat.id
  }

  tags = {
    Name = "main-rtb-private4-a"
  }
}

# private-route-table-5
resource "aws_route_table" "main_rtb_private5_b" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc-nat.id
  }

  tags = {
    Name = "main-rtb-private5-b"
  }
}

# private-route-table-6
resource "aws_route_table" "main_rtb_private6_c" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc-nat.id
  }

  tags = {
    Name = "main-rtb-private6-c"
  }
}

# subnet-association-with-route-table-public1
resource "aws_route_table_association" "main_rtb_public1_a" {
  subnet_id      = aws_subnet.main_public1_a.id
  route_table_id = aws_route_table.main_rtb_public.id
}

# subnet-association-with-route-table-public2
resource "aws_route_table_association" "main_rtb_public2_b" {
  subnet_id      = aws_subnet.main_public2_b.id
  route_table_id = aws_route_table.main_rtb_public.id
}

# subnet-association-with-route-table-public3
resource "aws_route_table_association" "main_rtb_public3_c" {
  subnet_id      = aws_subnet.main_public3_c.id
  route_table_id = aws_route_table.main_rtb_public.id
}

# subnet-association-with-route-table-public4
resource "aws_route_table_association" "main_rtb_public4_a" {
  subnet_id      = aws_subnet.main_public4_a.id
  route_table_id = aws_route_table.main_rtb_public.id
}

# subnet-association-with-route-table-public5
resource "aws_route_table_association" "main_rtb_public5_b" {
  subnet_id      = aws_subnet.main_public5_b.id
  route_table_id = aws_route_table.main_rtb_public.id
}

# subnet-association-with-route-table-public6
resource "aws_route_table_association" "main_rtb_public6_c" {
  subnet_id      = aws_subnet.main_public6_c.id
  route_table_id = aws_route_table.main_rtb_public.id
}

# subnet-association-with-route-table-private1
resource "aws_route_table_association" "main_rtb_private1_a" {
  subnet_id      = aws_subnet.main_private1_a.id
  route_table_id = aws_route_table.main_rtb_private1_a.id
}

# subnet-association-with-route-table-private2
resource "aws_route_table_association" "main_rtb_private2_b" {
  subnet_id      = aws_subnet.main_private2_b.id
  route_table_id = aws_route_table.main_rtb_private2_b.id
}

# subnet-association-with-route-table-private3
resource "aws_route_table_association" "main_rtb_private3_c" {
  subnet_id      = aws_subnet.main_private3_c.id
  route_table_id = aws_route_table.main_rtb_private3_c.id
}

# subnet-association-with-route-table-private4
resource "aws_route_table_association" "main_rtb_private4_a" {
  subnet_id      = aws_subnet.main_private4_a.id
  route_table_id = aws_route_table.main_rtb_private4_a.id
}

# subnet-association-with-route-table-private5
resource "aws_route_table_association" "main_rtb_private5_b" {
  subnet_id      = aws_subnet.main_private5_b.id
  route_table_id = aws_route_table.main_rtb_private5_b.id
}

# subnet-association-with-route-table-private6
resource "aws_route_table_association" "main_rtb_private6_c" {
  subnet_id      = aws_subnet.main_private6_c.id
  route_table_id = aws_route_table.main_rtb_private6_c.id
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${local.project}-igw"
  }
}

resource "aws_nat_gateway" "vpc-nat" {
  vpc_id            = aws_vpc.main_vpc.id
  availability_mode = "regional"
  depends_on        = [aws_internet_gateway.main_igw]
  tags = {
    Name = "${local.project}-nat"
  }
}
