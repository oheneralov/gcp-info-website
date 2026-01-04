run "production_environment_validation" {
  command = plan

  variables {
    project_id           = "test-project-production"
    environment          = "production"
    cluster_name         = "gke-prod-cluster"
    region               = "us-central1"
    kubernetes_namespace = "production"
    helm_release_name    = "mainwebsite-prod"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "v2.0.0"
    metrics_image_tag     = "v2.0.0"
  }

  assert {
    condition     = var.environment == "production"
    error_message = "Environment should be production for production deployment."
  }

  assert {
    condition     = var.kubernetes_namespace == "production"
    error_message = "Production should use production namespace."
  }
}

run "production_strict_validation" {
  command = plan

  variables {
    project_id           = "test-project-production"
    environment          = "production"
    cluster_name         = "gke-prod-cluster"
    region               = "us-central1"
    kubernetes_namespace = "production"
    helm_release_name    = "mainwebsite-prod"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "v2.0.0"
    metrics_image_tag     = "v2.0.0"
  }

  # Ensure production uses proper image tags (not latest)
  assert {
    condition     = !contains(["latest", "dev", "master"], var.mainwebsite_image_tag)
    error_message = "Production mainwebsite image tag must not be 'latest', 'dev', or 'master'."
  }

  assert {
    condition     = !contains(["latest", "dev", "master"], var.metrics_image_tag)
    error_message = "Production metrics image tag must not be 'latest', 'dev', or 'master'."
  }

  # Verify proper credentials handling
  assert {
    condition     = output.gcp_project_id == "test-project-production"
    error_message = "Production should deploy to the correct GCP project."
  }
}
