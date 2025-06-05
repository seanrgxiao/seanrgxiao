terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"        # 假设 2025 年 AWS Provider 已升级到 5.x 版本
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }

  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"   # 替换为你的 S3 状态桶
  #   key            = "eks/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   dynamodb_table = "terraform-lock-table"          # 用于状态锁定的 DynamoDB 表
  #   encrypt        = true
  # }
}

# provider.tf

# 指定 AWS Provider，默认使用变量 aws_region
provider "aws" {
  region = var.aws_region
}

# 额外声明一个可选的 AWS provider别名，例如用于其他区域的资源
provider "aws" {
  # alias  = ""
  region = "ap-southeast-1"
}

# Kubernetes Provider，后续用于管理 EKS 上的 Kubernetes 资源（如果需要）
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
# vpc.tf

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"  # 假设 2025 年模块版本为 5.x

  name                 = "${var.cluster_name}-vpc"
  cidr                 = var.vpc_cidr
  azs                  = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnets_cidrs))
  private_subnets      = var.private_subnets_cidrs
  public_subnets       = var.public_subnets_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = {
    "Name"        = "${var.cluster_name}-vpc"
    "Environment" = "dev"  # 按需修改
  }
}

# 获取可用区列表，用于给 VPC 模块配置 AZs
data "aws_availability_zones" "available" {
  state = "available"
}
# iam.tf

# 1. 创建 EKS 控制平面角色 (Cluster IAM Role)
resource "aws_iam_role" "eks_cluster_role" {
  name               = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role_policy.json
  tags = {
    "Name"        = "${var.cluster_name}-eks-cluster-role"
    "Environment" = "dev"
  }
}

data "aws_iam_policy_document" "eks_cluster_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# 附加 AmazonEKSClusterPolicy, AmazonEKSServicePolicy
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# 2. 创建 EKS Node Group Role (Worker IAM Role)
resource "aws_iam_role" "eks_nodegroup_role" {
  name               = "${var.cluster_name}-eks-nodegroup-role"
  assume_role_policy = data.aws_iam_policy_document.eks_nodegroup_assume_role_policy.json
  tags = {
    "Name"        = "${var.cluster_name}-eks-nodegroup-role"
    "Environment" = "dev"
  }
}

data "aws_iam_policy_document" "eks_nodegroup_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    # EKS 托管节点组会使用此角色
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# 附加 AmazonEKSWorkerNodePolicy, AmazonEC2ContainerRegistryReadOnly, AmazonEKS_CNI_Policy
resource "aws_iam_role_policy_attachment" "eks_ng_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_ng_AmazonECRReadOnly" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_ng_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
# eks-cluster.tf

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "24.0.0"  # 假设 2025 年版本
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # VPC 相关
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets  # EKS 控制平面和节点都放在私有子网里

  # 控制平面安全组入站规则（可以根据实际需求进行细化）
  cluster_security_group_ingress = var.eks_control_plane_security_group_rules

  # EKS 控制平面角色
  cluster_iam_role_name = aws_iam_role.eks_cluster_role.name

  # Worker 节点组配置
  node_groups = {
    managed_node_group = {
      # 为此托管 Node Group 明确指定 IAM Role
      node_role_arn = aws_iam_role.eks_nodegroup_role.arn

      # 节点组名称，会被 AWS 控制台显示
      name = "${var.cluster_name}-mng"

      # 实例类型、容量等
      instance_types = [var.node_group_instance_type]
      desired_capacity = var.node_group_desired_capacity
      min_capacity     = var.node_group_min_capacity
      max_capacity     = var.node_group_max_capacity

      # 子网 ID（使用私有子网）
      subnet_ids = module.vpc.private_subnets

      # 为节点打标签
      labels = merge(
        {
          "eks_cluster" = var.cluster_name
          "purpose"     = "production"
        },
        var.node_group_labels
      )

      # 可选：为节点打 Taints
      taints = var.node_group_taints

      # 节点组自动更新、自动修复设置
      launch_template = {
        # 如果需要使用自定义 AMI，可以在这里声明。若无需求，此部分可以删除。
        # id      = aws_launch_template.my_custom_ami.id
        # version = "$$Latest"
      }

      key_name = var.ssh_key_name  # 如果希望通过 SSH 登录节点，需提前创建 KeyPair
    }
  }

  # OIDC Provider：用于 IRSA（IAM Roles for Service Accounts），建议启用
  manage_aws_auth = true
  map_roles = [
    {
      rolearn  = aws_iam_role.eks_nodegroup_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]

  # 启用 IRSA（IAM Roles for Service Accounts）
  enable_irsa = true

  # 让模块为我们自动创建 Service Account 的 IAM 角色
  create_oidc_provider = true

  # 哪些 Kubernetes addon 需要启用，可以按需配置
  create_eks_managed_node_groups = true

  # Kubernetes Dashboard、VPC CNI 等常用 addon
  enable_irsa_addon = true
  addons = [
    {
      name    = "vpc-cni"
      version = "v1.12.0"  # 示例版本
    },
    {
      name    = "kube-proxy"
      version = "v1.27.3-eksbuild.1"
    },
    {
      name    = "coredns"
      version = "1.12.0-eksbuild.1"
    }
  ]

  tags = {
    "Environment" = "dev"
    "Owner"       = "team-xyz"
  }
}

# 在 EKS 集群创建完成后，获取 Auth Token
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
