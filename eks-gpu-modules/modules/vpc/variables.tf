variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "dns_support" {
  description = "Enable DNS support"
  type        = bool
}

variable "dns_hostname" {
  description = "Enable DNS hostnames"
  type        = bool
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "env" {
  description = "Name of the environment"
  type        = string
}

