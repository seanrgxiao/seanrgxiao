# variables.tf

variable "aws_region" {
  description = "AWS 区域"
  type        = string
  default     = "ap-southeast-1"
}

variable "cluster_name" {
  description = "EKS 集群名称"
  type        = string
  default     = "eks-cluster-2025"
}

variable "environment" {
  description = "环境名称"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "VPC CIDR 块"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "私有子网 CIDR 块"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "公有子网 CIDR 块"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}
