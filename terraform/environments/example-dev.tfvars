# Example Terraform Configuration for Development Environment
# Copy this file to environments/dev.tfvars and customize for your setup

# ============================================================
# GCP Configuration
# ============================================================

# Your GCP project ID
# Get this from: gcloud config get-value project
project_id = "clever-spirit-417020"

# GCP region for GKE cluster
# Options: us-central1, us-west1, us-east1, europe-west1, asia-east1
region = "us-central1"

# Environment name (dev/staging/production)
environment = "dev"

# Path to service account JSON key
# Get this from: gcloud iam service-accounts keys create
# IMPORTANT: Add this file to .gitignore - NEVER commit to version control
credentials_file = "./clever-spirit-terraform-service-account.json"

# ============================================================
# GKE Cluster Configuration
# ============================================================

# GKE cluster name
cluster_name = "gcp-info-website-dev"

# Initial number of nodes in default node pool
cluster_initial_node_count = 1

# Machine type for cluster nodes
# Options: n1-standard-1, n1-standard-2, n1-standard-4, e2-standard-2, e2-standard-4
cluster_machine_type = "n1-standard-1"

# Kubernetes version (omit for latest stable)
# Get available versions: gcloud container get-server-config --region=us-central1
cluster_kubernetes_version = "latest"

# ============================================================
# Kubernetes Configuration
# ============================================================

# Kubernetes namespace where applications will be deployed
kubernetes_namespace = "development"

# ============================================================
# Helm Configuration
# ============================================================

# Path to Helm chart (relative to terraform directory)
helm_chart_path = "../helm-dir"

# Helm release name (how it appears in "helm list")
helm_release_name = "mainwebsite"

# Timeout for Helm release deployment (seconds)
# Increase if deployments are timing out
helm_timeout = 300

# Atomic deployment: rollback on failed deployment
helm_atomic_deployment = true

# Wait for resources to be ready before returning
helm_wait = true

# ============================================================
# Application Configuration
# ============================================================

# Image tags for services
# For development: use 'dev-latest' for continuous development
# For staging: use 'staging-latest' for testing
# For production: use specific versions like 'v1.0.0', never 'latest'

mainwebsite_image_tag = "dev-latest"
metrics_image_tag = "dev-latest"

# Additional Helm values to override in the chart
# These are set as --set flags in Helm
helm_set_values = {
  # Replica counts
  "mainwebsite.replicaCount"           = "1"
  "metrics.replicaCount"               = "1"

  # Resource requests (usually lower in dev)
  "mainwebsite.resources.requests.memory"    = "256Mi"
  "mainwebsite.resources.requests.cpu"       = "100m"
  "mainwebsite.resources.limits.memory"      = "512Mi"
  "mainwebsite.resources.limits.cpu"         = "500m"

  # Autoscaling disabled in dev
  "mainwebsite.autoscaling.enabled"   = "false"
  "metrics.autoscaling.enabled"       = "false"

  # Ingress configuration (adjust hostname for your environment)
  "ingress.enabled"                   = "true"
  "ingress.hosts[0].host"             = "dev.gcp-info-website.local"
  "ingress.tls.enabled"               = "false"

  # Update strategy
  "mainwebsite.strategy.type"         = "RollingUpdate"
}

# ============================================================
# Labels
# ============================================================

# Common labels applied to all resources
common_labels = {
  environment = "dev"
  managed_by  = "terraform"
  project     = "gcp-info-website"
  team        = "platform"
}

# ============================================================
# Development-Specific Notes
# ============================================================

# Development environment guidelines:
# - Single replica for resource efficiency
# - Minimal resource requests
# - No autoscaling
# - No persistent storage required
# - Latest development images
# - No TLS required
# - Minimal logging level

# Cost estimates for this configuration:
# - Single n1-standard-1 node (hourly): ~$0.05
# - Monthly estimate: ~$35 (cloud costs only, excluding storage/networking)

# Next steps after applying this configuration:
# 1. Run: terraform apply -var-file="environments/dev.tfvars"
# 2. Verify deployment: kubectl get pods -n development
# 3. Access application: kubectl port-forward -n development svc/mainwebsite 8080:80
# 4. View logs: kubectl logs -n development -l app=mainwebsite
