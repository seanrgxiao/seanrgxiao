# main.tf

# 配置 AWS provider
provider "aws" {
  region = "ap-southeast-1" # 根据你的需求更改区域
}

# 数据源：获取可用区
data "aws_availability_zones" "available" {
  state = "available"
}

# 创建 VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "my-eks-vpc"
  }
}

# 创建公共子网
resource "aws_subnet" "public" {
  count = 2 # 创建两个公共子网

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10) # 示例 CIDR 块
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # 允许在公共子网中启动的实例分配公共 IP

  tags = {
    Name = "my-eks-public-subnet-${count.index}"
  }
}

# 创建私有子网 (可选，但推荐用于生产环境)
resource "aws_subnet" "private" {
  count = 2 # 创建两个私有子网

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 20) # 示例 CIDR 块
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "my-eks-private-subnet-${count.index}"
  }
}

# 创建 Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-eks-igw"
  }
}

# 创建公共路由表
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "my-eks-public-route-table"
  }
}

# 将公共子网与公共路由表关联
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 创建 NAT Gateway (用于私有子网的 Internet 访问)
resource "aws_eip" "nat" {
  count = length(aws_subnet.public) # 为每个公共子网创建一个 NAT Gateway

  vpc = true
}

resource "aws_nat_gateway" "main" {
  count = length(aws_subnet.public)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "my-eks-nat-gateway-${count.index}"
  }

  # Ensure the NAT Gateway is created after the EIP is provisioned
  depends_on = [aws_internet_gateway.main]
}

# 创建私有路由表
resource "aws_route_table" "private" {
  count = length(aws_subnet.private) # 为每个私有子网创建一个路由表

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id # 关联到 NAT Gateway
  }

  tags = {
    Name = "my-eks-private-route-table-${count.index}"
  }
}

# 将私有子网与私有路由表关联
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


# 使用 EKS 模块创建 Kubernetes 集群
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0" # 使用最新稳定版本，请查阅 Terraform Registry

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.28" # 指定 Kubernetes 版本

  vpc_id = aws_vpc.main.id
  subnet_ids = concat(aws_subnet.public.*.id, aws_subnet.private.*.id) # 将公共和私有子网都包含在内

  # EKS 控制平面访问设置
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # 可选：集群日志
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # EKS 管理节点组 (Managed Node Group)
  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.large"] # 节点实例类型
      min_size       = 1
      max_size       = 3
      desired_size   = 2

      # 可以在这里指定更多配置，例如 AMI 类型、标签等
      # ami_type = "AL2_x86_64"
    }
  }

  tags = {
    Environment = "Dev"
    Project     = "Kubernetes"
  }
}

# 输出 EKS 集群的 kubeconfig 信息，以便 kubectl 连接
output "kubeconfig" {
  description = "Kubeconfig to connect to the EKS cluster"
  value       = module.eks.kubeconfig
  sensitive   = true
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}
