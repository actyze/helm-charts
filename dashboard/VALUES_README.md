# Actyze Configuration Guide

Complete configuration reference for deploying Actyze on Kubernetes using Helm.

---

## Configuration Files

Actyze uses two configuration files:

1. **`values.yaml`** - Main configuration (resource limits, replicas, features)
2. **`values-secrets.yaml`** - Your secrets (API keys, passwords)

```bash
# Copy the secrets template
cp dashboard/values-secrets.yaml.template dashboard/values-secrets.yaml

# Add your credentials
nano dashboard/values-secrets.yaml

# Deploy with both files
helm install dashboard ./dashboard \
  --namespace actyze \
  --create-namespace \
  --values dashboard/values.yaml \
  --values dashboard/values-secrets.yaml
```

**Important**: Never commit `values-secrets.yaml` to version control.

---

## Quick Configuration

### Step 1: Configure LLM Provider

In `values-secrets.yaml`:

```yaml
secrets:
  externalLLM:
    apiKey: "your-llm-api-key"
```

In `values.yaml`:

```yaml
modelStrategy:
  externalLLM:
    enabled: true
    provider: "anthropic"  # anthropic, openai, perplexity, groq
    model: "claude-sonnet-4-20250514"
    baseUrl: "https://api.anthropic.com/v1/messages"
```

### Step 2: Configure Database Password

In `values-secrets.yaml`:

```yaml
secrets:
  postgres:
    password: "your-secure-password"
```

### Step 3: Deploy

```bash
helm install dashboard ./dashboard \
  --namespace actyze \
  --create-namespace \
  --values dashboard/values.yaml \
  --values dashboard/values-secrets.yaml \
  --wait
```

---

## LLM Provider Configuration

Configure your AI provider in `values.yaml`. Actyze supports multiple providers.

### Anthropic Claude (Recommended)

```yaml
modelStrategy:
  externalLLM:
    enabled: true
    provider: "anthropic"
    model: "claude-sonnet-4-20250514"
    baseUrl: "https://api.anthropic.com/v1/messages"
    authType: "x-api-key"
    extraHeaders: '{"anthropic-version": "2023-06-01"}'
    maxTokens: 4096
    temperature: 0.1
```

Add API key in `values-secrets.yaml`:
```yaml
secrets:
  externalLLM:
    apiKey: "sk-ant-xxxxx"
```

### OpenAI

```yaml
modelStrategy:
  externalLLM:
    enabled: true
    provider: "openai"
    model: "gpt-4o"
    baseUrl: "https://api.openai.com/v1/chat/completions"
    authType: "bearer"
```

Add API key in `values-secrets.yaml`:
```yaml
secrets:
  externalLLM:
    apiKey: "sk-xxxxx"
```

### Perplexity AI

```yaml
modelStrategy:
  externalLLM:
    enabled: true
    provider: "perplexity"
    model: "sonar-reasoning-pro"
    baseUrl: "https://api.perplexity.ai/chat/completions"
    authType: "bearer"
```

### Groq (Free Tier Available)

```yaml
modelStrategy:
  externalLLM:
    enabled: true
    provider: "groq"
    model: "mixtral-8x7b-32768"
    baseUrl: "https://api.groq.com/openai/v1/chat/completions"
    authType: "bearer"
```

### Azure OpenAI

```yaml
modelStrategy:
  externalLLM:
    enabled: true
    provider: "azure"
    model: "gpt-4"
    baseUrl: "https://your-resource.openai.azure.com/openai/deployments/your-deployment/chat/completions?api-version=2024-02-15-preview"
    authType: "api-key"
```

See [LLM_PROVIDERS.md](LLM_PROVIDERS.md) for complete provider configurations.

---

## Resource Configuration

Choose a resource tier that matches your deployment needs:

### Recommended Production (Standard)

Best for most production deployments (hundreds of users):

```yaml
# Trino - Distributed SQL queries
trino:
  resources:
    requests:
      memory: "12Gi"
      cpu: "6000m"
    limits:
      memory: "16Gi"
      cpu: "8000m"
  jvmHeapSize: "10G"

# Schema Service - AI recommendations
schemaService:
  resources:
    requests:
      memory: "6Gi"
      cpu: "4000m"
    limits:
      memory: "8Gi"
      cpu: "6000m"

# Nexus - API orchestration
nexus:
  replicaCount: 3
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"

# Frontend
frontend:
  replicaCount: 2
  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
    limits:
      memory: "512Mi"
      cpu: "500m"

# PostgreSQL
postgres:
  resources:
    requests:
      memory: "2Gi"
      cpu: "1000m"
    limits:
      memory: "4Gi"
      cpu: "2000m"
```

**Cluster Requirements**: 4-5 nodes × 8 CPU × 16Gi RAM

### Enterprise (Maximum Performance)

For large organizations with high concurrency:

```yaml
trino:
  resources:
    requests:
      memory: "24Gi"
      cpu: "12000m"
    limits:
      memory: "32Gi"
      cpu: "16000m"
  jvmHeapSize: "20G"

schemaService:
  resources:
    requests:
      memory: "12Gi"
      cpu: "8000m"
    limits:
      memory: "16Gi"
      cpu: "12000m"

nexus:
  replicaCount: 5
  resources:
    requests:
      memory: "2Gi"
      cpu: "1000m"
    limits:
      memory: "4Gi"
      cpu: "2000m"
```

**Cluster Requirements**: 4-5 nodes × 16 CPU × 32Gi RAM

### Minimum (Development/Testing)

For evaluation and testing only:

```yaml
trino:
  resources:
    requests:
      memory: "4Gi"
      cpu: "2000m"
    limits:
      memory: "6Gi"
      cpu: "4000m"
  jvmHeapSize: "3G"

schemaService:
  resources:
    requests:
      memory: "2Gi"
      cpu: "1000m"
    limits:
      memory: "4Gi"
      cpu: "2000m"

nexus:
  replicaCount: 1
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "500m"
```

**Cluster Requirements**: 2-3 nodes × 4 CPU × 8Gi RAM

---

## Auto-Scaling Configuration

Enable automatic scaling based on CPU/memory usage:

```yaml
nexus:
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80

frontend:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 5
    targetCPUUtilizationPercentage: 70
```

---

## Performance Tuning

### Cache Configuration

Improve query performance with caching:

```yaml
cache:
  # Query result caching
  query:
    enabled: true
    maxSize: 500
    ttl: 3600  # 1 hour
  
  # LLM response caching
  llm:
    enabled: true
    maxSize: 200
    ttl: 7200  # 2 hours
  
  # Schema metadata caching
  schema:
    enabled: true
    maxSize: 100
    ttl: 1800  # 30 minutes
  
  # Data discovery caching
  metadata:
    enabled: true
    maxSize: 100
    ttl: 3600  # 1 hour
```

### Timeout Configuration

Configure timeouts for different operations:

```yaml
timeouts:
  # SQL execution timeout
  sqlExecution: 300  # 5 minutes
  
  # LLM API call timeout
  llmApi: 60  # 1 minute
  
  # Trino query timeout
  trino: 600  # 10 minutes
  
  # Ingress timeout
  ingress:
    connect: 60
    send: 600
    read: 600
```

### Database Connection Pools

Optimize database connections:

```yaml
database:
  pool:
    size: 20
    maxOverflow: 10
    timeout: 30
    recycle: 3600
```

### Rate Limiting

Protect your deployment from overload:

```yaml
rateLimiting:
  # Ingress level
  ingress:
    enabled: true
    requestsPerSecond: 100
  
  # Application level
  api:
    enabled: true
    requestsPerMinute: 1000
  
  # LLM API calls
  llm:
    enabled: true
    requestsPerMinute: 60
```

### Query Limits

Control query result sizes:

```yaml
queryLimits:
  defaultRows: 1000
  maxRows: 10000
```

### File Upload Limits

Configure CSV/Excel upload limits:

```yaml
fileUpload:
  maxSize: "50MB"
  allowedExtensions: ["csv", "xlsx", "xls"]
  maxRows: 100000
```

---

## Ingress Configuration

### Basic Ingress Setup

```yaml
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: analytics.yourcompany.com
      paths:
        - path: /
          pathType: Prefix
          service: frontend
        - path: /api
          pathType: Prefix
          service: nexus
```

### SSL/TLS with cert-manager

Automatic HTTPS certificates:

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
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
```

**Prerequisites**: Install cert-manager first:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

### Cloud Provider Ingress

**AWS (Application Load Balancer):**

```yaml
ingress:
  className: "alb"
  annotations:
    alb.ingress.kubernetes.io/scheme: "internet-facing"
    alb.ingress.kubernetes.io/target-type: "ip"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:region:account:certificate/xxxxx"
```

**Google Cloud (GCE):**

```yaml
ingress:
  className: "gce"
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "actyze-ip"
    networking.gke.io/managed-certificates: "actyze-cert"
```

**Azure (Application Gateway):**

```yaml
ingress:
  className: "azure/application-gateway"
  annotations:
    appgw.ingress.kubernetes.io/ssl-redirect: "true"
```

---

## Database Connection Configuration

### Connect to Your Data Sources

Configure Trino to connect to your databases:

```yaml
trino:
  catalogs:
    # PostgreSQL
    production_db:
      connector.name: postgresql
      connection-url: jdbc:postgresql://db.yourcompany.com:5432/production
      connection-user: analytics_user
      connection-password: ${TRINO_POSTGRES_PASSWORD}
    
    # MySQL
    sales_db:
      connector.name: mysql
      connection-url: jdbc:mysql://mysql.yourcompany.com:3306/sales
      connection-user: analytics_user
      connection-password: ${TRINO_MYSQL_PASSWORD}
    
    # Snowflake
    warehouse:
      connector.name: snowflake
      snowflake.account: your-account
      snowflake.user: analytics_user
      snowflake.password: ${TRINO_SNOWFLAKE_PASSWORD}
      snowflake.database: ANALYTICS
      snowflake.role: ANALYTICS_ROLE
    
    # MongoDB
    events_db:
      connector.name: mongodb
      mongodb.connection-url: mongodb://mongo.yourcompany.com:27017
      mongodb.credentials: analytics_user:${TRINO_MONGO_PASSWORD}@admin
```

**Add passwords** in `values-secrets.yaml`:
```yaml
secrets:
  trino:
    postgresPassword: "your-password"
    mysqlPassword: "your-password"
    snowflakePassword: "your-password"
    mongoPassword: "your-password"
```

---

## Storage Configuration

### PostgreSQL Storage

```yaml
postgres:
  persistence:
    enabled: true
    storageClass: "standard"  # Or your cloud provider's storage class
    size: "50Gi"
```

### Trino Storage (for Iceberg/Hive)

```yaml
trino:
  persistence:
    enabled: true
    storageClass: "standard"
    size: "100Gi"
```

**Cloud Provider Storage Classes:**
- AWS: `gp3`, `gp2`, `io1`
- GCP: `standard`, `ssd`
- Azure: `managed-premium`, `default`

---

## Security Configuration

### Enable SSL/TLS

```yaml
ingress:
  tls:
    - secretName: actyze-tls
      hosts:
        - analytics.yourcompany.com
```

### Use Kubernetes Secrets

Store sensitive data in Kubernetes secrets:

```bash
# Create secret for LLM API key
kubectl create secret generic actyze-llm \
  --from-literal=apiKey=your-api-key \
  -n actyze

# Create secret for database passwords
kubectl create secret generic actyze-db \
  --from-literal=postgres-password=your-password \
  -n actyze
```

Reference in `values.yaml`:
```yaml
secrets:
  useExistingSecret: true
  existingSecretName: "actyze-llm"
```

---

## Accessing Actyze

### Via Ingress (Production)

Access at your configured domain:
```
https://analytics.yourcompany.com
```

### Via Port-Forwarding (Testing)

For testing without Ingress:

```bash
# Forward frontend
kubectl port-forward -n actyze svc/dashboard-frontend 3000:80
# Access: http://localhost:3000

# Forward API
kubectl port-forward -n actyze svc/dashboard-nexus 8002:8002
# Access: http://localhost:8002/docs
```

---

## Upgrading Actyze

### Update Configuration

```bash
# Pull latest chart updates
git pull

# Upgrade deployment
helm upgrade dashboard ./dashboard \
  --namespace actyze \
  --values dashboard/values.yaml \
  --values dashboard/values-secrets.yaml
```

### Update Images

Images automatically update with `pullPolicy: Always`:

```bash
# Restart services to pull latest images
kubectl rollout restart deployment -n actyze

# Or restart specific services
kubectl rollout restart deployment/dashboard-nexus -n actyze
kubectl rollout restart deployment/dashboard-frontend -n actyze
```

---

## Troubleshooting

### Check Deployment Status

```bash
# View all pods
kubectl get pods -n actyze

# Check pod logs
kubectl logs -f deployment/dashboard-nexus -n actyze
kubectl logs -f deployment/dashboard-frontend -n actyze

# Check resource usage
kubectl top pods -n actyze
```

### Common Issues

**Pods won't start - Insufficient resources:**
```bash
# Check node resources
kubectl describe nodes

# Solution: Scale down replicas or increase cluster size
```

**Image pull errors:**
```bash
# Verify images are public
docker pull actyze/dashboard-nexus:main-llm-flex

# Images are public - no authentication needed
```

**Database connection failed:**
```bash
# Check PostgreSQL logs
kubectl logs dashboard-postgres-0 -n actyze

# Test connection
kubectl exec -it dashboard-postgres-0 -n actyze -- psql -U nexus_service -d dashboard
```

**LLM API errors:**
```bash
# Check Nexus logs
kubectl logs deployment/dashboard-nexus -n actyze | grep -i llm

# Verify API key is configured
kubectl get secret dashboard-external-llm -n actyze -o yaml
```

**Ingress not working:**
```bash
# Check ingress status
kubectl get ingress -n actyze
kubectl describe ingress dashboard-ingress -n actyze

# Verify ingress controller is running
kubectl get pods -n ingress-nginx
```

---

## Support Resources

**Documentation:**
- Complete Guide: https://docs.actyze.io
- Deployment Guide: https://docs.actyze.io/docs/deployment/helm
- LLM Provider Configuration: [LLM_PROVIDERS.md](LLM_PROVIDERS.md)

**Support:**
- GitHub Issues: https://github.com/actyze/helm-charts/issues
- Documentation Site: https://docs.actyze.io

**Related:**
- Docker Compose (Local): https://github.com/actyze/dashboard-docker
- Docker Hub Images: https://hub.docker.com/u/actyze
