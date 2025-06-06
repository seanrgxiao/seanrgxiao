terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  # 开启 Terraform 状态加密（可选，根据需要打开）
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "eks-cluster/terraform.tfstate"
  #   region         = var.aws_region
  #   encrypt        = true
  #   dynamodb_table = "tf-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region
}

# Kubernetes provider 会在 EKS 集群创建完成后初始化，依赖于 cluster 的 output
provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
  # load_config_file       = false
}
# 为 EKS 控制平面创建安全组
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "EKS 控制平面安全组"
  vpc_id      = aws_vpc.main.id

  # 允许 Worker 节点向控制平面节点的通信
  ingress {
    description      = "Worker to Control Plane"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups  = [aws_security_group.eks_node_sg.id]
    self             = false
    cidr_blocks      = []
    ipv6_cidr_blocks = []
  }

  # 控制平面节点对外公开 https 端口（kubectl/vpn 等）
  egress {
    description      = "Allow all outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

# 为 EKS Worker 节点创建安全组
resource "aws_security_group" "eks_node_sg" {
  name        = "${var.cluster_name}-node-sg"
  description = "EKS Worker 节点安全组"
  vpc_id      = aws_vpc.main.id

  # 允许 Worker 节点与控制平面通信
  ingress {
    description      = "Worker to Control Plane"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups  = [aws_security_group.eks_cluster_sg.id]
    self             = false
    cidr_blocks      = []
    ipv6_cidr_blocks = []
  }

  # 允许节点组内节点相互通信（NodePort、Pod 互通等）
  ingress {
    description = "Node to Node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # 允许 Node 出站访问 Internet
  egress {
    description      = "Allow all outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.cluster_name}-node-sg"
  }
}
# IAM Role: EKS 集群角色
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
}

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# 附加 EKS 集群所需的管理策略
resource "aws_iam_role_policy_attachment" "eks_cluster_attach" {
  count      = 2
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = element(
    [
      "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
      "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
    ],
    count.index
  )
}

# IAM Role: EKS NodeGroup 节点角色
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
}

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# 为 NodeGroup 节点附加策略
resource "aws_iam_role_policy_attachment" "eks_node_attach" {
  count      = 3
  role       = aws_iam_role.eks_node_role.name
  policy_arn = element(
    [
      "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
      "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    ],
    count.index
  )
}
# EKS 集群本体
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"   # 2025 年最新的 EKS Kubernetes 版本之一，可根据实际情况调整

  # VPC 配置：使用私有子网进行 Pod 网络，控制平面节点置于公有子网
  vpc_config {
    subnet_ids         = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
    endpoint_private_access = true  # 开启私有访问
    endpoint_public_access  = true  # 同时保留公有访问
  }

  # 此处可添加额外的配置，比如 logging、identity providers 等
  # ... 

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_attach
  ]

  tags = {
    Name = var.cluster_name
  }
}

# 用于 kubernetes provider 的 Auth Token
data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
  depends_on = [
    aws_eks_cluster.eks
  ]
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}
# EKS 托管节点组
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-nodegroup"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id   # 节点放在私有子网

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  instance_types = [var.node_instance_type]

  ami_type = "AL2_x86_64"   # Amazon Linux 2

  remote_access {
    ec2_ssh_key = "my-eks-keypair"  # 请提前在 AWS 控制台创建好对应的 Key Pair
    source_security_group_ids = [
      aws_security_group.eks_node_sg.id
    ]
  }

  disk_size = 20   # 根卷大小（GiB）

  tags = {
    Name = "${var.cluster_name}-node"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_attach
  ]
}
