locals {
  project = "${var.project_name}-${var.env}"
}

locals {
  eks_oidc_issuer = data.aws_eks_cluster.eks_cluster_data.identity[0].oidc[0].issuer
}

