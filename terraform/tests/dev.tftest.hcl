run "development_environment_validation" {
  command = plan

  variables {
    project_id           = "test-project-dev"
    environment          = "dev"
    cluster_name         = "gke-dev-cluster"
    region               = "us-central1"
    kubernetes_namespace = "default"
    helm_release_name    = "mainwebsite"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "latest"
    metrics_image_tag     = "latest"
  }

  assert {
    condition     = var.environment == "dev"
    error_message = "Environment should be dev for development deployment."
  }

  assert {
    condition     = var.region == "us-central1"
    error_message = "Dev environment should use us-central1 region."
  }

  assert {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Invalid environment value."
  }
}

run "dev_output_validation" {
  command = plan

  variables {
    project_id           = "test-project-dev"
    environment          = "dev"
    cluster_name         = "gke-dev-cluster"
    region               = "us-central1"
    kubernetes_namespace = "default"
    helm_release_name    = "mainwebsite"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "v1.0.0-dev"
    metrics_image_tag     = "v1.0.0-dev"
  }

  assert {
    condition     = output.environment == "dev"
    error_message = "Output environment should match input environment."
  }

  assert {
    condition     = output.gcp_project_id == "test-project-dev"
    error_message = "Output project ID should match input project ID."
  }
}
