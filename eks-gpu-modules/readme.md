# 🚀 AWS EKS GPU Infrastructure — Terraform Modules

A hands-on AWS infrastructure lab that provisions an **Amazon EKS cluster** using **Terraform modules** and **GitHub Actions**. It establishes the networking, identity, storage, DNS, and load-balancing foundations for future GPU workloads and vLLM experiments.

> **Status:** Working lab environment, tested with GitHub Actions `apply` and `destroy` using remote Terraform state. **Not production-ready.** Despite the project name, GPU worker nodes and vLLM are **not deployed yet**.

## 🏗️ Architecture

```text
GitHub Actions ── OIDC ──> AWS IAM role
       │
       └── Terraform ──> S3 remote state + DynamoDB lock
                              │
                              ▼
                    AWS (eu-central-1)
                    ├── VPC (192.168.0.0/16)
                    │   ├── Public subnets / Internet Gateway
                    │   ├── Private subnets / Regional NAT Gateway
                    │   └── Route tables (3 Availability Zones)
                    └── Amazon EKS (Kubernetes 1.35)
                        ├── Managed node group (SPOT, t3.medium)
                        ├── EKS add-ons
                        ├── IAM Roles for Service Accounts (IRSA)
                        └── AWS Load Balancer Controller (Helm)
```

## ✨ What's Included

| Component | Current implementation |
| --- | --- |
| 🌐 Networking | VPC, 12 `/24` subnets across 3 AZs (6 public, 6 private), Internet Gateway, regional NAT Gateway, route tables |
| ☸️ Kubernetes | EKS 1.35; public and private API endpoints; managed SPOT node group (`t3.medium`, desired 1, min 1, max 2) |
| 🔐 Identity | Dedicated IAM roles; EKS OIDC provider and IRSA for VPC CNI, ExternalDNS, EBS CSI, and Load Balancer Controller |
| 🧩 EKS add-ons | VPC CNI, kube-proxy, CoreDNS, Metrics Server, EKS Node Monitoring Agent, ExternalDNS, EBS CSI Driver |
| ⚖️ Ingress | AWS Load Balancer Controller installed through Helm; sample HTTP ALB Ingress manifest |
| 🌍 DNS | ExternalDNS with Route 53 permissions restricted for record changes to a specific hosted zone; `sync` policy |
| 💾 Storage | EBS CSI Driver; encrypted `gp3` node root volumes |
| 🔑 Encryption & logs | KMS encryption for Kubernetes secrets, KMS key rotation, EKS control-plane logs in CloudWatch (30-day retention) |
| 🔄 Automation | GitHub Actions workflows for backend bootstrap, plan, apply, and destroy; AWS authentication via GitHub OIDC |
| 🗃️ State | S3 remote backend with encryption and DynamoDB state locking |

## 📁 Repository Layout

```text
eks-gpu-modules/
├── modules/
│   ├── vpc/                 # VPC, DHCP options, IGW, regional NAT
│   ├── subnets/             # Reusable single-subnet module
│   ├── routes/              # Route table + subnet association
│   └── sgs/                 # Placeholder (not implemented)
├── policies/                # IAM policies for LBC and ExternalDNS
├── vpc.tf                   # Subnet module instances
├── routes.tf                # Route table module instances
├── eks.tf                   # EKS, KMS, IAM, IRSA, access entries
├── ng.tf                    # Managed node group and scaling
├── addons.tf                # EKS managed add-ons
├── helm.tf                  # AWS Load Balancer Controller
├── terraform.tf             # Providers and remote backend
├── variables.tf             # Input defaults
├── locals.tf                # Derived values
├── outputs.tf               # Network and log outputs
├── ingress.yaml             # Sample ALB Ingress (test only)
└── delete.bat               # Emergency manual cleanup script
```

Workflows live in the repository root under `.github/workflows/`: `terraform-bootstrap.yml`, `terraform-plan.yml`, `terraform-apply.yml`, and `terraform-destroy.yml`.

## ✅ Prerequisites

- AWS account and permissions to manage VPC, EKS, IAM, EC2, KMS, CloudWatch, S3, and DynamoDB.
- Terraform **1.16.x**, AWS CLI, and `kubectl`; Helm is managed by the Terraform Helm provider.
- An existing EC2 key pair matching `ec2_ssh_key` (default: `ff-ec2-key`).
- GitHub Actions AWS OIDC role configured with the necessary AWS permissions.
- An S3 bucket (`eks-gpu-state`) and DynamoDB lock table (`eks-gpu-dev-lock`) created **before** initializing this Terraform configuration.
- For ExternalDNS testing: a Route 53 hosted zone matching the zone ID in `policies/ext_dns_iam_policy.json`.

> ⚠️ Review account-specific values before deployment: AWS account principal in `eks.tf`, hosted-zone ID in the ExternalDNS policy, EC2 key-pair name, backend resources, and local AWS credential paths. The existing configuration contains lab-specific defaults.

## 🚀 Deploy

### 1. Prepare the backend

Run the repository's **`terraform-bootstrap.yml`** GitHub Actions workflow to create the state bucket and lock table, or provision equivalent resources separately.

### 2. Initialize and inspect

```bash
cd eks-gpu-modules
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
```

### 3. Apply

```bash
terraform apply
```

Alternatively, use **`terraform-plan.yml`** followed by the manually triggered **`terraform-apply.yml`** workflow. GitHub Actions uses AWS OIDC rather than stored long-lived AWS access keys.

### 4. Connect to the cluster

```bash
aws eks update-kubeconfig --region eu-central-1 --name eks-gpu
kubectl get nodes -o wide
kubectl get pods -A
kubectl get events -A --sort-by='.lastTimestamp'
```

## 🧪 Validation

```bash
# Cluster and managed add-ons
aws eks describe-cluster --name eks-gpu --region eu-central-1 --query 'cluster.status'
aws eks list-addons --cluster-name eks-gpu --region eu-central-1

# Kubernetes networking and controllers
kubectl get nodes
kubectl get pods -n kube-system
kubectl get deployment aws-load-balancer-controller -n kube-system

# Remote Terraform state
terraform state list
```

The included `ingress.yaml` is **only a controller/ALB test**: it points to a deliberately nonexistent Service and is not a functional application deployment. EBS CSI and ExternalDNS have also been exercised separately in the lab.

## 🧹 Destroy

```bash
terraform destroy
```

Or trigger **`terraform-destroy.yml`** in GitHub Actions. The workflow can read the same S3 state created by the apply workflow, even when it runs on a new GitHub-hosted runner.

The **S3 backend and DynamoDB lock table are separate bootstrap resources** and are not removed by the infrastructure's Terraform destroy. `delete.bat` is an **emergency, best-effort manual cleanup utility**, not a replacement for `terraform destroy`; review it carefully before running it.

## ⚠️ Lab Limitations

- EKS API public endpoint currently permits `0.0.0.0/0` to accommodate GitHub-hosted runners. **Do not copy this setting into production.**
- The worker node group uses SPOT capacity with a single instance type; capacity is not guaranteed.
- EKS add-on versions and the Helm chart version are not explicitly pinned.
- IAM policies, naming, and access settings contain environment-specific values.
- No dedicated GPU node group, GPU device plugin, model serving, or vLLM deployment yet.
- The current subnet and route-table definitions use repeated module calls rather than `for_each`.
- No production-grade high availability, security hardening, monitoring stack, or disaster-recovery design is claimed.

## 🗺️ Next Steps

1. 🔧 Simplify Terraform dependencies and consolidate routing where appropriate.
2. ♻️ Refactor repeated subnet/route module calls with `for_each` and safe state moves.
3. 🔒 Add ACM-backed HTTPS ingress and tighten EKS API access.
4. 📊 Expand observability and introduce node autoscaling (e.g., Karpenter).
5. 🎮 Add GPU worker nodes and NVIDIA components.
6. 🤖 Deploy and benchmark vLLM on EKS.

---

**Purpose:** Learn and validate the full infrastructure lifecycle — **plan → apply → test → destroy** — before extending the platform for GPU-based AI workloads.
