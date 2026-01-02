# GCP Info Website

A cloud-native, production-grade application deployment on Google Kubernetes Engine (GKE) with automated CI/CD pipelines, infrastructure-as-code management, and multi-environment support.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Quick Start](#quick-start)
- [CI/CD Pipeline - Jenkins](#cicd-pipeline---jenkins)
- [Infrastructure as Code - Terraform](#infrastructure-as-code---terraform)
- [Kubernetes & Helm Deployment](#kubernetes--helm-deployment)
- [Docker & Container Management](#docker--container-management)
- [Ingress & Routing](#ingress--routing)
- [Monitoring & Debugging](#monitoring--debugging)
- [GCP Configuration](#gcp-configuration)
- [Utilities & Troubleshooting](#utilities--troubleshooting)



---

## 📚 Project Overview

This repository contains:
- **mainwebsite**: Primary NestJS web application
- **metrics**: Metrics aggregation service
- **Helm Charts**: Kubernetes deployment manifests with multi-environment support (dev, staging, production)
- **Terraform**: Infrastructure-as-code for GKE cluster and GCP resources
- **Jenkins Pipelines**: Automated CI/CD workflows

### Architecture
- **Container Registry**: Google Container Registry (GCR)
- **Orchestration**: Kubernetes on Google Kubernetes Engine (GKE)
- **Ingress Controller**: Traefik for advanced routing
- **Monitoring**: Prometheus integration via ServiceMonitor
- **Database**: Google Cloud SQL

---

## 🚀 Quick Start

### Prerequisites
- Docker & Docker CLI
- Kubernetes 1.19+
- Helm 3.0+
- Terraform >= 1.0
- gcloud CLI configured with appropriate GCP credentials
- kubectl configured to access GKE cluster
- Jenkins (for CI/CD automation)

### Minimal Setup
```bash
# 1. Clone the repository
git clone <repository-url>
cd gcp-info-website

# 2. Initialize Terraform (for infrastructure)
cd terraform
terraform init
terraform plan -var-file="environments/dev.tfvars"

# 3. Deploy with Helm
cd ../helm-dir
helm install mainwebsite . -f values-dev.yaml

# 4. Verify deployment
kubectl get pods
kubectl get svc
```

---

## 🔄 CI/CD Pipeline - Jenkins

The project includes three specialized Jenkins pipelines for different stages of the deployment process. All pipelines are triggered automatically based on Git events or can be run manually.

### Pipeline Files Overview

| File | Purpose | Trigger | Environment |
|------|---------|---------|-------------|
| `Jenkinsfile.validate` | Code validation, linting, unit tests | Every commit | Dev |
| `Jenkinsfile.build` | Build Docker images, run tests, push to registry | Manual or after validation | Dev/Staging |
| `Jenkinsfile.deploy` | Deploy to GKE using Helm, update production | Manual with environment selection | Staging/Production |

### Jenkinsfile.validate - Code Quality & Testing

**Purpose**: Automatically validates code quality, runs lints, and executes unit tests on every commit.

**Stages**:
1. **Checkout**: Clones the repository
2. **Install Dependencies**: Installs npm packages for mainwebsite and metrics services
3. **Lint**: Runs ESLint on both services
4. **Unit Tests**: Executes Jest tests for mainwebsite and metrics
5. **Build Test**: Builds NestJS application without deployment

**Usage**:
```bash
# Automatically triggered on every git push
# Or manually run from Jenkins UI:
# Navigate to: Jenkins Dashboard > Jenkinsfile.validate > Build Now
```

**Configuration Requirements**:
- Jenkins must have Node.js installed (npm)
- Service account credentials configured (optional for linting)

### Jenkinsfile.build - Docker Image Building & Registry Push

**Purpose**: Builds Docker images for both services, pushes them to Google Container Registry (GCR), and stores build artifacts.

**Stages**:
1. **Checkout**: Clones repository
2. **Setup GCP Authentication**: Authenticates with GCP using service account credentials
3. **Install Dependencies**: npm install for mainwebsite and metrics
4. **Lint**: Code quality checks
5. **Build Images**: 
   - Builds mainwebsite Docker image
   - Builds metrics Docker image
6. **Push to GCR**: 
   - Pushes both images to `gcr.io/[GCP_PROJECT_ID]/[service-name]:[BUILD_NUMBER]-[GIT_COMMIT]`
7. **Archive Artifacts**: Stores build metadata for deployment pipeline

**Environment Variables**:
```groovy
GCP_PROJECT_ID = credentials('gcp-project-id')
GKE_CLUSTER_NAME = credentials('gke-cluster-name')
GKE_ZONE = credentials('gke-zone')
DOCKER_REGISTRY = 'gcr.io'
IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(8)}"
```

**Usage**:
```bash
# Manual trigger from Jenkins:
# Jenkins Dashboard > Jenkinsfile.build > Build Now

# Or integrate with GitHub webhooks:
# Settings > Webhooks > Add Webhook
# Payload URL: https://your-jenkins.com/github-webhook/
# Content Type: application/json
# Trigger events: Push events
```

**Required Credentials in Jenkins**:
- `gcp-project-id` - GCP project ID
- `gke-cluster-name` - GKE cluster name
- `gke-zone` - GKE cluster zone
- `GOOGLE_APPLICATION_CREDENTIALS` - Service account JSON key file

**Output**:
- Docker images stored in GCR with tags like `mainwebsite:123-a1b2c3d4`
- Build artifacts available for the deploy pipeline

### Jenkinsfile.deploy - Kubernetes Deployment via Helm

**Purpose**: Deploys applications to GKE cluster using Helm charts with environment-specific configurations.

**Parameters**:
- `DEPLOYMENT_ENV`: Choose between `staging` or `production`
- `IMAGE_TAG`: Docker image tag to deploy (e.g., `123-a1b2c3d4`, `latest`)

**Stages**:
1. **Checkout**: Clones repository
2. **Setup GCP Authentication**: Configures kubectl access to GKE cluster
3. **Verify Images**: Confirms Docker images exist in GCR
4. **Update Helm Values**: Updates image tags in values files
5. **Helm Upgrade/Install**: 
   - Deploys or upgrades Helm release
   - Applies environment-specific values (dev/staging/production)
6. **Verify Deployment**: 
   - Checks pod status
   - Waits for deployment rollout (max 5 minutes)
7. **Run Health Checks**: Verifies service endpoints are responding
8. **Cleanup**: Removes old pods and unused resources

**Usage**:
```bash
# Manual deployment from Jenkins:
# 1. Navigate to Jenkins Dashboard > Jenkinsfile.deploy
# 2. Click "Build with Parameters"
# 3. Select environment: staging or production
# 4. Enter IMAGE_TAG (e.g., 123-a1b2c3d4)
# 5. Click Build

# Expected output:
# Helm release "gcp-info-staging" deployed to namespace "staging"
# All pods running and healthy
```

**Environment-Specific Deployment**:
```bash
# Staging deployment (from CLI - if Jenkins authenticated):
# Uses values-staging.yaml with 2-3 replicas, staging image tags

# Production deployment:
# Uses values-prod.yaml with 3+ replicas, full monitoring, pod disruption budgets
```

**Rollback After Deployment**:
```bash
# If deployment fails, Jenkins provides automatic rollback option
# Or manually rollback:
helm rollback gcp-info-staging 1
kubectl rollout undo deployment/mainwebsite -n staging
```

### Jenkins Pipeline Orchestration

**Recommended Workflow**:
```
Git Commit (main branch)
       ↓
[Jenkinsfile.validate] - Automatic validation
       ↓ (if passed)
[Jenkinsfile.build] - Manual trigger or webhook
       ↓
Docker images pushed to GCR
       ↓ (operator initiates)
[Jenkinsfile.deploy] - Manual with parameters
       ↓
Production environment updated
```

### Setting Up Jenkins for This Project

**1. Install Required Plugins**:
- Blue Ocean
- GitHub Integration
- Docker Pipeline
- Google Kubernetes Engine Plugin
- Kubernetes CLI Plugin
- Helm Plugin

**2. Create Jenkins Credentials**:
```bash
# Store in Jenkins Credentials Store:
- gcp-project-id (Secret text)
- gke-cluster-name (Secret text)
- gke-zone (Secret text)
- google-credentials (File) - Service account JSON key
```

**3. Configure Multibranch Pipeline** (Optional):
```groovy
// Jenkinsfile.validate, .build, .deploy in root directory
// Jenkins auto-discovers and runs based on branch
```

**4. GitHub Webhook Setup**:
```
Repository Settings > Webhooks > Add webhook
Payload URL: https://your-jenkins.com/github-webhook/
Events: Push events, Pull requests
```

---

## 🏗️ Infrastructure as Code - Terraform

Terraform manages the complete GCP infrastructure, from GKE cluster provisioning to Helm chart deployments. This enables reproducible, version-controlled infrastructure across all environments.

### Directory Structure

```
terraform/
├── terraform.tf              # Provider & version requirements
├── main.tf                   # Main resources and provider config
├── variables.tf              # Input variable definitions
├── outputs.tf                # Output values
├── locals.tf                 # Local computed values
├── backend.tf                # Remote state configuration
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
└── docs/
    ├── SETUP.md             # Detailed setup guide
    ├── DEPLOYMENT_GUIDE.md  # Deployment procedures
    ├── TROUBLESHOOTING.md   # Common issues & solutions
    └── INDEX.md             # Documentation index
```

### Prerequisites

**Required Tools**:
```bash
# Check versions
terraform --version        # Terraform >= 1.0
gcloud --version          # Google Cloud CLI
kubectl version --client  # Kubernetes >= 1.19
helm version              # Helm >= 3.0
```

**GCP Setup**:
```bash
# 1. Create GCP project
gcloud projects create gcp-info-website --name="GCP Info Website"

# 2. Set as active project
gcloud config set project gcp-info-website

# 3. Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com

# 4. Create service account for Terraform
gcloud iam service-accounts create terraform-sa \
  --display-name="Terraform Service Account"

# 5. Grant permissions
gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
  --member="serviceAccount:terraform-sa@$(gcloud config get-value project).iam.gserviceaccount.com" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
  --member="serviceAccount:terraform-sa@$(gcloud config get-value project).iam.gserviceaccount.com" \
  --role="roles/compute.admin"
```

### Quick Start Guide

**1. Initialize Terraform**:
```bash
cd terraform
terraform init

# Terraform downloads providers and prepares the environment
# Output should show "Terraform has been successfully configured"
```

**2. Plan Infrastructure Changes (Development)**:
```bash
terraform plan -var-file="environments/dev.tfvars"

# Review the output - shows all resources that will be created
# Example output:
# Plan: 15 to add, 0 to change, 0 to destroy.
```

**3. Apply Configuration (Development)**:
```bash
terraform apply -var-file="environments/dev.tfvars"

# Review the plan and type 'yes' to confirm
# Terraform creates all resources on GCP
# Takes 10-15 minutes for GKE cluster provisioning
```

**4. Configure kubectl**:
```bash
# After terraform apply, get GKE cluster credentials
gcloud container clusters get-credentials $(terraform output -raw cluster_name) \
  --zone $(terraform output -raw region)

# Verify connection
kubectl cluster-info
kubectl get nodes
```

**5. Deploy Applications with Helm**:
```bash
# Terraform automatically installs Helm chart, but you can also:
helm list
helm status gcp-info-dev
```

### Environment-Specific Deployments

**Development Environment**:
```bash
terraform apply -var-file="environments/dev.tfvars"

# Results in:
# - Single-node GKE cluster (cost-optimized)
# - Development image tags (dev-latest)
# - Single pod replicas
# - Reduced monitoring overhead
```

**Staging Environment**:
```bash
terraform apply -var-file="environments/staging.tfvars"

# Results in:
# - 2-3 node GKE cluster
# - Staging image tags (staging-latest)
# - 2-3 replicas per service
# - Full monitoring enabled
# - Pod disruption budgets configured
```

**Production Environment**:
```bash
terraform apply -var-file="environments/production.tfvars"

# Results in:
# - 3+ node GKE cluster with autoscaling
# - Production image tags (explicit version, e.g., 1.0.0)
# - 3+ replicas with autoscaling up to 10
# - Full monitoring, security policies
# - Pod anti-affinity for high availability
# - Maximum resource constraints
```

### Terraform Workflow for Multiple Environments

**Deployment Strategy**:
```bash
# 1. Deploy to development
cd terraform
terraform init
terraform apply -var-file="environments/dev.tfvars"

# 2. Validate in staging
terraform apply -var-file="environments/staging.tfvars"

# 3. Deploy to production (after validation)
terraform apply -var-file="environments/production.tfvars"
```

### Managing Terraform State

**State File Location**:
- Local state: `terraform.tfstate` (default, not recommended for production)
- Remote state: Configured in `backend.tf` to use Google Cloud Storage bucket

**Remote State Setup**:
```bash
# Create GCS bucket for remote state
gsutil mb gs://gcp-info-terraform-state

# Configure Terraform to use remote state
# Edit terraform/backend.tf:
# backend "gcs" {
#   bucket = "gcp-info-terraform-state"
#   prefix = "terraform/state"
# }

# Initialize with remote backend
terraform init
```

**State Management**:
```bash
# View current state
terraform state list

# Show specific resource state
terraform state show 'google_container_cluster.primary'

# Remove resource from state (without destroying)
terraform state rm 'google_container_cluster.primary'

# Import existing GCP resources
terraform import google_container_cluster.primary us-central1-a/my-cluster
```

### Common Terraform Operations

**View Output Values**:
```bash
terraform output
# or specific output
terraform output cluster_name
```

**Update Infrastructure**:
```bash
# Modify variables in environments/dev.tfvars
# Then apply changes
terraform apply -var-file="environments/dev.tfvars"
```

**Scale GKE Cluster**:
```bash
# Edit environments/dev.tfvars:
# Change: node_count = 2 (from 1)

terraform apply -var-file="environments/dev.tfvars"
```

**Destroy Infrastructure** (Development only):
```bash
terraform destroy -var-file="environments/dev.tfvars"

# Confirm with 'yes'
# WARNING: This will delete all resources including persistent data
```

**Lock Resources** (Prevent accidental changes):
```bash
# Create a .terraform.lock.hcl file (checked into version control)
# This locks provider versions and prevents conflicts
```

### Terraform Troubleshooting

**Common Issues**:
```bash
# 1. Authentication errors
# Solution: Ensure GOOGLE_APPLICATION_CREDENTIALS is set
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json

# 2. Quota exceeded
# Solution: Check GCP quotas and request increases
gcloud compute project-info describe --project=$(gcloud config get-value project)

# 3. Resource creation timeout
# Solution: Increase timeout in variables.tf or check GCP service availability

# 4. State file conflicts
# Solution: Use remote state and state locking
```

### Advanced Terraform Topics

**Module Customization**:
```bash
# Modify modules/gke-deployment/variables.tf
# Then update terraform/main.tf to pass new variables
terraform apply -var-file="environments/dev.tfvars"
```

**Variables File Structure** (environments/dev.tfvars):
```hcl
gcp_project_id    = "your-project-id"
gcp_region        = "us-central1"
cluster_name      = "gcp-info-dev"
node_count        = 1
machine_type      = "n1-standard-2"
app_version       = "0.1.0"
environment       = "dev"
```

For detailed information, see [terraform/README.md](terraform/README.md) and [terraform/SETUP.md](terraform/SETUP.md).

---

## ☸️ Kubernetes & Helm Deployment

### Helm Chart Management

The Helm chart (`helm-dir/`) provides templated Kubernetes deployments for both mainwebsite and metrics services with environment-specific configurations.

**Install Helm Chart**:
```bash
# Development
helm install mainwebsite ./helm-dir -f ./helm-dir/values-dev.yaml -n dev --create-namespace

# Staging
helm install mainwebsite ./helm-dir -f ./helm-dir/values-staging.yaml -n staging --create-namespace

# Production
helm install mainwebsite ./helm-dir -f ./helm-dir/values-prod.yaml -n production --create-namespace
```

**Upgrade Deployment**:
```bash
helm upgrade mainwebsite ./helm-dir -f ./helm-dir/values-prod.yaml -n production
```

**List Helm Releases**:
```bash
helm list -n production
helm list -A  # All namespaces
```

**Get Release Status**:
```bash
helm status mainwebsite -n production
helm get values mainwebsite -n production
```

**Rollback Deployment**:
```bash
# View revision history
helm history mainwebsite -n production

# Rollback to previous version
helm rollback mainwebsite 1 -n production
```

**Delete Deployment**:
```bash
helm uninstall mainwebsite -n production
```

For detailed configuration options, see [helm-dir/README.md](helm-dir/README.md).

---

## 🐳 Docker & Container Management

### Build and Push Service Images

**Main Website**:
```bash
cd mainwebsite
docker build -t gcr.io/clever-spirit-417020/mainwebsite:latest .
docker push gcr.io/clever-spirit-417020/mainwebsite:latest
kubectl rollout restart deploy mainwebsite
```

**Metrics Service**:
```bash
cd metrics
docker build -t gcr.io/clever-spirit-417020/metrics:latest .
docker push gcr.io/clever-spirit-417020/metrics:latest
kubectl rollout restart deploy metrics
```

### Image Tagging Strategy

**Development**:
```bash
docker tag mainwebsite gcr.io/project-id/mainwebsite:dev-latest
```

**Staging**:
```bash
docker tag mainwebsite gcr.io/project-id/mainwebsite:staging-latest
```

**Production** (explicit version):
```bash
docker tag mainwebsite gcr.io/project-id/mainwebsite:1.0.0
docker tag mainwebsite gcr.io/project-id/mainwebsite:latest
```

---

## 🔌 Ingress & Routing

### Traefik Ingress Controller

**Install Traefik**:
```bash
helm install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --set service.type=LoadBalancer
```

**Upgrade Traefik**:
```bash
helm upgrade traefik traefik/traefik -f traefik-values.yaml -n traefik
```

**View Traefik Configuration**:
```bash
kubectl describe service traefik -n traefik
helm get values traefik -n traefik
```

### Manage Traefik Deployment

**Scale Down (Temporary Stop)**:
```bash
kubectl scale deployment -n traefik traefik --replicas=0
```

**Restart**:
```bash
kubectl scale deployment -n traefik traefik --replicas=1
```

**Remove Traefik**:
```bash
kubectl delete all -n traefik -l app=traefik
helm uninstall traefik -n traefik
```

### IngressRoute Management

**List IngressRoutes**:
```bash
kubectl get ingressroute
kubectl get ingressroute -n production
```

**Get IngressRoute Details**:
```bash
kubectl describe ingressroute mainwebsite -n production
kubectl get ingressroute mainwebsite -n production -o yaml
```

**Delete Ingress Rules**:
```bash
kubectl delete ingressroute mainwebsite -n production
```

---

## 🔙 Deployment Management

### View Pod Details

**Check Cluster Status**:
```bash
kubectl get pods              # Current namespace
kubectl get pods -n production  # Specific namespace
kubectl get svc              # Services
kubectl get ingress          # Ingress rules
kubectl get nodes            # Cluster nodes
```

**View Pod Details**:
```bash
kubectl exec -it <pod_name> -- printenv    # Environment variables
kubectl logs <pod_name>                    # Pod logs
kubectl logs <pod_name> -f                 # Follow logs
kubectl logs <pod_name> --previous         # Previous pod logs (if crashed)
```

**Describe Resources**:
```bash
kubectl describe pod <pod_name> -n production
kubectl describe node <node_name>
kubectl describe svc mainwebsite -n production
```

### Deployment Rollback

**Rollback to Previous Version**:
```bash
kubectl rollout undo deployment/mainwebsite -n production
```

**View Rollout History**:
```bash
kubectl rollout history deployment/mainwebsite -n production
```

**Rollback to Specific Revision**:
```bash
kubectl rollout undo deployment/mainwebsite -n production --to-revision=5
```

**Check Rollback Status**:
```bash
kubectl rollout status deployment/mainwebsite -n production
kubectl get deployment mainwebsite -n production
```

---

## 🔍 Monitoring & Debugging

### View Logs

**Pod Logs**:
```bash
kubectl logs <pod-name> -n production
kubectl logs <pod-name> -n production --tail=100  # Last 100 lines
kubectl logs <pod-name> -n production -f          # Follow in real-time
```

**Application Logs**:
Logs are written to: `projects/YOUR_PROJECT_ID/logs/winston_log`

**View in Google Cloud Console**:
```bash
gcloud logging read "resource.type=k8s_container" --limit 50 --format=json
```

### Verify Service Status

**Traefik Status**:
```bash
kubectl get pods -n traefik
kubectl logs -n traefik <traefik-pod-name>
kubectl get crd | grep traefik
```

**Expected Traefik CRDs**:
- `ingressroutes.traefik.io`
- `middlewares.traefik.io`
- `traefikservices.traefik.io`

**Check Service Connectivity**:
```bash
kubectl exec -it <pod_name> -n production -- curl http://mainwebsite:3000
```

### Prometheus Monitoring

**Check ServiceMonitor**:
```bash
kubectl get servicemonitor -n production
kubectl describe servicemonitor mainwebsite -n production
```

**Access Prometheus Metrics**:
```bash
# Port-forward to Prometheus (if installed)
kubectl port-forward -n prometheus svc/prometheus 9090:9090

# Then access: http://localhost:9090
```

---

## ☁️ GCP Configuration

### Create Static IP Address

```bash
gcloud compute addresses create websitestatic2 --region=europe-west1
gcloud compute addresses list
gcloud compute addresses describe websitestatic2 --region=europe-west1
```

### Cloud SQL Connection

```bash
gcloud sql connect nextjs-app-db --user=root --quiet
```

### Service Account Permissions

```bash
# Grant Jenkins service account permissions
gcloud projects add-iam-policy-binding clever-spirit-417020 \
  --member="serviceAccount:jenkins@clever-spirit-417020.iam.gserviceaccount.com" \
  --role="roles/container.viewer"

gcloud projects add-iam-policy-binding clever-spirit-417020 \
  --member="serviceAccount:jenkins@clever-spirit-417020.iam.gserviceaccount.com" \
  --role="roles/compute.viewer"

gcloud projects add-iam-policy-binding clever-spirit-417020 \
  --member="serviceAccount:jenkins@clever-spirit-417020.iam.gserviceaccount.com" \
  --role="roles/container.developer"
```

### GKE Cluster Access

```bash
# Get cluster credentials
gcloud container clusters get-credentials <cluster-name> --zone <zone>

# List all clusters
gcloud container clusters list

# Describe cluster
gcloud container clusters describe <cluster-name> --zone <zone>
```

### Grant Jenkins Service Account Access to GKE

**Create Jenkins Service Account**:
```bash
kubectl create serviceaccount jenkins-sa
```

**Grant Permissions**:
```bash
kubectl create clusterrolebinding jenkins-sa-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=default:jenkins-sa
```

**Get Service Account Token**:
```bash
kubectl create token jenkins-sa

# Or retrieve existing token:
SECRET_NAME=$(kubectl get sa jenkins-sa -o jsonpath="{.secrets[0].name}")
TOKEN=$(kubectl get secret $SECRET_NAME -o jsonpath="{.data.token}" | base64 --decode)
echo $TOKEN
```

**Get Cluster URL**:
```bash
kubectl config view --minify -o jsonpath="{.clusters[0].cluster.server}"
```

---

## 🛠️ Utilities & Troubleshooting

### CSS Minification

```bash
css-minify --file filename
css-minify -d sourcedir -o distdir
```

### Remove Large Files from Git History

```bash
git filter-branch --force --index-filter 'git rm -r --cached --ignore-unmatch terraform/.terraform' \
  --prune-empty --tag-name-filter cat -- --all
```

### Troubleshooting Common Issues

**Issue: Pods not starting**
```bash
# Check pod status
kubectl describe pod <pod-name> -n production

# Check events
kubectl get events -n production --sort-by='.lastTimestamp'

# Check resource availability
kubectl top nodes
kubectl top pods -n production
```

**Issue: Service unreachable**
```bash
# Check service endpoints
kubectl get endpoints mainwebsite -n production

# Check DNS resolution
kubectl exec -it <pod> -- nslookup mainwebsite

# Verify ingress rules
kubectl get ingressroute -n production
kubectl describe ingressroute mainwebsite -n production
```

**Issue: High memory/CPU usage**
```bash
# View resource usage
kubectl top pods -n production --sort-by=memory

# Update resource limits in values.yaml and redeploy
helm upgrade mainwebsite ./helm-dir -f ./helm-dir/values-prod.yaml -n production
```

**Issue: CrashLoopBackOff pods**
```bash
# Check pod logs
kubectl logs <pod-name> -n production --previous

# Check environment variables
kubectl exec -it <pod-name> -n production -- printenv

# Verify ConfigMaps and Secrets
kubectl get configmap -n production
kubectl get secret -n production
```

---

## 📝 Summary

| Component | Purpose | Documentation |
|-----------|---------|----------------|
| Jenkins Files | CI/CD Automation | See [CI/CD Pipeline - Jenkins](#cicd-pipeline---jenkins) section |
| Terraform | Infrastructure as Code | See [terraform/README.md](terraform/README.md) |
| Helm Charts | Kubernetes Deployment | See [helm-dir/README.md](helm-dir/README.md) |
| Docker | Container Images | Build with `docker build` and push to GCR |
| Traefik | Ingress Controller | Installed via Helm, manages routing |
| GCP | Cloud Infrastructure | Managed via Terraform and gcloud CLI |

---

## 📞 Support & Resources

- **Terraform Documentation**: See [terraform/SETUP.md](terraform/SETUP.md) and [terraform/DEPLOYMENT_GUIDE.md](terraform/DEPLOYMENT_GUIDE.md)
- **Helm Chart Documentation**: See [helm-dir/README.md](helm-dir/README.md)
- **GCP Documentation**: https://cloud.google.com/docs
- **Kubernetes Documentation**: https://kubernetes.io/docs
- **Jenkins Documentation**: https://www.jenkins.io/doc

---

## 📝 Notes

- Replace `<pod_name>` with your actual pod name
- Replace `<traefik-namespace>` with your Traefik namespace (usually `traefik` or `kube-system`)
- Replace `<revision_number>` with the desired revision from history
- Update `YOUR_PROJECT_ID` with your actual GCP project ID
- Ensure all credentials are securely stored in Jenkins Credentials Store

