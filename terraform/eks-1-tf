data "aws_vpc" "existing_vpc" {
  default = true
}

# Fetch existing public subnets
data "aws_subnets" "existing_public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }
}

# Fetch the existing IAM role for EKS Cluster (Ensure this IAM role exists in AWS)
data "aws_iam_role" "eks_cluster_role" {
  name = "eksctl-python-web-app-cluster-cluster-ServiceRole-HQMFK6q2yKCM"
}

# Fetch the existing IAM role for EKS Node Group
data "aws_iam_role" "eks_node_role" {
  name = "eksctl-python-web-app-cluster-node-NodeInstanceRole-FY2GrJjYcbMY"
}

# Fetch the IAM role for eks-admin (Ensure this IAM role exists in AWS)
data "aws_iam_role" "eks_admin_role" {
  name = aws_iam_role.eks_admin.name
}

# EKS Cluster using existing subnets
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = data.aws_subnets.existing_public_subnets.ids
  }
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-nodes-group"
  node_role_arn   = data.aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.existing_public_subnets.ids

  scaling_config {
    desired_size = var.node_count
    min_size     = 1
    max_size     = 3
  }

  instance_types = [var.instance_type]
}

# Kubernetes ConfigMap for aws-auth to include eks-admin
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = "arn:aws:iam::886436961042:role/GitHubActionsOIDC"
        username = "GitHubActionsOIDC"
        groups   = ["system:masters"]
      },
      {
        rolearn  = "arn:aws:iam::886436961042:role/eks-admin"
        username = "eks-admin"
        groups   = ["system:masters"]
      }
    ])
  }
}
