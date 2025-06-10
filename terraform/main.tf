provider "google" {
  credentials = file("C:/alex/work/gcp-info-website/clever-spirit-terraform-service-account.json")
  project     = var.project_id
  region      = var.region
}

data "google_client_config" "default" {}

data "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.region
}

provider "kubernetes" {
  host  = data.google_container_cluster.gke.endpoint
  token = data.google_client_config.default.access_token

  cluster_ca_certificate = base64decode(
    data.google_container_cluster.gke.master_auth[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host                   = data.google_container_cluster.gke.endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.gke.master_auth[0].cluster_ca_certificate
    )
  }
}

resource "helm_release" "helm-dir" {
  name       = "helm-dir"
  chart      = "../helm-dir"   # Path to your Helm chart
  namespace  = "default"

  values = [file("../helm-dir/values.yaml")]

  # optional: to force a new deployment when chart files change
  # version = "1.0.0"
  # set {
  #   name  = "image.tag"
  #   value = "v1.2.3"
  # }
}
