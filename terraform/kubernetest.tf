resource "kubernetes_namespace" "python_app" {
  metadata {
    name = "python-app"
  }
}

# Kubernetes Deployment for Python Web App
resource "kubernetes_deployment" "python_web_app" {
  metadata {
    name      = "python-web-app"
    namespace = kubernetes_namespace.python_app.metadata[0].name
    labels = {
      app = "python-web-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "python-web-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "python-web-app"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.eks_admin.metadata[0].name

        container {
          name  = "python-web-app"
          image = "myrepo/python-web-app:latest"
          port {
            container_port = 5000
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.python_web_config.metadata[0].name
            }
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
          env {
            name  = "ENVIRONMENT"
            value = "production"
          }
        }
      }
    }
  }
}

# Kubernetes Service to expose the app
resource "kubernetes_service" "python_web_service" {
  metadata {
    name      = "python-web-service"
    namespace = kubernetes_namespace.python_app.metadata[0].name
  }

  spec {
    selector = {
      app = "python-web-app"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 5000
    }

    type = "LoadBalancer"
  }
}

# Kubernetes ConfigMap
resource "kubernetes_config_map" "python_web_config" {
  metadata {
    name      = "python-web-config"
    namespace = kubernetes_namespace.python_app.metadata[0].name
  }

  data = {
    APP_ENV       = "production"
    APP_DEBUG     = "false"
    DATABASE_HOST = "db-host.example.com"
    DATABASE_PORT = "5432"
    DATABASE_NAME = "python_web_app"
    LOG_LEVEL     = "info"
  }
}

# EKS IAM Role for Authentication


# Kubernetes RBAC for GitHub Actions OIDC
resource "kubernetes_cluster_role_binding" "github_actions_rbac" {
  metadata {
    name = "github-actions-rbac"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "User"
    name      = "GitHubActionsOIDC" # Matches IAM Role username in aws-auth
    api_group = "rbac.authorization.k8s.io"
  }
}

# Kubernetes RBAC for eks-admin
resource "kubernetes_cluster_role_binding" "eks_admin_rbac" {
  metadata {
    name = "eks-admin-rbac"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "User"
    name      = "eks-admin" # Matches IAM Role username in aws-auth
    api_group = "rbac.authorization.k8s.io"
  }
}

# Service Account for EKS Admin Role
resource "kubernetes_service_account" "eks_admin" {
  metadata {
    name      = "eks-admin"
    namespace = "kube-system"
  }
}

# Kubernetes RoleBinding for eks-admin
resource "kubernetes_role_binding" "eks_admin_binding" {
  metadata {
    name      = "eks-admin-binding"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.eks_admin.metadata[0].name
    namespace = "kube-system"
  }
}

