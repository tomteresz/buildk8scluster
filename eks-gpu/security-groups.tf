# resource "aws_security_group" "access_sg" {
#   name        = "test-01-all-inbound"
#   description = "LAB ONLY - Allow all inbound and outbound traffic"
#   vpc_id      = aws_vpc.main-vpc.id

#   ingress {
#     description = "LAB ONLY - all inbound IPv4 traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1" # All protocols
#     cidr_blocks = ["0.0.0.0/0"]
#   }


#   egress {
#     description = "Allow all outbound IPv4 traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1" # All protocols
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name      = "test-01-all-inbound"
#     env       = "dev"
#     temporary = "true"
#   }
# }