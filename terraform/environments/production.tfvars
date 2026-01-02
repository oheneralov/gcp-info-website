# Production Environment Variables
# Usage: terraform apply -var-file="environments/production.tfvars"
# IMPORTANT: Treat this file as sensitive - consider using remote state or Terraform Cloud

project_id            = "clever-spirit-417020"
region                = "us-central1"
environment           = "production"
cluster_name          = "gcp-info-website-prod"
kubernetes_namespace  = "production"
credentials_file      = "./clever-spirit-terraform-service-account.json"

helm_chart_path       = "../helm-dir"
helm_release_name     = "mainwebsite"
helm_timeout          = 600
helm_atomic_deployment = true

# Use explicit version tags in production, never "latest"
mainwebsite_image_tag = "1.0.0"
metrics_image_tag     = "1.0.0"

helm_set_values = {
  "mainwebsite.replicaCount" = "3"
  "metrics.replicaCount"     = "2"
  "mainwebsite.autoscaling.enabled" = "true"
  "mainwebsite.autoscaling.minReplicas" = "3"
  "mainwebsite.autoscaling.maxReplicas" = "10"
  "metrics.autoscaling.enabled" = "true"
  "metrics.autoscaling.maxReplicas" = "5"
  "monitoring.serviceMonitor.enabled" = "true"
}

common_labels = {
  environment = "production"
  managed_by  = "terraform"
  project     = "gcp-info-website"
  team        = "platform"
  sla         = "high"
}
