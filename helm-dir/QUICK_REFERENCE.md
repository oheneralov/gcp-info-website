# Helm Chart Quick Reference

## Installation Commands

```bash
# Development
helm install mainwebsite helm-dir/ -f helm-dir/values-dev.yaml -n development --create-namespace

# Staging  
helm install mainwebsite helm-dir/ -f helm-dir/values-staging.yaml -n staging --create-namespace

# Production
helm install mainwebsite helm-dir/ -f helm-dir/values-prod.yaml -n production --create-namespace
```

## Upgrade Commands

```bash
# All environments use same pattern
helm upgrade mainwebsite helm-dir/ -f helm-dir/values-prod.yaml -n production --wait

# With new image tags
helm upgrade mainwebsite helm-dir/ -f helm-dir/values-prod.yaml \
  --set mainwebsite.image.tag=v1.2.3 \
  --set metrics.image.tag=v2.0.0 \
  -n production
```

## Common Queries

```bash
# Check deployment status
kubectl get pods -n production
kubectl get deployments -n production

# Check services
kubectl get svc -n production
kubectl get endpoints -n production

# Check ingress routing
kubectl get ingressroute -n production

# Check autoscaling
kubectl get hpa -n production

# Check RBAC
kubectl get serviceaccount -n production
kubectl get clusterrole | grep mainwebsite
kubectl get clusterrolebinding | grep mainwebsite

# Check monitoring
kubectl get servicemonitor -n production

# View logs
kubectl logs deployment/mainwebsite-mainwebsite -n production
kubectl logs deployment/mainwebsite-metrics -n production

# Tail logs
kubectl logs -f deployment/mainwebsite-mainwebsite -n production
```

## Dry-Run & Validation

```bash
# Dry run (no deployment)
helm install mainwebsite helm-dir/ --dry-run --debug

# Template rendering
helm template mainwebsite helm-dir/ -f helm-dir/values-prod.yaml

# Lint chart
helm lint helm-dir/

# Validate manifests
helm template mainwebsite helm-dir/ | kubeval
```

## Rollback & Rollout

```bash
# Get release history
helm history mainwebsite -n production

# Rollback to previous version
helm rollback mainwebsite -n production

# Check rollout status
kubectl rollout status deployment/mainwebsite-mainwebsite -n production
kubectl rollout status deployment/mainwebsite-metrics -n production

# Manual rollout
kubectl rollout restart deployment/mainwebsite-mainwebsite -n production
```

## Configuration Overrides

```bash
# Override single value
helm install mainwebsite helm-dir/ \
  --set mainwebsite.replicaCount=5 \
  -n production

# Override multiple values
helm install mainwebsite helm-dir/ \
  --set mainwebsite.replicaCount=5 \
  --set metrics.replicaCount=2 \
  --set ingress.mainwebsite.hostname=myapp.com \
  -n production

# Use custom values file AND override
helm install mainwebsite helm-dir/ \
  -f helm-dir/values-prod.yaml \
  --set mainwebsite.image.tag=custom-tag \
  -n production
```

## Environment-Specific Patterns

### Development: Quick Deploy
```bash
helm install mainwebsite helm-dir/ -f helm-dir/values-dev.yaml
```

### Staging: Test Changes
```bash
helm upgrade mainwebsite helm-dir/ -f helm-dir/values-staging.yaml --wait
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=mainwebsite -n staging --timeout=300s
```

### Production: Safe Deployment
```bash
# Plan
helm diff upgrade mainwebsite helm-dir/ -f helm-dir/values-prod.yaml -n production

# Upgrade with wait
helm upgrade mainwebsite helm-dir/ -f helm-dir/values-prod.yaml -n production --wait --timeout 5m

# Verify
kubectl get pods -n production
kubectl logs deployment/mainwebsite-mainwebsite -n production
```

## Configuration Files

| File | Purpose | When to Use |
|------|---------|------------|
| `values.yaml` | Default values | Base configuration |
| `values-dev.yaml` | Development | Dev environments |
| `values-staging.yaml` | Staging | Pre-production testing |
| `values-prod.yaml` | Production | Production deployments |

## Template Files

| File | Manages |
|------|---------|
| `deployment.yaml` | Mainwebsite Deployment |
| `deployment-metrics.yaml` | Metrics Deployment |
| `service.yaml` | Both Services |
| `ingress.yaml` | Traefik IngressRoutes |
| `hpa-mainwebsite.yaml` | Mainwebsite Autoscaling |
| `hpa-metrics.yaml` | Metrics Autoscaling |
| `servicemonitor.yaml` | Prometheus Monitoring |
| `poddisruptionbudget.yaml` | High Availability |
| `serviceaccount.yaml` | RBAC ServiceAccount |
| `clusterrole.yaml` | RBAC Permissions |
| `clusterrolebinding.yaml` | RBAC Bindings |

## Key Values Structure

```yaml
global:
  namespace: production
  labels: {}
  annotations: {}

mainwebsite:
  enabled: true
  replicaCount: 3
  image:
    repository: gcr.io/project/mainwebsite
    tag: "1.0.0"
  service:
    type: ClusterIP
    port: 80
  resources:
    limits: {cpu: 1000m, memory: 1Gi}
    requests: {cpu: 500m, memory: 512Mi}
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10

metrics:
  enabled: true
  replicaCount: 2
  [similar structure to mainwebsite]

ingress:
  enabled: true
  mainwebsite:
    hostname: oleksandrdesign.com
  metrics:
    hostname: metrics.oleksandrdesign.com

monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s

rbac:
  create: true
```

## Debugging Commands

```bash
# Describe resources
kubectl describe deployment mainwebsite-mainwebsite -n production
kubectl describe service mainwebsite-mainwebsite -n production
kubectl describe pod <pod-name> -n production

# Check events
kubectl get events -n production --sort-by='.lastTimestamp'

# Port forward to test
kubectl port-forward svc/mainwebsite-mainwebsite 3000:80 -n production

# Execute command in pod
kubectl exec -it <pod-name> -n production -- /bin/sh

# Check volume mounts
kubectl get pvc -n production
kubectl get pv
```

## Performance Monitoring

```bash
# CPU and Memory usage
kubectl top pods -n production
kubectl top nodes

# HPA status
kubectl get hpa -n production
kubectl get hpa -n production -w  # Watch

# Resource requests vs actual
kubectl describe node
```

## Security Checks

```bash
# Verify RBAC
kubectl auth can-i list deployments --as=system:serviceaccount:production:mainwebsite -n production

# Check security context
kubectl get pod <pod-name> -o jsonpath='{.spec.securityContext}'

# Verify labels
kubectl get pods -n production --show-labels
```

## Uninstall

```bash
# Delete release but keep history
helm uninstall mainwebsite -n production

# Delete with all history
helm delete mainwebsite -n production
```

## Files to Read

1. **Start here**: `README.md` - Overview and usage
2. **Deep dive**: `BEST_PRACTICES_SUMMARY.md` - Detailed changes
3. **Reference**: `REFACTORING_COMPLETE.md` - What changed
4. **Quick help**: This file

## Common Issues & Solutions

**Pod CrashLoopBackOff?**
```bash
kubectl logs <pod-name> -n production
kubectl describe pod <pod-name> -n production
```

**Service not reachable?**
```bash
kubectl get svc -n production
kubectl get endpoints -n production
kubectl port-forward svc/mainwebsite-mainwebsite 3000:80 -n production
```

**Image pull errors?**
```bash
kubectl get pods -n production
kubectl describe pod <pod-name> -n production | grep -i pull
kubectl get secret -n production
```

**Resource limits exceeded?**
```bash
kubectl top pods -n production
kubectl describe nodes
# Increase limits in values file and upgrade
```

**HPA not scaling?**
```bash
kubectl get hpa -n production
kubectl describe hpa mainwebsite-mainwebsite -n production
kubectl top pods -n production
```

---

**Pro Tips:**
- Use `-f values-prod.yaml` always in production to avoid mistakes
- Use `--dry-run` before any production deployment
- Use `--wait` to ensure rollout completes
- Keep `helm history` clean for easy rollbacks
- Tag production images with explicit versions, not `latest`
- Monitor HPA metrics to understand scaling patterns
- Use namespaces to isolate environments

