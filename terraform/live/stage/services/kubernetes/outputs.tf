# 输出 EKS 集群 Endpoint
output "cluster_endpoint" {
  description = "EKS 集群的 Kubernetes API Server Endpoint"
  value       = aws_eks_cluster.eks.endpoint
}

# 输出 EKS 集群 CA 证书
output "cluster_ca_certificate_data" {
  description = "用于 kubectl 访问的 CA 证书"
  value       = aws_eks_cluster.eks.certificate_authority[0].data
}

# 输出 kubeconfig 片段示例（用户可以自己拼接到本地的 kubeconfig）
output "kubeconfig" {
  description = "可拷贝到本地 kubeconfig 的片段示例"
  value = <<EOF
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks.certificate_authority[0].data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - "eks"
        - "get-token"
        - "--cluster-name"
        - "${aws_eks_cluster.eks.name}"
EOF
}

# 输出 NodeGroup 中各节点的子网列表
output "nodegroup_subnets" {
  description = "EKS Worker 节点所在私有子网 ID 列表"
  value       = aws_eks_node_group.node_group.subnet_ids
}
