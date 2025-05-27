provider "aws" {
  region = "ap-southeast-1"  # 修改为你的区域
}

provider "kubernetes" {
  host                   = "https://FEFDCEE83C61234BDE18540020B872C9.gr7.ap-southeast-1.eks.amazonaws.com"   # 从 AWS CLI 获取的 API 端点
  cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJTSszZ0cyeW00RWt3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBMU1qWXdOek14TWpWYUZ3MHpOVEExTWpRd056TTJNalZhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUR6bTNTUGs4aUp1VEp6NncxVlpmaE1JREl0OUdTWDZGVTE1emhEdUVTSjhhb0RPTjh3MXZodGhrVDgKWG5pRktQOHEyV2twQkd0Yno4VHR3WkFEWUZhaTFiNlhMamNXbkVIQnRodit3SXZDQjRWaUpKUVZMSzN6L3lBVQpHWWVZU2ZBTytGeEhhMEp0TW95d1piS1RESkp3cnVnOFcyVmtyZ1hZYnBMczVrUjBwNTJxWHliUDJ0Tm9nendrCldlbzM4M3UwemVSa20zcmI1ODZNOFc1UzJuN3lWMVBQaWpDUUtRY1dDUDhwMUdlM2xuSkFuVVZIWnJXQXJKSUMKMnZsZ0ppdUFxbTAycDYwa1JNRnNMd0F3SVFuR0lBSC8zNDB5Tk51YWt2WHZPSVBpVm1xazZ4dzE2WlJtY2prSwpqbFA5b05mQ2MrbWN2N0xwQVozakZSRElncnJGQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJTWXg4ZURDNEp0cW9OT1dPZGZTcGJHdGFWK2xEQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQUpSR3dBVEw0cQpWaXRZMTFWY0huRXpuRWEreHJUMzhQQURSSDZDWW9GYXJLQTRvUm1wc25mQWo4Tk1iaDZVMEFLVW5xRHFCOS9ECm5mczdOcUFkQ1pQMVE2Qm9FTWdXS3J1VnNnaHRqV3lYTEp3TXlQUWdkSTlCRXltU1VJZysraXhIdGNuNUplOUEKTktSVHpLY25GSlZra21EMVc0ZjJFaWxsY25vQmVDUE8wRGlKSHZyWUd3azdMOFlPU2xwL2gyenZWdGUvNVY5Uwo0b0wrT25obGx3Q203dWNSSjA0ZVdaMGE0azVZL1gzZlNWalpCZEVmejZuN0ZudjFaWnJzNFlDTDN0SEJjcmM0CndiQVNuZ090cUpsM2JIYnFMQVdTUGVHQjNWRDgrbnhtMmgyV1AxVExuVVJTdFhQREt6cjZBejBieTlXZjZRUUMKUWZLS3hYUWFGS25xCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")  # 从 AWS CLI 获取的 CA 证书
  token                  = "k8s-aws-v1.aHR0cHM6Ly9zdHMuYXAtc291dGhlYXN0LTEuYW1hem9uYXdzLmNvbS8_QWN0aW9uPUdldENhbGxlcklkZW50aXR5JlZlcnNpb249MjAxMS0wNi0xNSZYLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFSWjVCTkVJWlNXQ01OT0daJTJGMjAyNTA1MjYlMkZhcC1zb3V0aGVhc3QtMSUyRnN0cyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwNTI2VDA3NTUzM1omWC1BbXotRXhwaXJlcz02MCZYLUFtei1TaWduZWRIZWFkZXJzPWhvc3QlM0J4LWs4cy1hd3MtaWQmWC1BbXotU2lnbmF0dXJlPWYxYWY1NDRiZjNiNzM3YThmMDI4ZTg5YTk3MjBmMzg1ODgzYWMwMjlhODk1ZDBjNjM5NGQzMDMwZDQ3NTYzMjM"  # 从 AWS CLI 获取的认证令牌
}

resource "null_resource" "list_nodes" {
  triggers = {
    always_run = "${timestamp()}"  # 使用 timestamp 触发重新执行
  }
  provisioner "remote-exec" {
    inline = [
      "sudo /usr/local/bin/kubectl get nodes",  # 在远程服务器上执行 kubectl 命令
      "sudo /usr/local/bin/kubectl get namespaces",
      "sudo /usr/local/bin/kubectl cluster-info"
    ]
    
    connection {
      type        = "ssh"
      host        = "18.142.186.10"  # EC2 实例 IP
      user        = "ec2-user"
      private_key = file("id_rsa.pem")  # SSH 私钥路径
    }
  }
}

# VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "eks-vpc"
  }
}

resource "aws_subnet" "eks_subnet_a" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-subnet-a"
  }
}

resource "aws_subnet" "eks_subnet_b" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-subnet-b"
  }
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks-igw"
  }
}

resource "aws_route_table" "eks_route_table" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "eks-route-table"
  }
}

resource "aws_route_table_association" "eks_rta_a" {
  subnet_id      = aws_subnet.eks_subnet_a.id
  route_table_id = aws_route_table.eks_route_table.id
}

resource "aws_route_table_association" "eks_rta_b" {
  subnet_id      = aws_subnet.eks_subnet_b.id
  route_table_id = aws_route_table.eks_route_table.id
}
resource "aws_iam_policy" "eks_user_policy" {
  name        = "tfuser-eks-policy"
  description = "Policy to allow tfuser to interact with EKS clusters and node groups"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "eks:ListNodegroups",
          "eks:DescribeCluster",
          "eks:DescribeNodegroup"
        ]
        Resource = "arn:aws:eks:ap-southeast-1:124355682867:cluster/example-eks-cluster"
      }
    ]
  })
  lifecycle {
    prevent_destroy = true
  }
}
# IAM role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# IAM role for EKS Worker Nodes
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Security group for EKS cluster control plane
resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "Allow communication between EKS control plane and worker nodes"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    description = "Allow pods to communicate with cluster API Server"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-cluster-sg"
  }
}

# Create EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "example-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = [aws_subnet.eks_subnet_a.id, aws_subnet.eks_subnet_b.id]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
    endpoint_public_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy
  ]
}

# Node Group (Managed NodeGroup)
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "example-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.eks_subnet_a.id, aws_subnet.eks_subnet_b.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  ami_type       = "AL2_x86_64"
  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only
  ]
}
# resource "null_resource" "execute_command" {
#   provisioner "local-exec" {
#     command = "kubectl get nodes"
#   }

#   depends_on = [aws_eks_cluster.eks_cluster]
# }