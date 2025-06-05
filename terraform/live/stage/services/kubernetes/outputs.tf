# outputs.tf

output "cluster_name" {
  description = "Kubernetes 集群名称"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS 控制平面端点"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "集群控制平面关联的安全组 ID"
  value       = module.eks.cluster_security_group_id
}

output "kubectl_config" {
  description = "kubectl 配置文件"
  value       = module.eks.kubeconfig
}

output "region" {
  description = "AWS 区域"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
