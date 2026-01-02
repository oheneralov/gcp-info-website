################################################################################
# GKE Deployment Module - Variables
################################################################################

variable "project_id" {
  description = "GCP project ID"
  type        = string
  nullable    = false
}

variable "region" {
  description = "GCP region"
  type        = string
  nullable    = false
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  nullable    = false
}

variable "credentials" {
  description = "GCP service account credentials (from google_client_config)"
  type        = any
  sensitive   = true
}

variable "cluster_endpoint" {
  description = "GKE cluster endpoint"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "access_token" {
  description = "GCP access token"
  type        = string
  sensitive   = true
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "default"
  nullable    = false
}

variable "helm_chart_path" {
  description = "Path to Helm chart"
  type        = string
  nullable    = false
}

variable "helm_release_name" {
  description = "Name of Helm release"
  type        = string
  nullable    = false
}

variable "helm_values_base" {
  description = "Base Helm values"
  type        = any
  default     = {}
}

variable "helm_values_override" {
  description = "Additional Helm values to override"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  nullable    = false
}

variable "common_labels" {
  description = "Common labels to apply"
  type        = map(string)
  default     = {}
}
