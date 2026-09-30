# 2. Instalacja AWS Load Balancer Controller za pomocą Helma
resource "helm_release" "lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  # Informujemy Helma, aby nie tworzył konta, bo zrobiliśmy to wyżej przez Terraform
  set = [
    {
    name  = "serviceAccount.create"
    value = "false"
  },

 {
    name  = "serviceAccount.name"
    value = kubernetes_service_account_v1.lbc_sa.metadata[0].name
  },

 {
    name  = "clusterName"
    value = aws_eks_cluster.eks_cluster.name
  },

 {
    name  = "region"
    value = var.aws_region
  },

 {
    name  = "vpcId"
    value = aws_vpc.main_vpc.id
  }
  ]
  depends_on = [
    aws_iam_role_policy_attachment.lbc,
    aws_eks_node_group.small,
    kubernetes_service_account_v1.lbc_sa
  ]
}