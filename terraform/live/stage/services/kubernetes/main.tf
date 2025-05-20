provider "aws" {
  region = "ap-southeast-1"  # 修改为你的区域
}

provider "kubernetes" {
  host                   = "https://F8F0631E37790AE6E72CF79B232CDDCA.gr7.ap-southeast-1.eks.amazonaws.com"   # 从 AWS CLI 获取的 API 端点
  cluster_ca_certificate = base64decode("LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJYzIxWFZ6bk1HVTh3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBMU1UWXdOak16TXpkYUZ3MHpOVEExTVRRd05qTTRNemRhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUR6Z3lPcm5GWmwrTFdjR0diMEQ3d0UzQm92N1Uya29VeG1JRG1xekVHVm1vbWxWWEZURkhRMjFjVHkKSXpBK3FvdkFQSW9SOFNmV1YvYUZPRmkvcDZLVGg1UkR4OHJXUWo0c3g0R0JmbE1RSHBoUFpWUlQ4WDdMN3NETQpyQWI1dzNSVTczeDRtOEp5U1RUK3FrSHlaWWhDdWVISTdicTd4QndZZXlycndYWkN4dHREanQwVU1OS2c1aElICmVLS0oxUXdFUG41cWVRWkdQNW9zYVBrSjNveVhScVNoRWxtSS9sR05vU3l5RXl2UVF5VFRlcVJkcFU2SmdLVHMKakIvSllwRUFHVUpGT3k0N0xvbE81cXRhOENLQkNsU2RoZWpBbjJ6R1ZJdnY5a0JDbjEvNnljbXA1RHhlSXhwNQpUSmRmYm11ZWpmK2hEUmQxTlZJMHEwQktpTXM1QWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSV0RsK1lEZjdmVHB4ZC81TTVNRnpkbFg4dXpEQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQUhuNTczNmYvcAp1NEZQOW9VcUVmaXlZaUhDR2VsWDFrbnVuSDNuOFhINktUVUlQaFdVK0NBRkZjRXpNUCs4Ukg0bFlFUlQwKzFnCmJ0Q0kyU05MQS9JcEF2UkFJdFRYWXZXR1BYdmhUTmdHQjIvV2wwREV4aVA3Njl6UlQzV2xYS0RMSEdKSHljMEIKSGlXcDNWeVJhRDdYdDJaSTk0Qm1iWHhlcnZ1a2tRbFp2NXFpTTJpZnR2Vk9vSjhnZmRncUI4cmdxQnlmVTlZNApKQjVVaU9qWDQrYU4rZkg0ckZRZExxZTdLbFBRT2dvRmZjSUZ2YUNkaFM4ZWN5Um5ZUUxFWkdoeEE5dXF6ZlkxCnphaTB0cG54cEtyanpEcEJTRlc2aVFhWTRwek9vMEQzK1l1QnhJYXZlY0Q1WVlKN2ZYbmhVQUNOOTE5Q0RmS2UKVDdEVDREdmNTZUg5Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K")  # 从 AWS CLI 获取的 CA 证书
  token                  = "k8s-aws-v1.aHR0cHM6Ly9zdHMuYXAtc291dGhlYXN0LTEuYW1hem9uYXdzLmNvbS8_QWN0aW9uPUdldENhbGxlcklkZW50aXR5JlZlcnNpb249MjAxMS0wNi0xNSZYLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFSWjVCTkVJWlNXQ01OT0daJTJGMjAyNTA1MTYlMkZhcC1zb3V0aGVhc3QtMSUyRnN0cyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwNTE2VDA3NTQyNlomWC1BbXotRXhwaXJlcz02MCZYLUFtei1TaWduZWRIZWFkZXJzPWhvc3QlM0J4LWs4cy1hd3MtaWQmWC1BbXotU2lnbmF0dXJlPWVmMmFmOWIxYThhZjc2NzM3ZTgxYWU0NWU0YThlNjc0YjUzZWM5ZDg2YjhlOWY1MzIzMmU0ZjUxNDIyNjUyNTU"  # 从 AWS CLI 获取的认证令牌
}

resource "null_resource" "list_nodes" {
  provisioner "remote-exec" {
    inline = [
      "sudo /usr/local/bin/kubectl get nodes"  # 在远程服务器上执行 kubectl 命令
    ]
    
    connection {
      type        = "ssh"
      host        = "127.0.0.1"  # EC2 实例 IP
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