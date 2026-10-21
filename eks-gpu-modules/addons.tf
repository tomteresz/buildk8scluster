resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.vpc_cni.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_iam_openid_connect_provider.eks_irsa,
    aws_iam_role_policy_attachment.vpc_cni,
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_cluster.eks_cluster]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "coredns"

  configuration_values = jsonencode({
    nodeSelector = {
      "workload-type" = "system"
    }

    tolerations = [
      {
        key    = "node-role.kubernetes.io/control-plane"
        effect = "NoSchedule"
      },
      {
        key      = "CriticalAddonsOnly"
        operator = "Exists"
      },

      {
        key      = "workload-type"
        operator = "Equal"
        value    = "system"
        effect   = "NoSchedule"
      }
    ]

    topologySpreadConstraints = [
      {
        maxSkew           = 1
        topologyKey       = "kubernetes.io/hostname"
        whenUnsatisfiable = "DoNotSchedule"

        labelSelector = {
          matchLabels = {
            "k8s-app" = "kube-dns"
          }
        }
      }
    ]

  })

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_cluster.eks_cluster]
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  addon_name    = "metrics-server"
  addon_version = "v0.9.0-eksbuild.11"

  configuration_values = jsonencode({
    nodeSelector = {
      "workload-type" = "system"
    }

    tolerations = [
      {
        key      = "CriticalAddonsOnly"
        operator = "Exists"
      },
      {
        key      = "workload-type"
        operator = "Equal"
        value    = "system"
        effect   = "NoSchedule"
      }
    ]
  })

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_cluster.eks_cluster]
}

resource "aws_eks_addon" "eks_node_monitoring_agent" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "eks-node-monitoring-agent"

  configuration_values = jsonencode({
    dcgmAgent = {
      nodeSelector = {
        "workload-type" = "gpu"
      }

      tolerations = [
        {
          key      = "nvidia.com/gpu"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }
      ]
    }
  })

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_cluster.eks_cluster]
}

resource "aws_eks_addon" "external_dns" {
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "external-dns"
  service_account_role_arn = aws_iam_role.ext_dns.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    policy = "sync"

    nodeSelector = {
      "workload-type" = "system"
    }

    tolerations = [
      {
        key      = "CriticalAddonsOnly"
        operator = "Exists"
      },
      {
        key      = "workload-type"
        operator = "Equal"
        value    = "system"
        effect   = "NoSchedule"
      }
    ]
  })

  depends_on = [
    aws_iam_openid_connect_provider.eks_irsa,
    aws_iam_role_policy_attachment.ext_dns,
  ]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  configuration_values = jsonencode({
    controller = {
      nodeSelector = {
        "workload-type" = "system"
      }

      tolerations = [
        {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        },
        {
          operator          = "Exists"
          effect            = "NoExecute"
          tolerationSeconds = 300
        },
        {
          key      = "workload-type"
          operator = "Equal"
          value    = "system"
          effect   = "NoSchedule"
        }
      ]
    }
  })

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_iam_openid_connect_provider.eks_irsa,
    aws_iam_role_policy_attachment.ebs_csi,
  ]
}
