# 🚀 IAM Role for EKS Cluster (Used by Control Plane)
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# 🚀 IAM Role for GitHub Actions OIDC (For Automated Deployments)
resource "aws_iam_role" "GitHubActionsOIDC" {
  name = "GitHubActionsOIDC"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:sub" = "repo:mystic3raven/python-web-app:ref:refs/heads/main"
        }
      }
    }]
  })
}

# 🚀 IAM Role for eks-admin User (Direct EKS Access)
resource "aws_iam_role" "eks_admin" {
  name = "eks-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::886436961042:root"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# 🚀 EKS Admin Role (With Full Cluster Management Permissions)
resource "aws_iam_role" "EKSAdminRole" {
  name = "EKSAdminRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::886436961042:user/eks-admin"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# 🚀 IAM Policy for eks-admin (Full Access to EKS)
resource "aws_iam_policy" "eks_admin_policy" {
  name        = "eks-admin-policy"
  description = "Full access to manage EKS cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*",
          "iam:GetRole",
          "iam:PassRole",
          "autoscaling:*",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      }
    ]
  })
}

# 🚀 Attach IAM Policy to eks-admin Role
resource "aws_iam_role_policy_attachment" "eks_admin_attach" {
  policy_arn = aws_iam_policy.eks_admin_policy.arn
  role       = aws_iam_role.eks_admin.name
}

# 🚀 Attach IAM Policy to EKSAdminRole (Allows eks-admin to Assume)
resource "aws_iam_role_policy_attachment" "eks_admin_role_attach" {
  policy_arn = aws_iam_policy.eks_admin_policy.arn
  role       = aws_iam_role.EKSAdminRole.name
}

# 🚀 IAM Policy for GitHub Actions Access to EKS
resource "aws_iam_policy" "GitHubActionsEKSPolicy" {
  name        = "GitHubActionsEKSPolicy"
  description = "Allows GitHub Actions to interact with EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::my-eks-artifacts/*"
      }
    ]
  })
}

# 🚀 Attach IAM Policy to GitHubActionsOIDC Role
resource "aws_iam_role_policy_attachment" "GitHubActionsEKSAttach" {
  policy_arn = aws_iam_policy.GitHubActionsEKSPolicy.arn
  role       = aws_iam_role.GitHubActionsOIDC.name
}

# 🚀 IAM User eks-admin
resource "aws_iam_user" "eks_admin_user" {
  name = "eks-admin"
}

# 🚀 Attach eks-admin to EKSAdminRole
resource "aws_iam_user_policy_attachment" "eks_admin_user_role_attach" {
  user       = aws_iam_user.eks_admin_user.name
  policy_arn = aws_iam_policy.eks_admin_policy.arn
}
