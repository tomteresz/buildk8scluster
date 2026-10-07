variable "vpc_id" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "subnet_az" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "lb_tag" {
  type    = map(string)
  default = {}
}