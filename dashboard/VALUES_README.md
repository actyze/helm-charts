# Dashboard Helm Values Configuration

## Configuration Files

We now have a **unified configuration** approach:

1. **`values.yaml`** - Main configuration (works for all environments)
2. **`values-secrets.yaml`** - Your secrets (gitignored, environment-specific)
3. **`values-secrets.yaml.template`** - Template for setting up secrets

## Docker Image Configuration

Actyze Helm charts use **public Docker Hub images** with automatic updates:

```yaml
nexus:
  image:
    repository: actyze/dashboard-nexus
    tag: main-llm-flex
    pullPolicy: Always  # Always pull latest from Docker Hub

frontend:
  image:
    repository: actyze/dashboard-frontend
    tag: latest
    pullPolicy: Always

schemaService:
  image:
    repository: actyze/dashboard-schema-service
    tag: latest
    pullPolicy: Always
```

**Benefits:**
- No manual image building required
- Automatic updates with latest features and bug fixes
- `pullPolicy: Always` ensures fresh images on every deployment
- Consistent across all environments

**Docker Hub Repositories:**
- https://hub.docker.com/r/actyze/dashboard-nexus
- https://hub.docker.com/r/actyze/dashboard-frontend
- https://hub.docker.com/r/actyze/dashboard-schema-service

### Updating to Latest Images

With `pullPolicy: Always`, simply restart your deployments to pull the latest images:

```bash
# Restart individual services to pull latest images
kubectl rollout restart deployment/dashboard-nexus -n actyze
kubectl rollout restart deployment/dashboard-frontend -n actyze
kubectl rollout restart deployment/dashboard-schema-service -n actyze

# Or restart all services
kubectl rollout restart deployment -n actyze
```

No Helm upgrade needed! The images are automatically pulled fresh each time a pod starts.

## Model Strategy - Choose ONE

Both files have a `modelStrategy` section where you choose your SQL generation approach:

### Option 1: External LLM APIs (Current Default)
```yaml
modelStrategy:
  externalLLM:
    enabled: true           # ← Set to true to use external APIs
    provider: "perplexity"  # openai, perplexity, anthropic, groq, together
    model: "sonar-reasoning-pro"
    apiKey: "your-api-key"  # Should be from Kubernetes secret in production
```

**Benefits:**
- No local GPU/CPU required
- Latest models (GPT-4, Claude, Perplexity)
- Pay-per-use pricing
- Instant updates to newer models

## Optional Services

All services can be toggled in the `services` section:

```yaml
services:
  nexus:
    enabled: true        # REQUIRED - core orchestration
  frontend:
    enabled: true        # REQUIRED - web interface
  schemaService:
    enabled: true        # REQUIRED - improves SQL quality
  postgres:
    enabled: true        # REQUIRED - operational database
  trino:
    enabled: true        # REQUIRED - query execution
```

## Deployment Commands

### All Environments (Dev, Staging, Production)
```bash
# 1. Create secrets file from template
cp helm/dashboard/values-secrets.yaml.template helm/dashboard/values-secrets.yaml
# Edit values-secrets.yaml with your credentials

# 2. Deploy
helm install dashboard ./helm/dashboard \
  --namespace dashboard \
  --create-namespace \
  --values helm/dashboard/values.yaml \
  --values helm/dashboard/values-secrets.yaml
```

## Upgrading Configuration

```bash
helm upgrade dashboard ./helm/dashboard \
  --namespace dashboard \
  --values helm/dashboard/values.yaml \
  --values helm/dashboard/values-secrets.yaml
```

---

## Custom Domain Configuration

### Quick Start - Local Development

By default, the Ingress is configured for local Kubernetes cluster access:
```yaml
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: dashboard.local
      paths:
        - path: /          # Frontend UI
          pathType: Prefix
          service: frontend
        - path: /api       # Backend API  
          pathType: Prefix
          service: nexus
```

**Access at:** http://dashboard.local:80 (after adding to `/etc/hosts`)

---

### Production Setup with Custom Domain

#### Step 1: Configure Your Domain in `values.yaml`

```yaml
ingress:
  enabled: true
  className: "nginx"  # Or your ingress controller (traefik, alb, etc.)
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: analytics.yourcompany.com  # 👈 YOUR CUSTOM DOMAIN
      paths:
        - path: /
          pathType: Prefix
          service: frontend
        - path: /api
          pathType: Prefix
          service: nexus
  tls:
    - secretName: dashboard-tls
      hosts:
        - analytics.yourcompany.com
```

#### Step 2: DNS Configuration

Point your domain to your Kubernetes cluster's ingress IP:

```bash
# Get your ingress IP/hostname
kubectl get ingress -n dashboard

# Example A record:
# analytics.yourcompany.com  →  35.123.45.67 (your ingress IP)
```

**For AWS EKS (ALB):**
```yaml
ingress:
  className: "alb"
  annotations:
    alb.ingress.kubernetes.io/scheme: "internet-facing"
    alb.ingress.kubernetes.io/target-type: "ip"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
```

**For GCP GKE:**
```yaml
ingress:
  className: "gce"
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "dashboard-ip"
```

**For Azure AKS:**
```yaml
ingress:
  className: "nginx"
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/use-regex: "true"
```

#### Step 3: SSL/TLS Setup

**Option A: Automatic Certificates with cert-manager** (Recommended)

1. Install cert-manager:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

2. Create ClusterIssuer:
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@yourcompany.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

3. Enable in `values.yaml`:
```yaml
ingress:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  tls:
    - secretName: dashboard-tls
      hosts:
        - analytics.yourcompany.com
```

**Option B: Manual Certificate**

```bash
# Create TLS secret from your certificate files
kubectl create secret tls dashboard-tls \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  -n dashboard
```

Then configure in `values.yaml`:
```yaml
ingress:
  tls:
    - secretName: dashboard-tls
      hosts:
        - analytics.yourcompany.com
```

---

### Advanced Ingress Configuration

#### Custom Annotations

```yaml
ingress:
  annotations:
    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "100"
    
    # Large file uploads
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    
    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://yourapp.com"
    
    # Timeouts
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    
    # IP Whitelisting
    nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/8,172.16.0.0/12"
```

#### Multiple Domains

```yaml
ingress:
  hosts:
    - host: analytics.yourcompany.com
      paths:
        - path: /
          pathType: Prefix
          service: frontend
        - path: /api
          pathType: Prefix
          service: nexus
    - host: dashboard.yourcompany.com  # Alternative domain
      paths:
        - path: /
          pathType: Prefix
          service: frontend
        - path: /api
          pathType: Prefix
          service: nexus
  tls:
    - secretName: dashboard-tls-primary
      hosts:
        - analytics.yourcompany.com
    - secretName: dashboard-tls-secondary
      hosts:
        - dashboard.yourcompany.com
```

#### Path-Based Routing (Multi-tenancy)

```yaml
ingress:
  hosts:
    - host: platform.yourcompany.com
      paths:
        - path: /analytics
          pathType: Prefix
          service: frontend
        - path: /analytics/api
          pathType: Prefix
          service: nexus
```

---

### Testing Your Domain

```bash
# 1. Check DNS resolution
nslookup analytics.yourcompany.com

# 2. Check ingress status
kubectl get ingress -n dashboard

# 3. Check certificate (if using TLS)
kubectl get certificate -n dashboard

# 4. Test HTTP access
curl http://analytics.yourcompany.com

# 5. Test HTTPS access
curl https://analytics.yourcompany.com
```

---

### Troubleshooting

**Issue: "Default backend - 404"**
- Check ingress controller is installed: `kubectl get pods -n ingress-nginx`
- Verify service names match: `kubectl get svc -n dashboard`

**Issue: Certificate not issuing**
- Check cert-manager logs: `kubectl logs -n cert-manager deployment/cert-manager`
- Check certificate status: `kubectl describe certificate dashboard-tls -n dashboard`

**Issue: SSL not working**
- Verify TLS secret exists: `kubectl get secret dashboard-tls -n dashboard`
- Check ingress TLS configuration: `kubectl describe ingress -n dashboard`

**Issue: 502 Bad Gateway**
- Check pods are running: `kubectl get pods -n dashboard`
- Check service endpoints: `kubectl get endpoints -n dashboard`

---

## Environment Differences

| Feature | Development | Production |
|---------|-------------|------------|
| **External LLM** | Enabled (default) | Enabled (default) |
| **Replicas** | 1 (single instance) | 3-10 (HA + autoscaling) |
| **Demo Data** | Enabled | Disabled |
| **Autoscaling** | Disabled | Enabled |
| **TLS/HTTPS** | Optional | Required |
| **Resource Limits** | Low (dev cluster) | High (production) |

## Migration from Old Configuration

**Configuration Consolidation:**
- ~~`values-dev.yaml`~~ → Merged into unified `values.yaml`
- ~~`values-production.yaml`~~ → Merged into unified `values.yaml`
- ~~`values-local.yaml`~~ → Deleted
- **New:** Single `values.yaml` works for all environments
- **New:** Public DockerHub images (no private registry needed)

## Security Notes

**Production Security Checklist:**

1. **Never commit API keys** to version control
2. **Use Kubernetes secrets** for sensitive data:
   ```bash
   kubectl create secret generic external-llm-secret \
     --from-literal=apiKey=your-actual-api-key \
     -n dashboard
   ```
3. **Enable TLS/HTTPS** in production ingress
4. **Use Azure Managed Identity** for cloud resources
5. **Enable network policies** to restrict pod communication

## Troubleshooting

### Nexus can't reach external LLM
Check that `modelStrategy.externalLLM.enabled` is `true` and API key is correctly set.

### Schema service not improving results
Ensure `services.schemaService.enabled` is `true`.

## Support

For issues, check:
1. Pod logs: `kubectl logs -n dashboard <pod-name>`
2. Events: `kubectl get events -n dashboard`
3. Configuration: `helm get values dashboard -n dashboard`
