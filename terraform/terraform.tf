terraform {
  # Required version constraint for Terraform
  required_version = ">= 1.0"

  # Required providers with explicit versions
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }

  # Remote state management in Google Cloud Storage
  # GCS has built-in locking
  # Backend configuration is provided via:
  # - Backend config file: terraform init -backend-config=backend-config.tfvars
  # - Command line flags: terraform init -backend-config="bucket=..." -backend-config="prefix=..."
  # - Environment file in each environment directory (dev.tfvars, staging.tfvars, production.tfvars)
  backend "gcs" {
    # Bucket and prefix are configured via backend-config during init
    # Example: terraform init -backend-config="bucket=tf-state-bucket-name" -backend-config="prefix=gcp-info-website/terraform"
  }
}

# Google Cloud Provider Configuration
# Credentials are sourced from GOOGLE_APPLICATION_CREDENTIALS environment variable
# Set it via: export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json (Unix/Linux/macOS)
#       or: $env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json" (PowerShell)
# Or pass via command line: terraform apply -var="credentials_file=/path/to/file.json"
provider "google" {
  credentials = var.credentials_file != null ? file(var.credentials_file) : null
  project     = var.project_id
  region      = var.region

  default_labels {
    labels = {
      managed_by  = "terraform"
      environment = var.environment
      project     = "gcp-info-website"
    }
  }
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  host  = "https://${data.google_container_cluster.gke.endpoint}"
  token = data.google_client_config.default.access_token

  cluster_ca_certificate = base64decode(
    data.google_container_cluster.gke.master_auth[0].cluster_ca_certificate
  )
}

# Helm Provider Configuration
provider "helm" {
  kubernetes {
    host  = "https://${data.google_container_cluster.gke.endpoint}"
    token = data.google_client_config.default.access_token

    cluster_ca_certificate = base64decode(
      data.google_container_cluster.gke.master_auth[0].cluster_ca_certificate
    )
  }
}

# Retrieve active Google Cloud client configuration
data "google_client_config" "default" {}

# Retrieve existing GKE cluster details
data "google_container_cluster" "gke" {
  name       = var.cluster_name
  location   = var.region
  project    = var.project_id
}

# Deploy mainwebsite Helm chart
resource "helm_release" "mainwebsite" {
  name             = local.helm_release_name
  namespace        = var.kubernetes_namespace
  create_namespace = true
  chart            = var.helm_chart_path
  timeout          = var.helm_timeout
  wait             = true
  wait_for_jobs    = true
  atomic           = var.helm_atomic_deployment

  # Use environment-specific values file
  values = [
    templatefile("${var.helm_chart_path}/values.yaml", {}),
    templatefile("${var.helm_chart_path}/values-${var.environment}.yaml", {})
  ]

  # Override specific chart values
  set {
    name  = "image.mainwebsite.tag"
    value = var.mainwebsite_image_tag
  }

  set {
    name  = "image.metrics.tag"
    value = var.metrics_image_tag
  }

  set {
    name  = "global.namespace"
    value = var.kubernetes_namespace
  }

  # Add labels and annotations for tracking
  dynamic "set" {
    for_each = var.helm_set_values
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    data.google_container_cluster.gke
  ]

  lifecycle {
    ignore_changes = [
      version
    ]
  }
}
