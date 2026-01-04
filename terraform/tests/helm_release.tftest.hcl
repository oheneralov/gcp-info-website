run "helm_release_configuration" {
  command = plan

  variables {
    project_id           = "test-project-1"
    environment          = "dev"
    cluster_name         = "test-cluster"
    region               = "us-central1"
    kubernetes_namespace = "default"
    helm_release_name    = "mainwebsite"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "v1.0.0"
    metrics_image_tag     = "v1.0.0"
  }

  assert {
    condition     = length(var.helm_release_name) > 0
    error_message = "Helm release name must not be empty."
  }

  assert {
    condition     = length(var.helm_chart_path) > 0
    error_message = "Helm chart path must not be empty."
  }
}

run "helm_values_override" {
  command = plan

  variables {
    project_id           = "test-project-1"
    environment          = "staging"
    cluster_name         = "test-cluster"
    region               = "us-central1"
    kubernetes_namespace = "staging"
    helm_release_name    = "mainwebsite-staging"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "v1.2.3"
    metrics_image_tag     = "v1.2.3"
    helm_values_override = {
      replicaCount = 2
      environment  = "staging"
    }
  }

  assert {
    condition     = output.helm_release_namespace == "staging"
    error_message = "Helm release should be deployed to staging namespace."
  }
}
