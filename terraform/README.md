# Terraform Project - GCP Website Infrastructure

## 📋 Overview

This Terraform project manages the deployment of the GCP Info Website application on Google Kubernetes Engine (GKE). It handles:
- GCP provider configuration and authentication
- Kubernetes and Helm provider setup
- Helm chart deployment to GKE cluster
- Multi-environment support (dev, staging, production)

## 🏗️ Project Structure

```
terraform/
├── terraform.tf              # Terraform version & provider requirements
├── main.tf                   # Main resources and provider configuration
├── variables.tf              # Input variables with validation
├── outputs.tf                # Output values
├── locals.tf                 # Local computed values
├── .gitignore               # Git ignore rules
│
├── environments/             # Environment-specific variables
│   ├── dev.tfvars           # Development environment
│   ├── staging.tfvars       # Staging environment
│   └── production.tfvars    # Production environment
│
├── modules/                  # Reusable Terraform modules
│   └── gke-deployment/      # GKE deployment module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── docs/                     # Documentation
    ├── README.md            # This file
    ├── SETUP.md             # Setup instructions
    ├── BEST_PRACTICES.md    # Best practices guide
    └── TROUBLESHOOTING.md   # Troubleshooting guide
```

## 🚀 Quick Start

### Prerequisites
- Terraform >= 1.0
- GCP account with appropriate permissions
- GKE cluster already created
- Service account credentials JSON file
- kubectl configured for the GKE cluster

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Plan Deployment

```bash
# Development
terraform plan -var-file="environments/dev.tfvars" -out=tfplan

# Staging
terraform plan -var-file="environments/staging.tfvars" -out=tfplan

# Production
terraform plan -var-file="environments/production.tfvars" -out=tfplan
```

### 3. Apply Configuration

```bash
# Apply the plan (use with caution in production)
terraform apply tfplan

# Or directly apply
terraform apply -var-file="environments/production.tfvars"
```

### 4. Verify Deployment

```bash
# Get deployment information
terraform output

# Check Helm release
helm list -n <namespace>

# Check pods
kubectl get pods -n <namespace>
```

## 📝 Configuration Files

### terraform.tf
- **Purpose**: Terraform version and provider requirements
- **Contains**:
  - Required Terraform version (>= 1.0)
  - Provider version constraints
  - Provider configurations
  - Default labels

### variables.tf
- **Purpose**: Input variable definitions
- **Contains**:
  - GCP configuration (project_id, region, credentials)
  - Kubernetes configuration (cluster_name, namespace)
  - Helm configuration (chart path, release name, timeout)
  - Image tags for mainwebsite and metrics services
  - Validation rules for all inputs

### outputs.tf
- **Purpose**: Output values for reference
- **Contains**:
  - GCP and cluster information
  - Helm release details
  - Environment information
  - Helpful kubectl/helm commands

### locals.tf
- **Purpose**: Local computed values
- **Contains**:
  - Resource naming conventions
  - Environment-specific configurations
  - Common labels
  - Helm file paths
  - Deployment metadata

### environments/*.tfvars
- **Purpose**: Environment-specific variable values
- **Files**:
  - `dev.tfvars` - Development configuration
  - `staging.tfvars` - Staging configuration
  - `production.tfvars` - Production configuration

## 🔧 Variables

### Required Variables
- `project_id` - GCP project ID
- `region` - GCP region
- `credentials_file` - Path to service account JSON
- `cluster_name` - GKE cluster name
- `environment` - Environment type (dev, staging, production)

### Optional Variables with Defaults
- `kubernetes_namespace` (default: "default")
- `helm_chart_path` (default: "../helm-dir")
- `helm_release_name` (default: "mainwebsite")
- `helm_timeout` (default: 300 seconds)
- `helm_atomic_deployment` (default: true)
- `mainwebsite_image_tag` (default: "latest")
- `metrics_image_tag` (default: "latest")

### Variable Validation
All variables include validation rules:
- Format validation (regex patterns)
- Type checking
- Range validation for numeric values
- File existence checks

## 📊 Environment Differences

| Aspect | Dev | Staging | Production |
|--------|-----|---------|------------|
| Namespace | development | staging | production |
| Cluster | gcp-info-website-dev | gcp-info-website-staging | gcp-info-website-prod |
| Mainwebsite Replicas | 1 | 2 | 3 |
| Metrics Replicas | 1 | 1 | 2 |
| Autoscaling | Disabled | Enabled (max 4) | Enabled (max 10) |
| Image Tags | dev-latest | staging-latest | 1.0.0 (explicit) |
| Monitoring | Disabled | Enabled | Enabled |

## 🔐 Security Best Practices

### Credentials Management
1. ✅ Store credentials in `.gitignore`
2. ✅ Use service account JSON for GCP auth
3. ✅ Mark credentials_file as `sensitive = true`
4. ✅ Never commit credentials to version control

### State Management
1. ✅ Use remote state (GCS backend recommended)
2. ✅ Enable state encryption
3. ✅ Restrict state file access via IAM
4. ✅ Enable state locking for team environments

### Environment Isolation
1. ✅ Separate tfvars files per environment
2. ✅ Different GKE clusters per environment
3. ✅ Different namespaces per environment
4. ✅ Distinct IAM roles per environment

## 📋 Common Commands

### Plan Changes
```bash
terraform plan -var-file="environments/dev.tfvars"
terraform plan -var-file="environments/staging.tfvars" -out=tfplan
terraform plan -var-file="environments/production.tfvars"
```

### Apply Changes
```bash
terraform apply -var-file="environments/dev.tfvars"
terraform apply tfplan  # Apply saved plan
```

### View State
```bash
terraform state list
terraform state show helm_release.mainwebsite
terraform show
```

### Destroy Resources
```bash
# Development (safe to test)
terraform destroy -var-file="environments/dev.tfvars"

# Production (requires extra confirmation)
terraform destroy -var-file="environments/production.tfvars"
```

### Format & Validate
```bash
# Format HCL files
terraform fmt -recursive

# Validate configuration
terraform validate

# Validate with TFLint
tflint --init
tflint
```

## 🧪 Testing

### Validate Syntax
```bash
terraform validate
```

### Check Formatting
```bash
terraform fmt -check -recursive
```

### Lint with TFLint
```bash
tflint --init
tflint --format compact
```

### Dry Run (Plan)
```bash
terraform plan -var-file="environments/staging.tfvars" -out=tfplan.json
terraform show -json tfplan.json | jq
```

## 🐛 Troubleshooting

### Common Issues

**Issue**: "Error: error reading the TLS CA Certificate"
```bash
# Solution: Verify cluster is accessible
gcloud container clusters get-credentials <cluster-name> --region <region>
kubectl cluster-info
```

**Issue**: "Error: resource type kubernetes_namespace not available"
```bash
# Solution: Ensure kubernetes provider is properly configured
terraform init -upgrade
```

**Issue**: "Error: helm_release error while running install action"
```bash
# Solution: Check Helm chart path and values
helm lint ../helm-dir/
helm template mainwebsite ../helm-dir/
```

### Debugging
```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform apply -var-file="environments/dev.tfvars"
unset TF_LOG

# Check provider logs
terraform providers
terraform version
```

## 📚 Additional Resources

### Documentation
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Terraform Helm Provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)

### Best Practices
- See [BEST_PRACTICES.md](BEST_PRACTICES.md)
- See [SETUP.md](SETUP.md)

### Troubleshooting
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 🤝 Contributing

When modifying this Terraform project:
1. Format code: `terraform fmt -recursive`
2. Validate syntax: `terraform validate`
3. Run linting: `tflint`
4. Test in dev first: `terraform plan -var-file="environments/dev.tfvars"`
5. Create descriptive commit messages

## 📞 Support

For issues or questions:
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review [BEST_PRACTICES.md](BEST_PRACTICES.md)
3. Check provider documentation
4. Review Terraform logs with `TF_LOG=DEBUG`

---

**Version**: 1.0  
**Last Updated**: January 2, 2026  
**Maintainer**: Platform Team
