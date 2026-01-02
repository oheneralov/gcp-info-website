################################################################################
# Terraform State Backend Configuration (Google Cloud Storage)
################################################################################
# This file configures Terraform to store its state in Google Cloud Storage (GCS)
# instead of locally. This enables:
# - Team collaboration (shared state)
# - Remote state locking (prevents concurrent modifications)
# - Better security (state stored in GCS with encryption)
# - CI/CD pipeline integration
#
# SETUP INSTRUCTIONS:
# ===================
#
# 1. Create GCS buckets for each environment:
#    gsutil mb -p YOUR_PROJECT_ID gs://tf-state-dev-YOUR_PROJECT_ID
#    gsutil mb -p YOUR_PROJECT_ID gs://tf-state-staging-YOUR_PROJECT_ID
#    gsutil mb -p YOUR_PROJECT_ID gs://tf-state-prod-YOUR_PROJECT_ID
#
# 2. Enable versioning on buckets (recommended):
#    gsutil versioning set on gs://tf-state-dev-YOUR_PROJECT_ID
#    gsutil versioning set on gs://tf-state-staging-YOUR_PROJECT_ID
#    gsutil versioning set on gs://tf-state-prod-YOUR_PROJECT_ID
#
# 3. Enable encryption on buckets (recommended):
#    gsutil encryption set gs://tf-state-dev-YOUR_PROJECT_ID
#    gsutil encryption set gs://tf-state-staging-YOUR_PROJECT_ID
#    gsutil encryption set gs://tf-state-prod-YOUR_PROJECT_ID
#
# 4. Restrict bucket access:
#    gsutil iam ch serviceAccount:YOUR_SA_EMAIL:objectAdmin gs://tf-state-dev-YOUR_PROJECT_ID
#    gsutil iam ch serviceAccount:YOUR_SA_EMAIL:objectAdmin gs://tf-state-staging-YOUR_PROJECT_ID
#    gsutil iam ch serviceAccount:YOUR_SA_EMAIL:objectAdmin gs://tf-state-prod-YOUR_PROJECT_ID
#
# 5. Initialize Terraform with GCS backend for each environment:
#
#    # For Development:
#    terraform init -backend-config=environments/backend-dev.tfvars
#
#    # For Staging:
#    terraform init -backend-config=environments/backend-staging.tfvars
#
#    # For Production:
#    terraform init -backend-config=environments/backend-production.tfvars
#
# 6. After initialization, you can use standard Terraform commands:
#    terraform plan -var-file=environments/dev.tfvars
#    terraform apply -var-file=environments/dev.tfvars
#
# MIGRATION FROM LOCAL STATE:
# ============================
#
# If you have existing local state files (terraform.tfstate), migrate them:
#
#    1. Initialize backend: terraform init -backend-config=environments/backend-dev.tfvars
#    2. Confirm migration when prompted
#    3. Verify state was uploaded: gsutil ls gs://tf-state-dev-YOUR_PROJECT_ID/
#    4. Keep local terraform.tfstate as backup
#    5. Add terraform.tfstate* to .gitignore if not already done
#
# SECURITY BEST PRACTICES:
# =========================
# - Enable versioning on all state buckets
# - Enable object hold to prevent accidental deletion
# - Enable logging to track state access
# - Restrict IAM permissions to only necessary service accounts
# - Enable encryption (default GCS encryption or CMEK)
# - Regularly audit state file access
# - Never commit state files to version control

