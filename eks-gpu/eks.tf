resource "aws_kms_key" "eks" {
  description             = "KMS key for ${var.eks_cluster} EKS secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  rotation_period_in_days = 90
#   region = var.aws_region
  

  tags = {
    Name = "${var.eks_cluster}-kms"
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.eks_cluster}-kms"
  target_key_id = aws_kms_key.eks.key_id
}