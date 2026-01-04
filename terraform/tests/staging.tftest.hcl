run "staging_environment_validation" {
  command = plan

  variables {
    project_id           = "test-project-staging"
    environment          = "staging"
    cluster_name         = "gke-staging-cluster"
    region               = "europe-west1"
    kubernetes_namespace = "staging"
    helm_release_name    = "mainwebsite-staging"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "v1.2.3"
    metrics_image_tag     = "v1.2.3"
  }

  assert {
    condition     = var.environment == "staging"
    error_message = "Environment should be staging for staging deployment."
  }

  assert {
    condition     = var.kubernetes_namespace == "staging"
    error_message = "Staging should use staging namespace."
  }

  assert {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Region must be a valid GCP region format."
  }
}

run "staging_namespace_validation" {
  command = plan

  variables {
    project_id           = "test-project-staging"
    environment          = "staging"
    cluster_name         = "gke-staging-cluster"
    region               = "europe-west1"
    kubernetes_namespace = "staging"
    helm_release_name    = "mainwebsite-staging"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "v1.2.3"
    metrics_image_tag     = "v1.2.3"
  }

  assert {
    condition     = output.application_namespace == "staging"
    error_message = "Application namespace output should be staging."
  }
}
