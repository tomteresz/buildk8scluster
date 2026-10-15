variable "shared_config_files" {
  type    = string
  default = "C:/Users/tom/.aws/config"
}

variable "shared_credentials_files" {
  type    = string
  default = "C:/Users/tom/.aws/credentials"
}

#general variables

variable "aws_region" {
  type    = string
  default = "eu-central-1"
  #default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "eks-gpu"
}

variable "eks_cluster" {
  type    = string
  default = "eks-cluster"
}

variable "eks_cluster_ver" {
  type    = string
  default = "1.35"
}

variable "ec2_ssh_key" {
  type    = string
  default = "ff-ec2-key"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "192.168.0.0/16"
}