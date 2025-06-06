variable "aws_region" {
  description = "要创建 EKS 集群的 AWS 区域"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS 集群名称"
  type        = string
  default     = "tf-eks-demo"
}

variable "vpc_cidr" {
  description = "VPC 的 CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "公有子网的 CIDR 列表"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets_cidr" {
  description = "私有子网的 CIDR 列表"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "node_instance_type" {
  description = "EKS 托管节点组使用的 EC2 实例类型"
  type        = string
  default     = "t3.medium"
}

variable "desired_capacity" {
  description = "EKS 托管节点组初始期望实例数"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "EKS 托管节点组最大实例数"
  type        = number
  default     = 3
}

variable "min_capacity" {
  description = "EKS 托管节点组最小实例数"
  type        = number
  default     = 1
}
