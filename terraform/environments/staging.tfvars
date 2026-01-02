# Staging Environment Variables
# Usage: terraform apply -var-file="environments/staging.tfvars"

project_id            = "clever-spirit-417020"
region                = "us-central1"
environment           = "staging"
cluster_name          = "gcp-info-website-staging"
kubernetes_namespace  = "staging"
credentials_file      = "./clever-spirit-terraform-service-account.json"

helm_chart_path       = "../helm-dir"
helm_release_name     = "mainwebsite"
helm_timeout          = 300
helm_atomic_deployment = true

mainwebsite_image_tag = "staging-latest"
metrics_image_tag     = "staging-latest"

helm_set_values = {
  "mainwebsite.replicaCount" = "2"
  "metrics.replicaCount"     = "1"
  "mainwebsite.autoscaling.enabled" = "true"
  "mainwebsite.autoscaling.maxReplicas" = "4"
}

common_labels = {
  environment = "staging"
  managed_by  = "terraform"
  project     = "gcp-info-website"
  team        = "platform"
}
