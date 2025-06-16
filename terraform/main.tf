provider "google" { # Configure the Google Cloud provider
  credentials = file("C:/alex/work/gcp-info-website/clever-spirit-terraform-service-account.json") # Path to the service account credentials JSON file
  project     = var.project_id # GCP project ID, provided as a variable
  region      = var.region     # GCP region, provided as a variable
}

# Retrieves the active Google Cloud client configuration (project, region, credentials)
data "google_client_config" "default" {}

data "google_container_cluster" "gke" {         # Data source to fetch details of an existing GKE cluster
  name     = var.cluster_name                   # Name of the GKE cluster, provided as a variable
  location = var.region                        # Location (region or zone) of the cluster, provided as a variable
}

provider "kubernetes" { # Configure the Kubernetes provider to interact with the GKE cluster
  host  = data.google_container_cluster.gke.endpoint # GKE cluster endpoint
  token = data.google_client_config.default.access_token # Access token for authentication

  cluster_ca_certificate = base64decode(
    data.google_container_cluster.gke.master_auth[0].cluster_ca_certificate # Decode the cluster CA certificate
  )
}

provider "helm" { # Configure the Helm provider to deploy Helm charts to the GKE cluster
  kubernetes {
    host                   = data.google_container_cluster.gke.endpoint # GKE cluster endpoint
    token                  = data.google_client_config.default.access_token # Access token for authentication
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.gke.master_auth[0].cluster_ca_certificate # Decode the cluster CA certificate
    )
  }
}

resource "helm_release" "helm-dir" { # Deploy a Helm chart using the Helm provider
  name       = "helm-dir"   # Name of the Helm release
  chart      = "../helm-dir"   # Path to the Helm chart directory
  namespace  = "default"    # Kubernetes namespace to deploy into

  values = [file("../helm-dir/values.yaml")] # Load custom values from a YAML file

  # optional: to force a new deployment when chart files change
  # version = "1.0.0" # Specify the chart version
  # set {
  #   name  = "image.tag" # Set a specific value in the chart
  #   value = "v1.2.3"    # Value to set
  # }
}
