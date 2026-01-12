# Dashboard Helm Values Configuration

## Configuration Files

We now have a **unified configuration** approach:

1. **`values.yaml`** - Main configuration (works for all environments)
2. **`values-secrets.yaml`** - Your secrets (gitignored, environment-specific)
3. **`values-secrets.yaml.template`** - Template for setting up secrets

## Docker Hub Setup (Private Registry)

**All images are configured to always pull `latest` from your private Docker Hub repository.**

### Quick Setup

**1. Replace Docker Hub username in both values files:**
**Note:** The unified values.yaml now uses public DockerHub images from the `actyze` organization:
- `actyze/dashboard-nexus:latest`
- `actyze/dashboard-frontend:latest`
- `actyze/dashboard-schema-service:latest`

No private registry setup required!

**2. Create private repositories on Docker Hub:**
- Go to https://hub.docker.com/repositories
- Create 3 private repositories:
  - `dashboard-nexus`
  - `dashboard-frontend`
  - `dashboard-schema-service`

**3. Build and push images:**
```bash
# Set your Docker Hub username
export DOCKERHUB_USERNAME="your-username"

# Login to Docker Hub
docker login

# Build and push nexus
docker build -f nexus/Dockerfile -t ${DOCKERHUB_USERNAME}/dashboard-nexus:latest .
docker push ${DOCKERHUB_USERNAME}/dashboard-nexus:latest

# Build and push frontend
docker build -f frontend/Dockerfile -t ${DOCKERHUB_USERNAME}/dashboard-frontend:latest .
docker push ${DOCKERHUB_USERNAME}/dashboard-frontend:latest

# Build and push schema service
docker build -f schema-service/Dockerfile -t ${DOCKERHUB_USERNAME}/dashboard-schema-service:latest .
docker push ${DOCKERHUB_USERNAME}/dashboard-schema-service:latest
```

**4. Create Kubernetes secret for Docker Hub authentication:**
```bash
# For development (Kind cluster)
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=YOUR_DOCKERHUB_USERNAME \
  --docker-password=YOUR_DOCKERHUB_PASSWORD \
  --docker-email=YOUR_EMAIL \
  -n dashboard

# For production (Azure AKS)
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=YOUR_DOCKERHUB_USERNAME \
  --docker-password=YOUR_DOCKERHUB_PASSWORD \
  --docker-email=YOUR_EMAIL \
  -n dashboard \
  --context=your-production-cluster
```

**5. Deploy with Helm:**
```bash
# Now Helm will always pull the latest images from your private Docker Hub
helm upgrade --install dashboard ./helm/dashboard \
  --namespace dashboard \
  --create-namespace \
  --values helm/dashboard/values-dev.yaml
```

### Updating Images (No Helm Changes Needed!)

**Every time you build a new image, just push it:**
```bash
# Build new version
docker build -f nexus/Dockerfile -t ${DOCKERHUB_USERNAME}/dashboard-nexus:latest .

# Push to Docker Hub (overwrites latest tag)
docker push ${DOCKERHUB_USERNAME}/dashboard-nexus:latest

# Restart pods to pull new image
kubectl rollout restart deployment dashboard-nexus -n dashboard
```

**Helm values never need updating!** The `latest` tag and `pullPolicy: Always` ensure fresh images every time.

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
- ✅ No local GPU/CPU required
- ✅ Latest models (GPT-4, Claude, Perplexity)
- ✅ Pay-per-use pricing
- ✅ Instant updates to newer models

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

## Environment Differences

| Feature | Development | Production |
|---------|-------------|------------|
| **External LLM** | ✅ Enabled (default) | ✅ Enabled (default) |
| **Replicas** | 1 (single instance) | 3-10 (HA + autoscaling) |
| **Demo Data** | ✅ Enabled | ❌ Disabled |
| **Autoscaling** | ❌ Disabled | ✅ Enabled |
| **TLS/HTTPS** | ❌ Optional | ✅ Required |
| **Resource Limits** | Low (dev cluster) | High (production) |

## Migration from Old Configuration

**Configuration Consolidation:**
- ~~`values-dev.yaml`~~ → Merged into unified `values.yaml`
- ~~`values-production.yaml`~~ → Merged into unified `values.yaml`
- ~~`values-local.yaml`~~ → Deleted
- **New:** Single `values.yaml` works for all environments
- **New:** Public DockerHub images (no private registry needed)

## Security Notes

⚠️ **Production Security Checklist:**

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
