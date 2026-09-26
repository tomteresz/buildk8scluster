# start coding

# resource "aws_instance" "main_ff_jbox_01" {
#   instance_type = "t3.large"
#   ami           = "ami-04ba5fe2f0e2f875f"

#   subnet_id                   = aws_subnet.main_public1_a.id
#   associate_public_ip_address = true
#   key_name                    = "ff-ec2-key"

#   instance_market_options {
#     market_type = "spot"
#     spot_options {
#       spot_instance_type = "one-time" 
#     }
#   }

#   tags = {
#     "env"   = "prod"
#     "Name"  = "main_ff-jbox-01"
#     "os"    = "windows"
#     "owner" = "TT"
#   }
# }



/*
resource "aws_internet_gateway_attachment" "main_igw-attach" {
  internet_gateway_id = aws_internet_gateway.main_igw.id
  vpc_id              = aws_vpc.main_vpc.id
}
*/



/* #ec2
resource "aws_instance" "main_ff-jbox-01" {
  instance_type = "t3.large"
  ami           = "ami-00cb3eed37fa7b06c"
  subnet_id     = aws_subnet.main_subnet-private1-eu-central-1a.id


  tags = {
    "env"   = "prod"
    "Name"  = "main_ff-jbox-01"
    "os"    = "windows"
    "owner" = "TT"
  }
} */



# #ec2
# resource "aws_instance" "test_01" {
#   instance_type               = "g4ad.xlarge"
#   ami                         = "ami-066684246476b7b50"
#   subnet_id                   = aws_subnet.main_public2-eu-central-1b.id
#   associate_public_ip_address = true
#   key_name                    = "ff-ec2-key"

#   instance_market_options {
#     market_type = "spot"

#     spot_options {
#       instance_interruption_behavior = "terminate"
#       spot_instance_type             = "one-time"


#     }
#   }
# }
#   vpc_security_group_ids = [
#     aws_security_group.access_sg.id
#   ]

#   tags = {
#     "env"   = "test"
#     "Name"  = "test-01"
#     "owner" = "TT"
#   }
# }

/*

#ec2
resource "aws_instance" "main_ff-ansible" {
  instance_type = "t3.micro"
  ami           = "ami-01f79b1e4a5c64257"
  subnet_id     = aws_subnet.main_subnet-private2-eu-central-1b.id

  
  tags = {
    "env"  = "prod"
    "Name" = "main_ff-ansible"
    "os"   = "linux"
  }
}

#ec2
resource "aws_instance" "main_ff-jenkins" {
  instance_type = "t3.micro"
  ami           = "ami-01f79b1e4a5c64257"
  subnet_id     = aws_subnet.main_subnet-private2-eu-central-1b.id

  
  tags = {
    "env"  = "prod"
    "Name" = "main_ff-jenkins"
    "os"   = "linux"
  }
}

#ec2
resource "aws_instance" "main_ff-l100" {
  instance_type = "t3.micro"
  ami           = "ami-01f79b1e4a5c64257"
  subnet_id     = aws_subnet.main_subnet-private2-eu-central-1b.id

  
  tags = {
    "env"  = "prod"
    "Name" = "main_ff-l100"
    "os"   = "linux"
  }
}

#ec2
resource "aws_instance" "main_ff-w160" {
  instance_type = "t3.micro"
  ami           = "ami-00cb3eed37fa7b06c"
  subnet_id     = aws_subnet.main_subnet-private2-eu-central-1b.id

  
  tags = {
    "env"  = "prod"
    "Name" = "main_ff-w160"
    "os"   = "windows"
  }
}

#ec2
resource "aws_instance" "main_ff-w190" {
  instance_type = "t3.micro"
  ami           = "ami-00cb3eed37fa7b06c"
  subnet_id     = aws_subnet.main_subnet-private1-eu-central-1a.id
  
  tags = {
    "env"  = "prod"
    "Name" = "main_ff-w190"
    "os"   = "windows"
  }
}

#ec2
resource "aws_instance" "main_ff-w220" {
  instance_type = "t3.micro"
  ami           = "ami-00cb3eed37fa7b06c"
  subnet_id     = aws_subnet.main_subnet-private2-eu-central-1b.id

  
  tags = {
    "env"  = "prod"
    "Name" = "main_ff-w220"
    "os"   = "windows"
  }
}

*/