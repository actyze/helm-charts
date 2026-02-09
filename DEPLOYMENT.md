# Actyze Kubernetes Deployment Guide

Complete guide for deploying Actyze to your Kubernetes cluster using Helm.

---

## Quick Start

Deploy Actyze in 3 steps:

\`\`\`bash
# 1. Clone Helm charts
git clone https://github.com/actyze/helm-charts.git
cd helm-charts

# 2. Configure secrets
cp dashboard/values-secrets.yaml.template dashboard/values-secrets.yaml
nano dashboard/values-secrets.yaml
# Add your LLM API key and passwords

# 3. Deploy
helm install dashboard ./dashboard \\
  --namespace actyze \\
  --create-namespace \\
  --values dashboard/values.yaml \\
  --values dashboard/values-secrets.yaml \\
  --wait
\`\`\`

---

## Prerequisites

**Infrastructure:**
- Kubernetes cluster v1.24 or higher
- Helm 3.x installed
- \`kubectl\` configured to access your cluster

**Credentials:**
- LLM API key (Anthropic, OpenAI, Perplexity, or Groq)
- Database passwords

**Resources:**
- **Minimum (Dev/Testing)**: 2-3 nodes × 4 CPU × 8Gi RAM
- **Recommended (Production)**: 4-5 nodes × 8 CPU × 16Gi RAM
- **Enterprise**: 4-5 nodes × 16 CPU × 32Gi RAM

See [Production Resource Requirements](README.md#production-resource-requirements) for details.

---

## Step-by-Step Deployment

### Step 1: Get Helm Charts

\`\`\`bash
# Clone repository
git clone https://github.com/actyze/helm-charts.git
cd helm-charts
\`\`\`

### Step 2: Configure Secrets

\`\`\`bash
# Copy template
cp dashboard/values-secrets.yaml.template dashboard/values-secrets.yaml

# Edit with your credentials
nano dashboard/values-secrets.yaml
\`\`\`

**Required secrets:**

\`\`\`yaml
secrets:
  # LLM API Key (REQUIRED)
  externalLLM:
    apiKey: "your-llm-api-key"
  
  # PostgreSQL Password (REQUIRED)
  postgres:
    password: "your-secure-password"
\`\`\`

### Step 3: Configure LLM Provider (Optional)

Default is Anthropic Claude. To use a different provider, edit \`dashboard/values.yaml\`:

\`\`\`yaml
modelStrategy:
  externalLLM:
    enabled: true
    provider: "anthropic"  # or openai, perplexity, groq
    model: "claude-sonnet-4-20250514"
    baseUrl: "https://api.anthropic.com/v1/messages"
    authType: "x-api-key"
    extraHeaders: '{"anthropic-version": "2023-06-01"}'
\`\`\`

See [LLM Provider Configuration](dashboard/LLM_PROVIDERS.md) for all providers.

### Step 4: Configure Ingress (Production Only)

For production, configure external access in \`dashboard/values.yaml\`:

\`\`\`yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: analytics.yourcompany.com
      paths:
        - path: /
          pathType: Prefix
          service: frontend
        - path: /api
          pathType: Prefix
          service: nexus
  tls:
    - secretName: actyze-tls
      hosts:
        - analytics.yourcompany.com
\`\`\`

See [Ingress Configuration](dashboard/VALUES_README.md#ingress-configuration) for details.

### Step 5: Deploy Actyze

\`\`\`bash
helm install dashboard ./dashboard \\
  --namespace actyze \\
  --create-namespace \\
  --values dashboard/values.yaml \\
  --values dashboard/values-secrets.yaml \\
  --wait
\`\`\`

**Wait time:** 2-5 minutes for all services to start.

### Step 6: Verify Deployment

\`\`\`bash
# Check all pods are running
kubectl get pods -n actyze

# Expected output:
# NAME                                  READY   STATUS
# dashboard-frontend-xxx                1/1     Running
# dashboard-nexus-xxx                   1/1     Running
# dashboard-schema-service-xxx          1/1     Running
# dashboard-postgres-0                  1/1     Running
# dashboard-trino-xxx                   1/1     Running

# Check services
kubectl get svc -n actyze

# Check ingress (if configured)
kubectl get ingress -n actyze
\`\`\`

### Step 7: Access Actyze

**Via Ingress (Production):**
\`\`\`
https://analytics.yourcompany.com
\`\`\`

**Via Port-Forward (Testing):**
\`\`\`bash
kubectl port-forward -n actyze svc/dashboard-frontend 3000:80
# Access: http://localhost:3000
\`\`\`

**Login:**
- Username: \`nexus_admin\`
- Password: \`admin\`
- **Change password immediately**

---

## Resource Configuration

Choose the resource tier that matches your needs:

### Minimum (Development/Testing)

\`\`\`bash
# Edit dashboard/values.yaml
# Use default values (lowest tier)
helm install dashboard ./dashboard \\
  --namespace actyze \\
  --create-namespace \\
  --values dashboard/values.yaml \\
  --values dashboard/values-secrets.yaml
\`\`\`

**Cluster:** 2-3 nodes × 4 CPU × 8Gi RAM  
**Use case:** Evaluation and testing only

### Recommended (Standard Production)

See [VALUES_README.md](dashboard/VALUES_README.md#recommended-production-standard) for complete configuration.

**Cluster:** 4-5 nodes × 8 CPU × 16Gi RAM  
**Use case:** Most production deployments (hundreds of users)

### Enterprise (Maximum Performance)

See [VALUES_README.md](dashboard/VALUES_README.md#enterprise-maximum-performance) for complete configuration.

**Cluster:** 4-5 nodes × 16 CPU × 32Gi RAM  
**Use case:** Large organizations, high concurrency (thousands of users)

---

## Connecting Your Data

### Configure Database Connections

Edit \`dashboard/values.yaml\` to add your data sources:

\`\`\`yaml
trino:
  catalogs:
    # PostgreSQL
    production:
      connector.name: postgresql
      connection-url: jdbc:postgresql://db.yourcompany.com:5432/production
      connection-user: analytics_user
      connection-password: \${TRINO_POSTGRES_PASSWORD}
    
    # MySQL
    sales:
      connector.name: mysql
      connection-url: jdbc:mysql://mysql.yourcompany.com:3306/sales
      connection-user: analytics_user
      connection-password: \${TRINO_MYSQL_PASSWORD}
    
    # Snowflake
    warehouse:
      connector.name: snowflake
      snowflake.account: your-account
      snowflake.user: analytics_user
      snowflake.password: \${TRINO_SNOWFLAKE_PASSWORD}
\`\`\`

Add passwords in \`dashboard/values-secrets.yaml\`:

\`\`\`yaml
secrets:
  trino:
    postgresPassword: "your-password"
    mysqlPassword: "your-password"
    snowflakePassword: "your-password"
\`\`\`

See [Database Connectors](https://docs.actyze.io/docs/features/database-connectors) for all supported databases.

---

## Management

### View Status

\`\`\`bash
# Check deployment status
helm status dashboard --namespace actyze

# List all releases
helm list --namespace actyze

# View logs
kubectl logs -f deployment/dashboard-nexus -n actyze
kubectl logs -f deployment/dashboard-frontend -n actyze

# Check resource usage
kubectl top pods -n actyze
\`\`\`

### Update Configuration

\`\`\`bash
# Edit configuration
nano dashboard/values.yaml

# Apply changes
helm upgrade dashboard ./dashboard \\
  --namespace actyze \\
  --values dashboard/values.yaml \\
  --values dashboard/values-secrets.yaml
\`\`\`

### Update to Latest Version

\`\`\`bash
# Pull latest chart changes
git pull

# Upgrade deployment
helm upgrade dashboard ./dashboard \\
  --namespace actyze \\
  --values dashboard/values.yaml \\
  --values dashboard/values-secrets.yaml
\`\`\`

**Images automatically update** - \`pullPolicy: Always\` pulls latest from Docker Hub.

### Scale Services

\`\`\`bash
# Scale Nexus for more concurrency
kubectl scale deployment/dashboard-nexus --replicas=5 -n actyze

# Or configure in values.yaml:
# nexus:
#   replicaCount: 5

# Apply with Helm
helm upgrade dashboard ./dashboard \\
  --namespace actyze \\
  --values dashboard/values.yaml \\
  --values dashboard/values-secrets.yaml
\`\`\`

### Rollback

\`\`\`bash
# View deployment history
helm history dashboard --namespace actyze

# Rollback to previous version
helm rollback dashboard --namespace actyze

# Rollback to specific revision
helm rollback dashboard 3 --namespace actyze
\`\`\`

### Uninstall

\`\`\`bash
# Remove Actyze (preserves persistent volumes)
helm uninstall dashboard --namespace actyze

# Delete persistent volumes (optional)
kubectl delete pvc --all --namespace actyze

# Delete namespace
kubectl delete namespace actyze
\`\`\`

---

## Troubleshooting

### Pods Not Starting

\`\`\`bash
# Check pod status
kubectl get pods -n actyze

# View pod details
kubectl describe pod dashboard-nexus-xxx -n actyze

# Check logs
kubectl logs dashboard-nexus-xxx -n actyze

# Check events
kubectl get events -n actyze --sort-by='.lastTimestamp'
\`\`\`

### Insufficient Resources

**Symptom:** Pods stuck in "Pending" state

**Solution:**
\`\`\`bash
# Check node resources
kubectl describe nodes

# View resource requests
kubectl describe pod dashboard-trino-xxx -n actyze | grep -A 5 "Requests"

# Solutions:
# 1. Scale down replicas in values.yaml
# 2. Reduce resource requests in values.yaml
# 3. Add more nodes to your cluster
\`\`\`

### Image Pull Errors

**Images are public on Docker Hub** - no authentication needed.

\`\`\`bash
# Verify images are accessible
docker pull actyze/dashboard-frontend:latest
docker pull actyze/dashboard-nexus:main-llm-flex
docker pull actyze/dashboard-schema-service:latest

# Check pod events
kubectl describe pod dashboard-frontend-xxx -n actyze
\`\`\`

### Database Connection Issues

\`\`\`bash
# Check PostgreSQL logs
kubectl logs dashboard-postgres-0 -n actyze

# Test database connection
kubectl exec -it dashboard-postgres-0 -n actyze -- psql -U nexus_service -d dashboard

# Verify secrets are configured
kubectl get secret dashboard-postgres -n actyze -o yaml
\`\`\`

### LLM API Issues

\`\`\`bash
# Check Nexus logs for LLM errors
kubectl logs deployment/dashboard-nexus -n actyze | grep -i llm

# Verify API key secret
kubectl get secret dashboard-external-llm -n actyze -o yaml

# Test API key manually (example for Anthropic)
kubectl run test-curl --rm -i --tty --image=curlimages/curl -- \\
  curl https://api.anthropic.com/v1/messages \\
  -H "x-api-key: YOUR_KEY" \\
  -H "anthropic-version: 2023-06-01" \\
  -H "content-type: application/json" \\
  -d '{"model":"claude-sonnet-4-20250514","max_tokens":100,"messages":[{"role":"user","content":"test"}]}'
\`\`\`

### Ingress Not Working

\`\`\`bash
# Check ingress status
kubectl get ingress -n actyze
kubectl describe ingress dashboard-ingress -n actyze

# Verify ingress controller is running
kubectl get pods -n ingress-nginx

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Test DNS resolution
nslookup analytics.yourcompany.com
\`\`\`

### SSL Certificate Issues

\`\`\`bash
# Check cert-manager (if using)
kubectl get certificate -n actyze
kubectl describe certificate actyze-tls -n actyze

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Verify TLS secret exists
kubectl get secret actyze-tls -n actyze
\`\`\`

---

## Cloud Provider Specific

### AWS (EKS)

**Ingress with ALB:**
\`\`\`yaml
ingress:
  className: "alb"
  annotations:
    alb.ingress.kubernetes.io/scheme: "internet-facing"
    alb.ingress.kubernetes.io/target-type: "ip"
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:region:account:certificate/xxxxx"
\`\`\`

**Storage:**
\`\`\`yaml
postgres:
  persistence:
    storageClass: "gp3"  # or gp2, io1
\`\`\`

### Google Cloud (GKE)

**Ingress with GCE:**
\`\`\`yaml
ingress:
  className: "gce"
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "actyze-ip"
    networking.gke.io/managed-certificates: "actyze-cert"
\`\`\`

**Storage:**
\`\`\`yaml
postgres:
  persistence:
    storageClass: "standard"  # or ssd
\`\`\`

### Azure (AKS)

**Ingress with Application Gateway:**
\`\`\`yaml
ingress:
  className: "azure/application-gateway"
  annotations:
    appgw.ingress.kubernetes.io/ssl-redirect: "true"
\`\`\`

**Storage:**
\`\`\`yaml
postgres:
  persistence:
    storageClass: "managed-premium"  # or default
\`\`\`

---

## Support

**Documentation:**
- Complete Guide: https://docs.actyze.io
- Deployment Guide: https://docs.actyze.io/docs/deployment/helm
- Configuration Reference: [VALUES_README.md](dashboard/VALUES_README.md)
- LLM Providers: [LLM_PROVIDERS.md](dashboard/LLM_PROVIDERS.md)

**Support:**
- GitHub Issues: https://github.com/actyze/helm-charts/issues
- Docker Hub: https://hub.docker.com/u/actyze

**Related:**
- Local Deployment (Docker): https://github.com/actyze/dashboard-docker
- Documentation Site: https://docs.actyze.io

---

**Deploy Actyze on Kubernetes. Scale with confidence. Query with ease.**
