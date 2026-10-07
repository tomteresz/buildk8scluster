variable "vpc_id" {
  type = string
}

variable "cidr_block" {
  type    = string
  default = null
}

variable "gateway_id" {
  type    = string
  default = null
}

variable "nat_gateway_id" {
  type    = string
  default = null
}

variable "route_name" {
  type = string
}

variable "subnet_id" {
  type    = string
  default = null
}