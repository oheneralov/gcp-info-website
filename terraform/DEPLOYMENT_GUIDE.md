# Terraform Deployment Guide

Complete guide covering setup, commands, troubleshooting, and quick reference all in one document.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation & Setup](#installation--setup)
4. [Environment Configuration](#environment-configuration)
5. [Common Commands](#common-commands)
6. [Deployment Workflows](#deployment-workflows)
7. [Troubleshooting](#troubleshooting)
8. [Quick Reference](#quick-reference)

---

## Overview

This Terraform project manages deployment of the GCP Info Website application on Google Kubernetes Engine (GKE). It handles:
- GCP provider configuration and authentication
- Kubernetes and Helm provider setup
- Helm chart deployment to GKE cluster
- Multi-environment support (dev, staging, production)

### Project Structure

```
terraform/
├── terraform.tf              # Provider config & version requirements
├── variables.tf              # Input variables with validation
├── outputs.tf                # Output values
├── locals.tf                 # Computed values
├── main.tf                   # Main resources
├── .gitignore               # Git ignore rules
├── environments/             # Environment-specific configs
│   ├── dev.tfvars           # Development
│   ├── staging.tfvars       # Staging
│   └── production.tfvars    # Production
└── modules/gke-deployment/  # Reusable module
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

---

## Prerequisites

### Required Software

```bash
# Terraform >= 1.0
terraform version

# gcloud CLI
gcloud --version

# kubectl
kubectl version --client

# Helm (optional, for chart management)
helm version
```

**Installation:**
```bash
# macOS
brew install terraform
brew install --cask google-cloud-sdk
brew install kubectl
brew install helm

# Windows
choco install terraform
choco install gcloudsdk
choco install kubernetes-cli
choco install helm

# Linux
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-get install terraform
# Install GCP SDK: https://cloud.google.com/sdk/docs/install
```

### GCP Account Access

- GCP project with billing enabled
- Service account with appropriate IAM roles
- GKE cluster already created
- Service account credentials JSON file
- kubectl configured for the GKE cluster

---

## Installation & Setup

### Step 1: Set Up GCP Service Account

```bash
# Set your project
export PROJECT_ID="clever-spirit-417020"
gcloud config set project $PROJECT_ID

# Create service account
gcloud iam service-accounts create terraform-sa \
  --display-name="Terraform Service Account"

# Grant required roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

### Step 2: Create Service Account Key

```bash
# Create JSON key
gcloud iam service-accounts keys create \
  clever-spirit-terraform-service-account.json \
  --iam-account=terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com

# Set restrictive permissions
chmod 600 clever-spirit-terraform-service-account.json

# Verify it's in .gitignore
grep "*.json" .gitignore
```

### Step 3: Set Up GCS Buckets for Terraform State

```bash
# Create GCS buckets for each environment
gsutil mb -p $PROJECT_ID gs://tf-state-dev-${PROJECT_ID}
gsutil mb -p $PROJECT_ID gs://tf-state-staging-${PROJECT_ID}
gsutil mb -p $PROJECT_ID gs://tf-state-prod-${PROJECT_ID}

# Enable versioning on all buckets (recommended for state recovery)
gsutil versioning set on gs://tf-state-dev-${PROJECT_ID}
gsutil versioning set on gs://tf-state-staging-${PROJECT_ID}
gsutil versioning set on gs://tf-state-prod-${PROJECT_ID}

# Enable encryption (optional, GCS default encryption is applied)
gsutil encryption set gs://tf-state-dev-${PROJECT_ID}
gsutil encryption set on gs://tf-state-staging-${PROJECT_ID}
gsutil encryption set on gs://tf-state-prod-${PROJECT_ID}

# Grant service account access to state buckets
SA_EMAIL="terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com"
gsutil iam ch serviceAccount:${SA_EMAIL}:objectAdmin gs://tf-state-dev-${PROJECT_ID}
gsutil iam ch serviceAccount:${SA_EMAIL}:objectAdmin gs://tf-state-staging-${PROJECT_ID}
gsutil iam ch serviceAccount:${SA_EMAIL}:objectAdmin gs://tf-state-prod-${PROJECT_ID}
```

### Step 4: Verify GKE Cluster

```bash
# List available clusters
gcloud container clusters list

# Get cluster details
gcloud container clusters describe gcp-info-website-prod \
  --region us-central1

# Configure kubectl
gcloud container clusters get-credentials gcp-info-website-prod \
  --region us-central1

# Verify cluster access
kubectl cluster-info
```

### Step 5: Set Credentials via Environment Variable

**Option A: Set Environment Variable (Recommended)**

PowerShell (Windows):
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\clever-spirit-terraform-service-account.json"
```

Bash (Unix/Linux/macOS):
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/clever-spirit-terraform-service-account.json"
```

**Option B: Pass via Command Line Variable**

```bash
terraform apply -var="credentials_file=/path/to/service-account.json" -var-file="environments/dev.tfvars"
```

Note: The environment variable approach is recommended as it follows GCP best practices and doesn't require passing credentials on the command line.

### Step 6: Navigate to Terraform Directory

```bash
cd /path/to/gcp-info-website
cd terraform
```

### Step 7: Initialize Terraform with GCS Backend

```bash
# For development environment
terraform init -backend-config=environments/backend-dev.tfvars

# For staging environment
terraform init -backend-config=environments/backend-staging.tfvars

# For production environment
terraform init -backend-config=environments/backend-production.tfvars

# Verify initialization
ls -la .terraform/

# Verify state is in GCS
gsutil ls gs://tf-state-dev-${PROJECT_ID}/gcp-info-website/terraform/
```

### Step 8: Validate Configuration

```bash
# Check syntax
terraform validate

# Check formatting
terraform fmt -check -recursive

# View formatted files (optional)
terraform fmt -recursive
```

---

## Environment Configuration

### Development Environment

```bash
# Deploy to development (with environment variable set)
# $env:GOOGLE_APPLICATION_CREDENTIALS should be set before running
terraform plan -var-file="environments/dev.tfvars" -out=tfplan-dev
terraform apply tfplan-dev

# Verify
terraform output
kubectl get pods -n development
helm list -n development
```

**Configuration (dev.tfvars):**
```hcl
project_id            = "clever-spirit-417020"
region                = "us-central1"
environment           = "dev"
cluster_name          = "gcp-info-website-dev"
kubernetes_namespace  = "development"
# credentials_file is optional - uses GOOGLE_APPLICATION_CREDENTIALS env var if not provided
# credentials_file = null  # Or omit this line entirely

helm_chart_path       = "../helm-dir"
helm_release_name     = "mainwebsite"
helm_timeout          = 300
helm_atomic_deployment = true

mainwebsite_image_tag = "dev-latest"
metrics_image_tag     = "dev-latest"

helm_set_values = {
  "mainwebsite.replicaCount" = "1"
  "metrics.replicaCount"     = "1"
}

common_labels = {
  environment = "dev"
  managed_by  = "terraform"
  project     = "gcp-info-website"
}
```

### Staging Environment

```bash
# Deploy to staging (mirrors production in structure)
terraform plan -var-file="environments/staging.tfvars" -out=tfplan-staging
terraform apply tfplan-staging
```

### Production Environment

```bash
# ⚠️ PRODUCTION REQUIRES EXTRA CARE

# 1. Review the plan carefully
terraform plan -var-file="environments/production.tfvars" \
  -out=tfplan-prod

# 2. Show detailed plan
terraform show tfplan-prod | less

# 3. Get approval from team

# 4. Apply only when ready
terraform apply tfplan-prod

# 5. Verify thoroughly
terraform output
kubectl get all -n production
helm status mainwebsite -n production
```

---

## Common Commands

### Planning & Validation

```bash
# Validate syntax
terraform validate

# Format check
terraform fmt -check -recursive

# Initialize (first time or after provider changes)
terraform init

# Plan changes (without applying)
terraform plan -var-file="environments/dev.tfvars" -out=tfplan

# Show plan details
terraform show tfplan

# Plan changes with targeting
terraform plan -var-file="environments/dev.tfvars" \
  -target="kubernetes_namespace.default" \
  -out=tfplan
```

### Deployment

```bash
# Set credentials via environment variable first (Recommended)
# PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\creds.json"
# Bash: export GOOGLE_APPLICATION_CREDENTIALS="/path/to/creds.json"

# Apply planned changes
terraform apply tfplan

# Apply with auto-approve (dev only)
terraform apply -auto-approve -var-file="environments/dev.tfvars"

# Apply to production (with review)
terraform apply -var-file="environments/production.tfvars"

# Apply with explicit credentials file (alternative to env var)
terraform apply -var="credentials_file=/path/to/creds.json" -var-file="environments/dev.tfvars"

# Destroy infrastructure (dev only)
terraform destroy -var-file="environments/dev.tfvars"

# Destroy specific resource
terraform destroy -target="kubernetes_namespace.default"
```

### State Management

```bash
# List all resources in current state
terraform state list

# Show resource details from GCS backend
terraform state show 'kubernetes_namespace.default'

# Remove from state (doesn't delete resource, only local tracking)
terraform state rm 'google_container_cluster.primary'

# Show all outputs
terraform output

# Get specific output
terraform output -raw gke_cluster_endpoint
terraform output -json | jq '.mainwebsite_namespace'

# Refresh state from GCS backend
terraform refresh

# Backup state from GCS (stored safely in GCS, but good practice)
terraform state pull > terraform.tfstate.backup

# Restore from backup (dangerous - use carefully, updates GCS backend)
terraform state push terraform.tfstate.backup

# Force unlock (if GCS backend lock is stuck)
terraform force-unlock <LOCK_ID>

# List GCS state files
gsutil ls gs://tf-state-dev-${PROJECT_ID}/gcp-info-website/terraform/
```

### Kubernetes Commands

```bash
# Get cluster info
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# Pod management
kubectl get pods -n production
kubectl describe pod <pod-name> -n production
kubectl logs <pod-name> -n production
kubectl logs <pod-name> -n production --previous  # Crashed pod
kubectl exec -it <pod-name> -n production -- /bin/bash

# Troubleshooting
kubectl get events -n production
kubectl describe node <node-name>
kubectl top pods -n production
kubectl top nodes

# Resource management
kubectl delete pod <pod-name> -n production --grace-period=0 --force
kubectl scale deployment <deployment-name> --replicas=3 -n production

# Port forwarding
kubectl port-forward -n production svc/mainwebsite 8080:80
```

### Helm Commands

```bash
# List releases
helm list -n production

# Get release values
helm get values mainwebsite -n production

# Show deployed manifest
helm get manifest mainwebsite -n production

# Check release status
helm status mainwebsite -n production

# View release history
helm history mainwebsite -n production

# Rollback to previous version
helm rollback mainwebsite -n production

# Dry-run deployment
helm install test ../helm-dir --dry-run --debug

# Validate chart
helm lint ../helm-dir/
```

### GCP Commands

```bash
# List clusters
gcloud container clusters list

# Get cluster details
gcloud container clusters describe CLUSTER_NAME --region REGION

# Configure kubectl
gcloud container clusters get-credentials CLUSTER_NAME --region REGION

# Check IAM permissions
gcloud projects get-iam-policy PROJECT_ID

# View logs
gcloud logging read --limit 50
gcloud logging read "resource.type=k8s_container" --limit 10

# Test authentication
gcloud auth application-default login
gcloud auth list
gcloud config list
```

---

## Deployment Workflows

### Quick Dev Deployment (5 minutes)

```bash
cd terraform

# Set credentials environment variable first
# PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\service-account.json"
# Bash: export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# Initialize with GCS backend
terraform init -backend-config=environments/backend-dev.tfvars

# Plan and apply
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
terraform output
```

### Production Deployment (with Review - 20 minutes)

```bash
# 1. Plan
terraform plan -var-file="environments/production.tfvars" -out=tfplan

# 2. Review
terraform show tfplan

# 3. Get approval from team

# 4. Apply
terraform apply tfplan

# 5. Verify
terraform output
kubectl get all -n production

# 6. Verify state is in GCS
gsutil ls gs://tf-state-prod-${PROJECT_ID}/gcp-info-website/terraform/
```

### Rollback

```bash
# Option 1: Revert tfvars and redeploy
git checkout environments/production.tfvars
terraform apply -var-file="environments/production.tfvars"

# Option 2: Helm rollback
helm rollback mainwebsite -n production

# Option 3: Restore from GCS versioned state
# First, list versions
gsutil ls -L gs://tf-state-prod-${PROJECT_ID}/gcp-info-website/terraform/default.tfstate
# Then restore specific version (if versioning is enabled)
gsutil cp gs://tf-state-prod-${PROJECT_ID}/gcp-info-website/terraform/default.tfstate#<GENERATION> restore.tfstate
```

### Scaling

```bash
# Scale replicas
terraform apply -var-file="environments/production.tfvars" \
  -var="helm_set_values={\"mainwebsite.replicaCount\" = \"5\"}"

# Or update tfvars file and redeploy
nano environments/production.tfvars
terraform apply -var-file="environments/production.tfvars"
```

---

## Troubleshooting

### Provider & Authentication Issues

#### Error: "Error: Error configuring the Google Cloud Provider"

**Symptoms:**
```
Error: Error configuring the Google Cloud Provider: credentials must be 
provided when using default application credentials
```

**Solutions:**
```bash
# Option 1: Set environment variable (RECOMMENDED)
# PowerShell: 
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\service-account.json"

# Bash:
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# Then run Terraform
terraform plan -var-file="environments/dev.tfvars"

# Option 2: Specify credentials in command line
terraform plan -var="credentials_file=./clever-spirit-terraform-service-account.json" -var-file="environments/dev.tfvars"

# Option 3: Use gcloud authentication (fallback)
gcloud auth application-default login

# Verify credentials are accessible
ls -la $env:GOOGLE_APPLICATION_CREDENTIALS  # PowerShell
ls -la $GOOGLE_APPLICATION_CREDENTIALS      # Bash
```

#### Error: "Error requesting list of clusters"

**Symptoms:**
```
Error: Error requesting list of clusters: googleapi: Error 403: 
Permission 'container.clusters.list' denied
```

**Solution:**
```bash
# Grant required roles to service account
PROJECT_ID="your-project-id"
SERVICE_ACCOUNT="terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/compute.admin"

# Verify roles are assigned
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:${SERVICE_ACCOUNT}"
```

### GCS Backend State Issues

#### Error: "Error reading state from backend"

**Cause:** GCS bucket doesn't exist or service account lacks permissions

**Solution:**
```bash
# Verify bucket exists
gsutil ls gs://tf-state-dev-${PROJECT_ID}/

# Create bucket if missing
gsutil mb -p $PROJECT_ID gs://tf-state-dev-${PROJECT_ID}

# Grant service account access
SERVICE_ACCOUNT="terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com"
gsutil iam ch serviceAccount:${SERVICE_ACCOUNT}:objectAdmin gs://tf-state-dev-${PROJECT_ID}

# Reinitialize backend
terraform init -backend-config=environments/backend-dev.tfvars
```

#### Error: "Error acquiring the state lock"

**Cause:** Another operation is using the state file or lock is stuck

**Solution:**
```bash
# Wait for other operations to complete
# If stuck, force unlock (use with caution):
terraform force-unlock <LOCK_ID>

# List locks in GCS (if configured):
gsutil ls -L gs://tf-state-dev-${PROJECT_ID}/.terraform.lock.json
```

#### Error: "Error: Error requesting list of clusters"

**Symptoms:**
```
Error: Error requesting list of clusters: googleapi: Error 403: 
Permission 'container.clusters.list' denied
```

**Solution:**
```bash
# Grant required roles
PROJECT_ID="your-project-id"
SERVICE_ACCOUNT="terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/container.admin"

# Verify
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:${SERVICE_ACCOUNT}"
```

#### Error: "Error: Invalid or unsupported attribute name"

**Cause:** Incorrect resource attribute

**Solution:**
```bash
# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Check provider documentation
terraform providers
# https://registry.terraform.io/providers/hashicorp/google/latest
```

### Kubernetes Connection Issues

#### Error: "Error: Unable to connect to Kubernetes cluster"

**Solution:**
```bash
# Configure kubeconfig
gcloud container clusters get-credentials gcp-info-website-prod \
  --region us-central1

# Test connectivity
kubectl cluster-info
kubectl get nodes
kubectl auth can-i create pods
```

#### Error: "Error: Unable to authenticate with Kubernetes"

**Solution:**
```bash
# Regenerate kubeconfig
gcloud container clusters get-credentials gcp-info-website-prod \
  --region us-central1 \
  --project clever-spirit-417020

# Verify context
kubectl config current-context
kubectl config get-contexts

# Test
kubectl get namespaces
```

### Helm & Chart Issues

#### Error: "Error: chart not found"

**Cause:** Incorrect chart path

**Solution:**
```bash
# Verify chart exists
ls -la ../helm-dir/Chart.yaml

# Validate chart
helm lint ../helm-dir/

# Update path in tfvars
echo 'helm_chart_path = "/full/path/to/helm-dir"' >> environments/dev.tfvars

# Test dry-run
helm install test /path/to/helm-dir/ --dry-run
```

#### Error: "ImagePullBackOff"

**Cause:** Image doesn't exist or registry auth failed

**Solution:**
```bash
# Verify image exists
docker pull gcr.io/project/image:tag

# Check image tag
terraform output -raw mainwebsite_image_tag

# Update tfvars
echo 'mainwebsite_image_tag = "v1.0.0"' >> environments/dev.tfvars

# Verify registry access
gcloud container images describe gcr.io/project/image:tag
```

#### Error: "CrashLoopBackOff"

**Cause:** Application error or configuration issue

**Solution:**
```bash
# Check pod logs
kubectl logs <pod-name> -n production -c <container>

# Previous crash logs
kubectl logs <pod-name> -n production --previous

# Describe pod for events
kubectl describe pod <pod-name> -n production

# Check environment variables
kubectl get pod <pod-name> -n production -o yaml | grep -A20 env:

# Check resource allocation
kubectl top pods -n production
```

### Terraform State Issues

#### Error: "Error acquiring the state lock"

**Solution:**
```bash
# List state locks
terraform force-unlock <LOCK_ID>

# Backup state
cp terraform.tfstate terraform.tfstate.backup

# Refresh state
terraform refresh

# Validate state
terraform validate
```

#### Error: "State has uncommitted resource changes"

**Solution:**
```bash
# Apply pending changes
terraform apply -auto-approve

# Or refresh
terraform refresh

# Or manually inspect
terraform state list
terraform state show <resource>
```

### Resource Issues

#### Error: "Insufficient memory"

**Solution:**
```bash
# Check node capacity
kubectl top nodes

# Increase resource requests
# Edit tfvars to increase memory:
echo 'helm_set_values = {"mainwebsite.resources.requests.memory" = "512Mi"}' >> environments/dev.tfvars

# Or scale cluster
gcloud container clusters resize gcp-info-website-prod --num-nodes 5
```

#### Error: "Insufficient CPU"

**Solution:**
```bash
# Check CPU allocation
kubectl top nodes

# Reduce CPU requests in tfvars
# Or add node pool
gcloud container node-pools create high-cpu \
  --cluster gcp-info-website-prod \
  --machine-type n1-standard-4
```

### Timeout Issues

#### Error: "Timeout while waiting for Helm release to be active"

**Cause:** Pods not starting, resource constraints, or long initialization

**Solution:**
```bash
# Check pod status
kubectl get pods -n production

# View pod events
kubectl get events -n production --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name> -n production
kubectl logs <pod-name> -n production --previous

# Increase timeout in tfvars
echo 'helm_timeout = 600' >> environments/production.tfvars

# Check node status
kubectl describe node
```

### Common Configuration Issues

| Issue | Solution |
|-------|----------|
| Credentials not found | Set GOOGLE_APPLICATION_CREDENTIALS env var or use -var flag |
| Permission denied | Add IAM roles to service account |
| Cluster not found | Verify cluster_name and region |
| Chart not found | Check helm_chart_path in tfvars |
| Pod not starting | Check logs: `kubectl logs <pod> -n namespace` |
| Helm timeout | Increase helm_timeout in tfvars |
| State locked | Use `terraform force-unlock <LOCK_ID>` |
| Invalid attribute | Run `terraform validate` and check spelling |
| GCS bucket not found | Create bucket with `gsutil mb` and reinit backend |

### Debugging Workflow

```bash
# 1. Enable debug logging
$env:TF_LOG = "DEBUG"  # PowerShell
# export TF_LOG=DEBUG   # Bash

# 2. Verify credentials are set
gcloud auth list
gcloud config list

# 3. Run failing command
terraform plan -var-file="environments/dev.tfvars"

# 4. Check Terraform state location
terraform state list

# 5. Check Kubernetes resources
kubectl get all -n production

# 6. Check Helm release
helm status mainwebsite -n production

# 7. Check logs
kubectl logs -n production -l app=mainwebsite

# 8. Disable debugging
$env:TF_LOG = ""  # PowerShell
# export TF_LOG=  # Bash
```

### Emergency Procedures

```bash
# Force delete stuck pod
kubectl delete pod <pod-name> -n production --grace-period=0 --force

# Force delete stuck deployment
kubectl delete deployment <deployment-name> -n production --cascade=orphan

# Terraform force unlock (releases GCS lock)
terraform force-unlock <LOCK_ID>

# Emergency destroy (dev/staging only)
terraform destroy -auto-approve -var-file="environments/dev.tfvars"

# Restore from GCS backup (if versioning enabled)
gsutil cp gs://tf-state-prod-${PROJECT_ID}/gcp-info-website/terraform/default.tfstate#<GENERATION> restore.tfstate
terraform state push restore.tfstate
```

---

## Quick Reference

### Environment Variables

```bash
# GCP
export PROJECT_ID="clever-spirit-417020"
export REGION="us-central1"

# Credentials (RECOMMENDED - set before Terraform)
# PowerShell:
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\service-account.json"

# Bash:
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# Terraform
$env:TF_LOG = "DEBUG"           # PowerShell - Enable debug logging
# export TF_LOG=DEBUG           # Bash
$env:TF_INPUT = "false"          # PowerShell - Don't prompt for input
# export TF_INPUT=false          # Bash
$env:TF_VAR_project_id = "..."   # PowerShell - Override variables
# export TF_VAR_project_id="..." # Bash

# Kubernetes
$env:KUBECONFIG = "$HOME\.kube\config"  # PowerShell
# export KUBECONFIG=~/.kube/config      # Bash
$env:KUBE_NAMESPACE = "production"       # PowerShell
# export KUBE_NAMESPACE=production       # Bash

# Helm
$env:HELM_TIMEOUT = "600"  # PowerShell
# export HELM_TIMEOUT=600   # Bash
```

### Configuration Reference

| Variable | Dev | Staging | Prod |
|----------|-----|---------|------|
| Image Tag | dev-latest | staging-latest | v1.0.0 |
| Replicas | 1 | 2 | 3 |
| Autoscaling | No | Yes | Yes |
| Timeout | 300s | 300s | 600s |
| Atomic | true | true | true |
| State Bucket | tf-state-dev-* | tf-state-staging-* | tf-state-prod-* |

### Key Outputs

```bash
# View all outputs
terraform output

# GKE cluster endpoint
terraform output -raw gke_cluster_endpoint

# Kubernetes namespace
terraform output -raw mainwebsite_namespace

# List state files in GCS
gsutil ls gs://tf-state-dev-${PROJECT_ID}/gcp-info-website/terraform/# Helm release status
terraform output -raw helm_release_status
```

### Security Checklist

✅ **DO:**
- Use version tags in production (v1.0.0, never latest)
- Mark sensitive variables
- Keep credentials in .gitignore
- Backup state regularly
- Use remote state (GCS) in production
- Review plans before apply
- Use service accounts
- Restrict IAM permissions

❌ **DON'T:**
- Commit credentials or state files
- Use "latest" in production
- Deploy without planning
- Force destroy in production
- Hardcode secrets
- Use personal credentials
- Skip validation
- Ignore warnings/errors

### Troubleshooting Checklist

- [ ] Verify authentication: `gcloud auth list`
- [ ] Check cluster access: `kubectl cluster-info`
- [ ] Verify credentials file: `ls -la credentials.json`
- [ ] Validate Terraform: `terraform validate`
- [ ] Review plan before apply: `terraform show tfplan`
- [ ] Check pod status: `kubectl get pods -n production`
- [ ] View pod logs: `kubectl logs <pod> -n production`
- [ ] Check Helm release: `helm status mainwebsite -n production`
- [ ] Check resource allocation: `kubectl top pods -n production`

---

## Remote State Setup (Recommended for Teams)

### Create GCS Bucket for State

```bash
# Create bucket
gsutil mb gs://${PROJECT_ID}-terraform-state

# Enable versioning
gsutil versioning set on gs://${PROJECT_ID}-terraform-state

# Set lifecycle policy (keep last 5 versions)
gsutil lifecycle set - <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {"numNewerVersions": 5}
      }
    ]
  }
}
EOF

# Restrict access
gsutil acl ch -u terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  gs://${PROJECT_ID}-terraform-state
```

### Enable Backend

```hcl
# In terraform.tf, uncomment:
backend "gcs" {
  bucket  = "your-project-id-terraform-state"
  prefix  = "gcp-info-website"
}
```

### Migrate State

```bash
# Terraform will prompt to migrate
terraform init

# Confirm migration
# Local state backed up to terraform.tfstate.backup
```

---

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [GCP Provider Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Kubernetes Provider Docs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Helm Provider Docs](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Helm Documentation](https://helm.sh/docs/)

---

**Last Updated**: January 2, 2026  
**Status**: Production-Ready
