################################################################################
# GKE Deployment Module - Outputs
################################################################################

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.deployment.name
}

output "helm_release_namespace" {
  description = "Namespace of the Helm release"
  value       = helm_release.deployment.namespace
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.deployment.status
}

output "helm_release_version" {
  description = "Version of the Helm chart"
  value       = helm_release.deployment.version
}
