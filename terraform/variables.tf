################################################################################
# GCP Configuration Variables
################################################################################

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be a valid GCP project ID format."
  }
}

variable "region" {
  description = "The GCP region for resource deployment (e.g., us-central1, europe-west1)"
  type        = string
  default     = "us-central1"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Region must be a valid GCP region format."
  }
}

variable "credentials_file" {
  description = "Path to GCP service account credentials JSON file (optional if GOOGLE_APPLICATION_CREDENTIALS is set)"
  type        = string
  default     = null
  nullable    = true
  sensitive   = true

  validation {
    condition     = var.credentials_file == null || can(file(var.credentials_file))
    error_message = "Credentials file must exist and be readable, or leave null to use GOOGLE_APPLICATION_CREDENTIALS environment variable."
  }
}

################################################################################
# Environment Configuration
################################################################################

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

################################################################################
# Kubernetes & GKE Configuration
################################################################################

variable "cluster_name" {
  description = "Name of the existing GKE cluster"
  type        = string
  nullable    = false

  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 40
    error_message = "Cluster name must be between 1 and 40 characters."
  }
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for deploying the application"
  type        = string
  default     = "default"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.kubernetes_namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

################################################################################
# Helm Chart Configuration
################################################################################

variable "helm_chart_path" {
  description = "Path to the Helm chart directory (relative or absolute)"
  type        = string
  default     = "../helm-dir"
  nullable    = false
}

variable "helm_release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "mainwebsite"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.helm_release_name))
    error_message = "Helm release name must be a valid Kubernetes resource name."
  }
}

variable "helm_timeout" {
  description = "Timeout for Helm deployment in seconds"
  type        = number
  default     = 300
  nullable    = false

  validation {
    condition     = var.helm_timeout > 0 && var.helm_timeout <= 3600
    error_message = "Helm timeout must be between 1 and 3600 seconds."
  }
}

variable "helm_atomic_deployment" {
  description = "If true, helm upgrade process rolls back changes on failure"
  type        = bool
  default     = true
  nullable    = false
}

variable "helm_set_values" {
  description = "Additional Helm values to set via command line"
  type        = map(string)
  default     = {}
  nullable    = false
}

################################################################################
# Container Image Configuration
################################################################################

variable "mainwebsite_image_tag" {
  description = "Docker image tag for the mainwebsite service"
  type        = string
  default     = "latest"
  nullable    = false

  validation {
    condition     = length(var.mainwebsite_image_tag) > 0
    error_message = "Image tag must not be empty."
  }
}

variable "metrics_image_tag" {
  description = "Docker image tag for the metrics service"
  type        = string
  default     = "latest"
  nullable    = false

  validation {
    condition     = length(var.metrics_image_tag) > 0
    error_message = "Image tag must not be empty."
  }
}

################################################################################
# Optional: Remote State Configuration (uncomment to use)
################################################################################

# variable "state_bucket" {
#   description = "GCS bucket for storing Terraform state"
#   type        = string
#   default     = ""
#   nullable    = false
# }

# variable "state_encryption_key" {
#   description = "Encryption key for state file (base64 encoded 32-byte key)"
#   type        = string
#   sensitive   = true
#   default     = ""
# }

################################################################################
# Optional: Labels and Tags
################################################################################

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "gcp-info-website"
  }
  nullable = false
}

################################################################################
# Terraform State Management (Google Cloud Storage Backend)
################################################################################

variable "terraform_state_bucket" {
  description = "GCS bucket name for storing Terraform state"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]*[a-z0-9]$", var.terraform_state_bucket))
    error_message = "Terraform state bucket must be a valid GCS bucket name."
  }
}

variable "terraform_state_prefix" {
  description = "Prefix path in the GCS bucket for Terraform state files"
  type        = string
  default     = "gcp-info-website/terraform"
  nullable    = false

  validation {
    condition     = length(var.terraform_state_prefix) > 0
    error_message = "Terraform state prefix must not be empty."
  }
}

