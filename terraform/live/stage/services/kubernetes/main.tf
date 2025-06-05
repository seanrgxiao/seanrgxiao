# main.tf

terraform {
  required_version = ">= 1.6.0" # 2025 年推荐版本

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.20.0" # 2025 年 AWS provider 版本
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
  }

  # backend "s3" {
  #   bucket         = "my-eks-tfstate-2025"
  #   key            = "global/eks-cluster/terraform.tfstate"
  #   region         = "us-west-2"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Terraform   = "true"
      Project     = "eks-cluster-2025"
    }
  }
}

# VPC 模块
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.0" # 2025 年 VPC 模块版本

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = var.cluster_name
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

# EKS 集群模块
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.0.0" # 2025 年 EKS 模块版本

  cluster_name                   = var.cluster_name
  cluster_version                = "1.29" # 2025 年 Kubernetes 稳定版本
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    initial = {
      instance_types = ["m6i.large"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Karpenter 自动扩缩容
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.0.0"

  cluster_name           = module.eks.cluster_name
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Environment = var.environment
  }
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "0.35.0" # 2025 年 Karpenter 版本

  set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.irsa_arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = module.karpenter.instance_profile_name
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.karpenter.queue_name
  }

  depends_on = [module.eks]
}

# AWS Load Balancer Controller
module "lb_controller" {
  source  = "terraform-aws-modules/eks/aws//modules/load-balancer-controller"
  version = "20.0.0"

  cluster_name           = module.eks.cluster_name
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn

  tags = {
    Environment = var.environment
  }
}

# Karpenter Provisioner
resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["m", "c", "r"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["5"] # 2025 年推荐第 6 代及以上实例
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64", "arm64"]
          nodeClassRef:
            name: default
          taints:
            - key: "example.com/special-taint-2025"
              value: "true"
              effect: "NoSchedule"
      limits:
        cpu: 1000
      disruption:
        consolidationPolicy: WhenUnderutilized
        expireAfter: 720h # 30 天
  YAML

  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2023 # 2025 年 Amazon Linux 版本
      role: "${module.karpenter.role_name}"
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${module.eks.cluster_name}"
      securityGroupSelectorTerms:
        - tags:
            "kubernetes.io/cluster/${module.eks.cluster_name}": "owned"
      tags:
        Environment: "${var.environment}"
        NodeClass: "default-2025"
      metadataOptions:
        httpEndpoint: "enabled"
        httpProtocolIPv6: "enabled" # 2025 年 IPv6 支持
        httpPutResponseHopLimit: 2
        httpTokens: "required"
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: "100Gi"
            volumeType: "gp3"
            encrypted: true
            deleteOnTermination: true
  YAML

  depends_on = [helm_release.karpenter]
}
