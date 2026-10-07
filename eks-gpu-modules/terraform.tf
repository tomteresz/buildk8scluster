terraform {
  required_version = "~> 1.16"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.66.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.4.1"
    }
    helm = {
      source = "hashicorp/helm", version = "~> 3.3.0"
    }
    http = {
      source = "hashicorp/http", version = "~> 3.6.2"
    }
  }

  backend "local" {
    path = "mystate/terraform.tfstate"
  }


  # backend "s3" {
  #   #bucket name - set the permision, versioning and encryption
  #   bucket = "eks-gpu-state"
  #   #key is just a name, can be anything as i understand
  #   key     = "state/terraform.tfstate"
  #   region  = "eu-central-1"
  #   encrypt = true
  #   #the name of the dynamodb table, key MUST be "LockID"
  #   dynamodb_table = "eks-gpu-dev-lock"
  # }

}

provider "aws" {
  region                   = var.aws_region
  shared_config_files      = [var.shared_config_files]
  shared_credentials_files = [var.shared_credentials_files]
  //profile                 = "default"
  default_tags {
    tags = {
      Environment = var.env
      Owner       = "TT"
      Project     = var.project_name
    }
  }
}

# provider "kubernetes" {
#   host                   = aws_eks_cluster.eks_cluster.endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token
# }

# provider "helm" {
#   kubernetes = {
#     host                   = aws_eks_cluster.eks_cluster.endpoint
#     cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token
#   }
# }

# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "eks-gpu-state"

#   tags = {
#     Name        = "${local.project}-state"
#     Environment = "Shared"
#     Purpose     = "Terraform Remote Backend"
#   }
# }

# # Enable versioning (highly recommended for state files)
# resource "aws_s3_bucket_versioning" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# # Enable server-side encryption by default (using AWS KMS or SSE-S3)
# resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256" # You can change to "aws:kms" if you prefer KMS
#     }
#   }
# }

# # Block all public access (security best practice)
# resource "aws_s3_bucket_public_access_block" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# # =============================================
# # DynamoDB Table for State Locking
# # =============================================

# resource "aws_dynamodb_table" "terraform_lock" {
#   name         = "eks-gpu-dev-lock"
#   billing_mode = "PAY_PER_REQUEST" # Recommended for locking tables

#   hash_key = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }

#   tags = {
#     Name        = "Terraform State Lock Table"
#     Environment = "Shared"
#     Purpose     = "Terraform State Locking"
#   }
# }






