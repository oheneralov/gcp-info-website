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
- Helm >= 3.0 installed
- gcloud CLI installed and configured

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

## 🔧 Terraform Setup Guide

### Prerequisites Installation

#### Install Terraform
```bash
# macOS (using Homebrew)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Windows (using Chocolatey)
choco install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

#### Install Required Tools
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install gcloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### GCP Setup

#### 1. Create GCP Service Account
```bash
# Set project ID
export PROJECT_ID="your-gcp-project-id"
gcloud config set project $PROJECT_ID

# Create service account
gcloud iam service-accounts create terraform-sa \
  --display-name="Terraform Service Account"

# Grant necessary roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/container.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/compute.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountUser
```

#### 2. Generate and Store Credentials
```bash
# Create key file
gcloud iam service-accounts keys create terraform-key.json \
  --iam-account=terraform-sa@$PROJECT_ID.iam.gserviceaccount.com

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terraform-key.json"

# Store securely (never commit to version control)
echo "terraform-key.json" >> .gitignore
```

#### 3. Configure GCP Access
```bash
# Authenticate gcloud
gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
gcloud config set project $PROJECT_ID

# Verify access
gcloud container clusters list
```

### Initial Setup Steps

#### 1. Clone Repository and Navigate
```bash
git clone <repository-url>
cd gcp-info-website/terraform
```

#### 2. Setup Environment Variables
Create a local environment configuration file:
```bash
# Create .env file (not committed to git)
cat > .env << EOF
export TF_VAR_project_id="your-project-id"
export TF_VAR_region="us-central1"
export TF_VAR_credentials_file="$(pwd)/terraform-key.json"
export TF_VAR_cluster_name="gcp-info-website-dev"
export TF_VAR_environment="dev"
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terraform-key.json"
EOF

# Source the environment
source .env
```

#### 3. Update Environment Variables
```bash
# Edit environment-specific tfvars files
# Development
vi environments/dev.tfvars

# Staging
vi environments/staging.tfvars

# Production
vi environments/production.tfvars
```

#### 4. Initialize Terraform Backend
```bash
# Initialize with local state (for testing)
terraform init

# Or with remote GCS backend (for production)
# First create GCS bucket
gsutil mb gs://$PROJECT_ID-terraform-state

# Then update backend configuration in terraform.tf and init
terraform init -backend-config="bucket=$PROJECT_ID-terraform-state"
```

#### 5. Validate Configuration
```bash
terraform validate
terraform fmt -recursive
tflint
```

#### 6. Plan and Apply
```bash
# Development
terraform plan -var-file="environments/dev.tfvars" -out=tfplan
terraform apply tfplan

# Check deployment
terraform output
kubectl get pods -n development
```

### Post-Setup Verification

```bash
# Verify Helm release
helm list -n development

# Check service endpoints
kubectl get svc -n development

# View deployment logs
kubectl logs -n development -l app=mainwebsite

# Test connectivity
kubectl port-forward -n development svc/mainwebsite 8080:3000
curl http://localhost:8080
```

## 🤖 Jenkins Integration Setup

### Jenkins Prerequisites

#### Required Jenkins Plugins
Install these plugins in Jenkins:
- Pipeline (Declarative Pipeline)
- GitHub or GitLab (depending on your VCS)
- Google Kubernetes Engine (GKE)
- Docker Pipeline
- Terraform Plugin (or similar)
- Credentials Binding Plugin
- Google Cloud Storage Plugin
- Slack Notification Plugin (optional)

#### Jenkins System Configuration

1. **Manage Jenkins → Manage Credentials**
   - Add GCP Service Account JSON credentials
   - Credential ID: `gcp-service-account`
   - Select JSON file from `terraform-key.json`

2. **Manage Jenkins → Configure System**
   - Google Kubernetes Engine
   - Configure GCP project and credentials
   - Configure Kubernetes clusters

3. **Manage Jenkins → Configure Global Security**
   - Enable CSRF protection
   - Configure authentication method (LDAP, GitHub OAuth, etc.)

### Jenkins Pipeline Configuration

#### 1. Create Build Pipeline Job

Create a Jenkins pipeline job that uses `Jenkinsfile.build`:

```groovy
// Example pipeline configuration
pipeline {
    agent any
    
    triggers {
        githubPush()  // Trigger on GitHub push
    }
    
    environment {
        GCP_PROJECT_ID = credentials('gcp-project-id')
        GCP_REGION = 'us-central1'
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-service-account')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Validate Terraform') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform init
                        terraform validate
                        terraform fmt -check -recursive
                    '''
                }
            }
        }
        
        // ... additional stages
    }
}
```

#### 2. Create Deploy Pipeline Job

Create a Jenkins pipeline job that uses `Jenkinsfile.deploy`:

**Job Configuration:**
- Select: Pipeline job
- Pipeline: Pipeline script from SCM
- SCM: Git
- Repository URL: Your Git repository
- Script Path: `Jenkinsfile.deploy`
- Parameters:
  - `DEPLOYMENT_ENV`: staging or production
  - `IMAGE_TAG`: Docker image tag

#### 3. Configure Credentials in Jenkins

Navigate to **Manage Jenkins → Manage Credentials → System → Global credentials**

Add the following credentials:

1. **GCP Project ID**
   - Type: Secret text
   - ID: `gcp-project-id`
   - Secret: Your GCP project ID

2. **GKE Cluster Name**
   - Type: Secret text
   - ID: `gke-cluster-name`
   - Secret: Your GKE cluster name

3. **GKE Zone**
   - Type: Secret text
   - ID: `gke-zone`
   - Secret: Your GKE zone (e.g., `us-central1-a`)

4. **GCP Docker Registry URL**
   - Type: Secret text
   - ID: `gcp-docker-registry-url`
   - Secret: `gcr.io`

5. **GCP Service Account JSON**
   - Type: Secret file
   - ID: `gcp-service-account`
   - File: Upload `terraform-key.json`

### Jenkins Job Setup Steps

#### 1. Build Pipeline Job

```bash
# Job name: gcp-info-website-build
# Type: Pipeline
# Trigger: GitHub Push (webhook)

# Pipeline configuration:
# - Pipeline script from SCM
# - Git repository: <your-repo-url>
# - Script path: Jenkinsfile.build
```

**Build Job Stages:**
- Checkout
- Setup GCP Authentication
- Install Dependencies
- Lint Code
- Build Docker Images
- Push Images to GCR
- Run Tests
- Generate Reports

#### 2. Deploy Pipeline Job

```bash
# Job name: gcp-info-website-deploy
# Type: Parameterized Pipeline
# Trigger: Manual or after build success

# Parameters:
# - DEPLOYMENT_ENV (choice: staging, production)
# - IMAGE_TAG (string: default latest)
```

**Deploy Job Stages:**
- Checkout
- Setup GCP Authentication
- Verify Docker Images
- Configure kubectl
- Update Helm Values
- Deploy with Helm
- Verify Deployment
- Run Smoke Tests
- Notify Slack

#### 3. Validate Terraform Pipeline Job

```bash
# Job name: gcp-info-website-validate-terraform
# Type: Pipeline
# Trigger: Pull Request

# Pipeline stages:
# - Terraform Init
# - Terraform Validate
# - Terraform Format Check
# - TFLint
# - Security Scan (Optional)
```

### GitHub Webhook Setup (for automated builds)

1. Go to your GitHub repository
2. Settings → Webhooks → Add webhook
3. Payload URL: `http://<jenkins-url>/github-webhook/`
4. Content type: `application/json`
5. Events: Select "Push events"
6. Active: ✓ Check

### Jenkins Environment Configuration

#### Set Up Jenkins Build Node

```bash
# On Jenkins agent/node
# Install required tools
sudo apt-get update
sudo apt-get install -y \
    docker.io \
    terraform \
    kubectl \
    helm \
    git \
    npm \
    python3 \
    jq

# Configure Docker
sudo usermod -aG docker jenkins

# Setup gcloud
curl https://sdk.cloud.google.com | bash
```

#### Configure Jenkins Node Credentials

1. **Manage Jenkins → Manage Nodes**
2. **Agent node → Configure**
3. Add environment variables:
   ```
   DOCKER_HOST=unix:///var/run/docker.sock
   GCP_REGION=us-central1
   KUBECONFIG=/var/lib/jenkins/.kube/config
   ```

### Monitoring and Notifications

#### Slack Notifications

1. Install Slack plugin
2. **Manage Jenkins → Configure System → Slack**
3. Add Slack workspace URL and token
4. In pipeline, add notification stage:

```groovy
post {
    success {
        slackSend(
            color: 'good',
            message: "Deployment Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        )
    }
    failure {
        slackSend(
            color: 'danger',
            message: "Deployment Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        )
    }
}
```

#### Email Notifications

1. **Manage Jenkins → Configure System → E-mail Notification**
2. Configure SMTP server details
3. In pipeline:

```groovy
post {
    always {
        emailext(
            to: 'team@example.com',
            subject: "Build ${env.BUILD_NUMBER}: ${currentBuild.result}",
            body: "Check console output at ${env.BUILD_URL}"
        )
    }
}
```

### CI/CD Workflow

```
GitHub Push
    ↓
Jenkins Build Trigger (Jenkinsfile.build)
    ├─ Checkout code
    ├─ Run tests
    ├─ Build Docker images
    └─ Push to GCR
    ↓
Manual Deployment Trigger (Jenkinsfile.deploy)
    ├─ Staging environment
    ├─ Run smoke tests
    ├─ Approve for production
    └─ Deploy to production
    ↓
Verify Deployment
    ├─ Health checks
    ├─ Helm verification
    └─ Slack notification
```

### Troubleshooting Jenkins Integration

**Issue**: Permission Denied when pulling images
```groovy
// Solution: Configure Docker authentication in Jenkins
withCredentials([file(credentialsId: 'gcp-service-account', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
    sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'
    sh 'gcloud auth configure-docker gcr.io'
}
```

**Issue**: Terraform state lock conflicts
```bash
# Solution: Clear stuck locks
terraform force-unlock <LOCK_ID>

# Or use backend configuration for state locking
terraform init -backend-config="skip_bucket_creation=true"
```

**Issue**: GKE authentication failures
```bash
# Solution: Update kubeconfig
gcloud container clusters get-credentials <cluster-name> --zone <zone> --project <project-id>
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
