run "project_id_validation" {
  command = plan

  variables {
    project_id           = "valid-project-id"
    environment          = "dev"
    cluster_name         = "test-cluster"
    region               = "us-central1"
    kubernetes_namespace = "default"
    helm_release_name    = "mainwebsite"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "latest"
    metrics_image_tag     = "latest"
  }

  assert {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must match valid GCP project ID format."
  }
}

run "region_validation" {
  command = plan

  variables {
    project_id           = "test-project-1"
    environment          = "dev"
    cluster_name         = "test-cluster"
    region               = "europe-west1"
    kubernetes_namespace = "default"
    helm_release_name    = "mainwebsite"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "latest"
    metrics_image_tag     = "latest"
  }

  assert {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Region must be a valid GCP region format."
  }
}

run "cluster_name_validation" {
  command = plan

  variables {
    project_id           = "test-project-1"
    environment          = "dev"
    cluster_name         = "valid-cluster-name"
    region               = "us-central1"
    kubernetes_namespace = "default"
    helm_release_name    = "mainwebsite"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "latest"
    metrics_image_tag     = "latest"
  }

  assert {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 40
    error_message = "Cluster name must be between 1 and 40 characters."
  }
}

run "namespace_validation" {
  command = plan

  variables {
    project_id           = "test-project-1"
    environment          = "dev"
    cluster_name         = "test-cluster"
    region               = "us-central1"
    kubernetes_namespace = "valid-namespace"
    helm_release_name    = "mainwebsite"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "latest"
    metrics_image_tag     = "latest"
  }

  assert {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.kubernetes_namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

run "environment_validation" {
  command = plan

  variables {
    project_id           = "test-project-1"
    environment          = "production"
    cluster_name         = "test-cluster"
    region               = "us-central1"
    kubernetes_namespace = "default"
    helm_release_name    = "mainwebsite"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "latest"
    metrics_image_tag     = "latest"
  }

  assert {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}
