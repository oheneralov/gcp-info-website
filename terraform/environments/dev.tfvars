# Development Environment Variables
# Usage: terraform apply -var-file="environments/dev.tfvars"

project_id            = "clever-spirit-417020"
region                = "us-central1"
environment           = "dev"
cluster_name          = "gcp-info-website-dev"
kubernetes_namespace  = "development"
credentials_file      = "./clever-spirit-terraform-service-account.json"

helm_chart_path       = "../helm-dir"
helm_release_name     = "mainwebsite"
helm_timeout          = 300
helm_atomic_deployment = true

mainwebsite_image_tag = "dev-latest"
metrics_image_tag     = "dev-latest"

helm_set_values = {
  "mainwebsite.replicaCount" = "1"
  "metrics.replicaCount"     = "1"
}

common_labels = {
  environment = "dev"
  managed_by  = "terraform"
  project     = "gcp-info-website"
  team        = "platform"
}
