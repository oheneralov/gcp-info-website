################################################################################
# GKE Deployment Module - Main
################################################################################

# Configure Kubernetes provider for this module
provider "kubernetes" {
  host  = "https://${var.cluster_endpoint}"
  token = var.access_token

  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

# Configure Helm provider for this module
provider "helm" {
  kubernetes {
    host  = "https://${var.cluster_endpoint}"
    token = var.access_token

    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  }
}

# Create Kubernetes namespace
resource "kubernetes_namespace" "deployment" {
  metadata {
    name = var.kubernetes_namespace

    labels = merge(
      var.common_labels,
      {
        name = var.kubernetes_namespace
      }
    )
  }
}

# Deploy application via Helm
resource "helm_release" "deployment" {
  name             = var.helm_release_name
  chart            = var.helm_chart_path
  namespace        = kubernetes_namespace.deployment.metadata[0].name
  create_namespace = false
  timeout          = 300
  wait             = true
  wait_for_jobs    = true

  # Merge base and override values
  values = [
    yamlencode(merge(
      var.helm_values_base,
      {
        global = {
          namespace = kubernetes_namespace.deployment.metadata[0].name
          labels    = var.common_labels
        }
      }
    ))
  ]

  # Dynamic set values from override map
  dynamic "set" {
    for_each = var.helm_values_override
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    kubernetes_namespace.deployment
  ]
}
