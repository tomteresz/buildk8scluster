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

# resource "aws_iam_role_policy_attachment" "node_cni" {
#   role       = aws_iam_role.eks_worker.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# }

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

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids = [
      module.main_private4_a.subnet_id,
      module.main_private5_b.subnet_id,
      module.main_private6_c.subnet_id,
    ]
    endpoint_private_access = true
    endpoint_public_access  = true

    #this one is dynamic from local terraform
    public_access_cidrs = [
      #local.my_ip_cidr,
      "0.0.0.0/0",
    ]
    #this one is static when terraform running via Github
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
    module.vpc.vpc_nat_id,
    module.route_table_private4_a,
    module.route_table_private5_b,
    module.route_table_private6_c
  ]
}

#this part is only when running from for GH-Action - gives my local user access
resource "aws_eks_access_entry" "eks_admin" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = "arn:aws:iam::651629222199:user/admino-cli"
  type          = "STANDARD"
}

#this part is only when running from for GH-Action - gives my local user access
resource "aws_eks_access_policy_association" "eks_admin" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = aws_eks_access_entry.eks_admin.principal_arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_launch_template" "default" {
  name_prefix            = "${var.project_name}-default"
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
      Name = "${var.project_name}-node"
      Role = "eks-worker"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.project_name}-node-vol"
    }
  }
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

data "aws_eks_cluster" "eks_cluster_data" {
  name       = aws_eks_cluster.eks_cluster.name
  depends_on = [aws_eks_cluster.eks_cluster]
}

data "aws_eks_cluster_auth" "eks_cluster_auth" {
  name       = aws_eks_cluster.eks_cluster.name
  depends_on = [aws_eks_cluster.eks_cluster]
}

data "tls_certificate" "eks_oidc_issuer" {
  url = local.eks_oidc_issuer
}

resource "aws_iam_openid_connect_provider" "eks_irsa" {
  url             = local.eks_oidc_issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc_issuer.certificates[0].sha1_fingerprint]

  depends_on = [aws_eks_cluster.eks_cluster]
}

resource "aws_iam_role" "vpc_cni" {
  name               = "${var.eks_cluster}-vpc-cni"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume.json

  tags = {
    Name = "${var.eks_cluster}-vpc-cni"
  }
}

data "aws_iam_policy_document" "vpc_cni_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_irsa.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_irsa.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_irsa.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_policy" "lbc" {
  name        = "${var.eks_cluster}-AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/policies/lbc_iam_policy.json")
}

data "aws_iam_policy_document" "lbc_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_irsa.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_irsa.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_irsa.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lbc" {
  name               = "${var.eks_cluster}-lbc"
  assume_role_policy = data.aws_iam_policy_document.lbc_assume.json

  tags = {
    Name = "${var.eks_cluster}-lbc"
  }
}

resource "aws_iam_role_policy_attachment" "lbc" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}

resource "kubernetes_service_account_v1" "lbc_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.lbc.arn
    }
  }
}

data "aws_iam_policy_document" "ext_dns_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_irsa.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_irsa.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:external-dns:external-dns"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_irsa.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ext_dns" {
  name        = "${var.eks_cluster}-AWSExternalDnsIAMPolicy"
  description = "IAM policy for External Dns Addon"
  policy      = file("${path.module}/policies/ext_dns_iam_policy.json")
}

resource "aws_iam_role" "ext_dns" {
  name               = "${var.eks_cluster}-ext-dns"
  assume_role_policy = data.aws_iam_policy_document.ext_dns_assume.json

  tags = {
    Name = "${var.eks_cluster}-ext-dns"
  }
}

resource "aws_iam_role_policy_attachment" "ext_dns" {
  role       = aws_iam_role.ext_dns.name
  policy_arn = aws_iam_policy.ext_dns.arn
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${var.eks_cluster}-ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume.json

  tags = {
    Name = "${var.eks_cluster}-ebs-csi"
  }
}

data "aws_iam_policy_document" "ebs_csi_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_irsa.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_irsa.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_irsa.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2"
}