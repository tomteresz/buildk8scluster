resource "aws_kms_key" "eks_cluster" {
  description             = "KMS key for ${var.eks_cluster} EKS secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  rotation_period_in_days = 90
  #   region = var.aws_region

  tags = {
    Name = "${var.eks_cluster}-kms"
  }
}

resource "aws_kms_alias" "eks_cluster" {
  name          = "alias/${var.eks_cluster}-kms"
  target_key_id = aws_kms_key.eks_cluster.key_id
}

resource "aws_iam_role" "eks_cluster" {
  name = "${var.eks_cluster}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  tags = {
    Name = "${var.eks_cluster}-eks-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_worker" {
  name = "${var.eks_cluster}-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  tags = {
    Name = "${var.eks_cluster}-worker-role"
  }
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.eks_worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.eks_worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.eks_worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.eks_cluster}/cluster"
  retention_in_days = 30

  tags = {
    Name = "${var.eks_cluster}-log-group"
  }
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = var.project_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_cluster_ver

  vpc_config {
    subnet_ids = [
      aws_subnet.main_private4_a.id,
      aws_subnet.main_private5_b.id,
      aws_subnet.main_private6_c.id,
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_cluster.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_nat_gateway.vpc-nat,
    aws_route_table_association.main_rtb_private4_a,
    aws_route_table_association.main_rtb_private5_b,
    aws_route_table_association.main_rtb_private6_c
  ]
}

resource "aws_launch_template" "default" {
  name_prefix            = "${var.project_name}-default-"
  update_default_version = true

  key_name = var.ec2_ssh_key

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  # EC2 instance tags: applied to every new EKS worker node
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-default-node"
      Role = "eks-worker"
    }
  }
}

# resource "aws_eks_node_group" "small" {
#   cluster_name    = aws_eks_cluster.eks_cluster.name
#   node_group_name = "${var.project_name}-small"
#   node_role_arn   = aws_iam_role.eks_worker.arn
#   subnet_ids      = [aws_subnet.main_private4_a.id, aws_subnet.main_private5_b.id]
#   version         = var.eks_cluster_ver

#   scaling_config {
#     desired_size = 1
#     min_size     = 1
#     max_size     = 2
#   }

#   capacity_type = "SPOT"
#   #capacity_type  = "ON_DEMAND"
#   instance_types = ["t3.medium"]
#   ami_type       = "AL2023_x86_64_STANDARD"
#   disk_size      = 20
# }