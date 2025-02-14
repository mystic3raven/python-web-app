resource "kubernetes_deployment" "python_web_app" {
  metadata {
    name = "python-web-app"
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
        container {
          name  = "python-web-app"
          image = "${aws_ecr_repository.repo.repository_url}:latest"
          port {
            container_port = 5000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "python_web_service" {
  metadata {
    name = "python-web-app"
  }

  spec {
    selector = {
      app = "python-web-app"
    }

    port {
      port        = 80
      target_port = 5000
    }

    type = "LoadBalancer"
  }
}
