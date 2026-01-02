# GCP Info Website

A cloud-native application deployment using Kubernetes, Helm, Traefik, and GCP services.

## 📋 Table of Contents

- [Docker & Container Management](#docker--container-management)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Helm Chart Management](#helm-chart-management)
- [Traefik Ingress Controller](#traefik-ingress-controller)
- [Deployment Rollback](#deployment-rollback)
- [Monitoring & Debugging](#monitoring--debugging)
- [GCP Configuration](#gcp-configuration)
- [Database Access](#database-access)
- [Jenkins Integration](#jenkins-integration)
- [Utilities](#utilities)

---

## 🐳 Docker & Container Management

### Build and Push Service Images

**Main Website:**
```bash
cd mainwebsite
docker build -t gcr.io/clever-spirit-417020/mainwebsite:latest .
docker push gcr.io/clever-spirit-417020/mainwebsite:latest
kubectl rollout restart deploy mainwebsite
```

**Metrics Service:**
```bash
cd metrics
docker build -t gcr.io/clever-spirit-417020/metrics:latest .
docker push gcr.io/clever-spirit-417020/metrics:latest
```

---

## ☸️ Kubernetes Deployment

### Deploy Services and Ingress

```bash
# Deploy Main Website
kubectl apply -f k8s-manifests/mainwebsite-deployment.yaml
kubectl apply -f k8s-manifests/mainwebsite-service.yaml

# Deploy Metrics Service
kubectl apply -f k8s-manifests/metrics-deployment.yaml
kubectl apply -f k8s-manifests/metrics-service.yaml

# Deploy Ingress
kubectl apply -f k8s-manifests/ingress.yaml
```

### Check Cluster Status

```bash
kubectl get pods              # View all pods
kubectl get svc              # View all services
kubectl get ingress          # View ingress rules
```

### View Pod Details

```bash
kubectl exec -it <pod_name> -- printenv    # View environment variables
kubectl logs <pod_name>                    # View pod logs
```

---

## 📦 Helm Chart Management

### Install Helm Chart

```bash
helm install helm-dir ./helm-dir
```

### Upgrade Deployment

```bash
helm upgrade helm-dir ./helm-dir
```

### List Helm Releases

```bash
helm list
```

### Delete Deployment

```bash
helm uninstall helm-dir
```

---

## 🔄 Traefik Ingress Controller

### Install Traefik

```bash
helm install traefik traefik/traefik --set service.type=LoadBalancer
```

### Upgrade Traefik

```bash
helm upgrade traefik traefik/traefik -f treafik.yaml
```

### View Traefik Configuration

```bash
kubectl describe service traefik -n default
helm get values traefik -n default > values.yaml
```

### Manage Traefik Deployment

**Stop temporarily (scale down):**
```bash
kubectl scale deployment -n <traefik-namespace> traefik --replicas=0
```

**Restart:**
```bash
kubectl scale deployment -n <traefik-namespace> traefik --replicas=1
```

**Remove completely:**
```bash
kubectl delete all -n <traefik-namespace> -l app=traefik
```

### Delete Ingress Rules

```bash
kubectl delete ingress mainwebsite-ingress metrics-ingress
```

### IngressRoute Management

**List IngressRoutes:**
```bash
kubectl get ingressroute
```

**Get IngressRoute details:**
```bash
kubectl describe ingressroute <name-of-your-ingressroute>
```

---

## 🔙 Deployment Rollback

### Rollback to Previous Version

```bash
kubectl rollout undo deployment/mainwebsite
```

### View Rollout History

```bash
kubectl rollout history deployment/mainwebsite
```

### Rollback to Specific Revision

```bash
kubectl rollout undo deployment/mainwebsite --to-revision=<revision_number>
```

### Check Rollback Status

```bash
kubectl rollout status deployment/mainwebsite
kubectl get deployment mainwebsite
```

---

## 🔍 Monitoring & Debugging

### View Pod Logs

```bash
kubectl logs <pod-name>
```

### Verify Traefik is Running

```bash
kubectl get pods -n traefik
```

### Check Traefik Custom Resource Definitions

```bash
kubectl get crd
```

Expected CRDs: `ingressroutes.traefik.io`, `middlewares.traefik.io`, etc.

### Check Traefik Controller Logs

```bash
kubectl logs -n traefik <traefik-pod-name>
```

### Verify IngressRoute Configuration

Open `k8s-manifests/ingress.yaml` and ensure:
- IngressRoute points to correct services
- Entry points are configured (web for HTTP, websecure for HTTPS)

---

## ☁️ GCP Configuration

### Create Static IP Address

```bash
gcloud compute addresses create websitestatic2 --region=europe-west1
```

### List Static Addresses

```bash
gcloud compute addresses list
```

### Connect to Cloud SQL

```bash
gcloud sql connect nextjs-app-db --user=root --quiet
```

### Service Account Permissions

```bash
gcloud projects add-iam-policy-binding clever-spirit-417020 \
  --member="serviceAccount:jenkins@clever-spirit-417020.iam.gserviceaccount.com" \
  --role="roles/container.viewer"

gcloud projects add-iam-policy-binding clever-spirit-417020 \
  --member="serviceAccount:jenkins@clever-spirit-417020.iam.gserviceaccount.com" \
  --role="roles/compute.viewer"
```

---

## 💾 Database Access

### Cloud SQL Connection

```bash
gcloud sql connect nextjs-app-db --user=root --quiet
```

### Application Logs

Logs are written to: `projects/YOUR_PROJECT_ID/logs/winston_log`

---

## 🔧 Jenkins Integration

### Create Jenkins Service Account

```bash
kubectl create serviceaccount jenkins-sa
```

### Grant Permissions

```bash
kubectl create clusterrolebinding jenkins-sa-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=default:jenkins-sa
```

### Get Service Account Token

```bash
kubectl create token jenkins-sa
```

**Or retrieve existing token:**
```bash
SECRET_NAME=$(kubectl get sa jenkins-sa -o jsonpath="{.secrets[0].name}")
TOKEN=$(kubectl get secret $SECRET_NAME -o jsonpath="{.data.token}" | base64 --decode)
```

### Get Cluster URL

```bash
kubectl config view --minify -o jsonpath="{.clusters[0].cluster.server}"
```

### Create Jenkins Secret

```bash
kubectl create secret generic jenkins-sa-secret --from-literal=token=$(openssl rand -base64 32)
kubectl patch serviceaccount jenkins-sa -p '{"secrets": [{"name": "jenkins-sa-secret"}]}'
```

### Run Jenkins Docker Container

```bash
docker run --name jenkins-docker --rm --detach --privileged \
  --network jenkins --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume jenkins-docker-certs:/certs/client \
  --volume jenkins-data:/var/jenkins_home \
  --publish 2376:2376 docker:dind --storage-driver overlay2
```

---

## 🛠️ Utilities

### Minify CSS

```bash
css-minify --file filename
css-minify -d sourcedir -o distdir
```

### Remove Large Files from Git History

```bash
git filter-branch --force --index-filter 'git rm -r --cached --ignore-unmatch terraform/.terraform' \
  --prune-empty --tag-name-filter cat -- --all
```

---

## 📝 Notes

- Replace `<pod_name>` with your actual pod name
- Replace `<traefik-namespace>` with your Traefik namespace (usually `traefik` or `kube-system`)
- Replace `<revision_number>` with the desired revision from history
- Update `YOUR_PROJECT_ID` with your actual GCP project ID

