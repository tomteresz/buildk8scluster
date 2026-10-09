# node groups

resource "aws_eks_node_group" "small" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.project_name}-small"
  node_role_arn   = aws_iam_role.eks_worker.arn
  subnet_ids      = [module.main_private4_a.subnet_id, module.main_private5_b.subnet_id, module.main_private6_c.subnet_id]
  version         = var.eks_cluster_ver

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  launch_template {
    id      = aws_launch_template.default.id
    version = aws_launch_template.default.latest_version
  }

  capacity_type = "SPOT"
  #capacity_type  = "ON_DEMAND"
  instance_types = [
    "t3.medium",
    "t3a.medium",
  ]
  ami_type = "AL2023_x86_64_STANDARD"

  depends_on = [
    aws_eks_addon.vpc_cni,                      #needed
    aws_iam_role_policy_attachment.node_worker, #needed
    aws_iam_role_policy_attachment.node_ecr,    #for pull images - not necessary

    module.route_table_private4_a,
    module.route_table_private5_b,
    module.route_table_private6_c
  ]
}

resource "aws_eks_node_group" "gpu" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.project_name}-gpu"
  node_role_arn   = aws_iam_role.eks_worker.arn

  subnet_ids = [
    module.main_private4_a.subnet_id,
    module.main_private5_b.subnet_id,
    module.main_private6_c.subnet_id
  ]

  version = var.eks_cluster_ver

  scaling_config {
    desired_size = 1
    min_size     = 0
    max_size     = 1
  }

  launch_template {
    id      = aws_launch_template.gpu.id
    version = aws_launch_template.gpu.latest_version
  }

  capacity_type = "SPOT"
  #capacity_type  = "ON_DEMAND"

  instance_types = [
    "g5.xlarge",
    "g6.xlarge",
    "g4dn.xlarge"
  ]

  ami_type = "AL2023_x86_64_NVIDIA"

  labels = {
    "workload-type" = "gpu"
  }

  taint {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  depends_on = [
    aws_eks_addon.vpc_cni,
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_ecr,

    module.route_table_private4_a,
    module.route_table_private5_b,
    module.route_table_private6_c
  ]
}