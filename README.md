# Actyze Helm Charts

Production-ready Helm charts for deploying Actyze on Kubernetes.

## Overview

Actyze is an AI-powered natural language to SQL analytics platform that enables users to query databases using plain English.

**Components:**
- **Frontend**: React-based web interface
- **Nexus**: FastAPI orchestration service
- **Schema Service**: FAISS-powered schema recommendations with multilingual support (50+ languages)
- **PostgreSQL**: Application database
- **Trino**: Distributed SQL query engine for federated queries

**Image Pull Policy:**
All Actyze images are configured with `pullPolicy: Always` to automatically pull the latest versions from Docker Hub:
- `actyze/dashboard-nexus:main-llm-flex`
- `actyze/dashboard-frontend:latest`
- `actyze/dashboard-schema-service:latest`

## Prerequisites

- **Kubernetes cluster**: v1.24 or higher
- **Helm**: 3.x
- **kubectl**: Configured to access your cluster
- **Resources**: See [Production Requirements](#production-configuration) below

### Recommended Cluster Sizing

**For production deployments:**
- **Standard Production**: 4-5 nodes × 8 CPU × 16Gi RAM (or 3 nodes × 16 CPU × 32Gi RAM)
- **Enterprise**: 4-5 nodes × 16 CPU × 32Gi RAM (or 3 nodes × 32 CPU × 64Gi RAM)
- **Minimum (Dev/Testing)**: 2-3 nodes × 4 CPU × 8Gi RAM

See [Complete Resource Specifications](https://docs.actyze.io/docs/deployment/helm#production-grade-resource-specifications) for detailed requirements per service.

## Quick Start

```bash
# Clone repository
git clone https://github.com/actyze/helm-charts.git
cd helm-charts

# Configure secrets
cp dashboard/values-secrets.yaml.template dashboard/values-secrets.yaml
nano dashboard/values-secrets.yaml
# Add your LLM API key and other secrets

# Install Actyze
helm install dashboard ./dashboard \
  --namespace actyze \
  --create-namespace \
  --values dashboard/values.yaml \
  --values dashboard/values-secrets.yaml \
  --wait
```

## Production Configuration

### Resource Requirements

Actyze provides three production-ready resource tiers:

| Tier | Use Case | Total Resources | Cluster Size |
|------|----------|-----------------|--------------|
| **Minimum** | Dev/Testing | ~4 CPUs, ~7Gi RAM | 2-3 nodes × 4 CPU × 8Gi RAM |
| **Recommended** | Standard Production | ~12 CPUs, ~21Gi RAM | 4-5 nodes × 8 CPU × 16Gi RAM |
| **Enterprise** | Maximum Performance | ~30 CPUs, ~46Gi RAM | 4-5 nodes × 16 CPU × 32Gi RAM |

**Key Services (Recommended Tier):**
- **Trino**: 12Gi RAM, 6 CPUs (distributed SQL queries)
- **Schema Service**: 6Gi RAM, 4 CPUs (CPU-intensive FAISS + spaCy operations)
- **Nexus**: 1Gi RAM, 500m CPU × 3 replicas (orchestration)
- **Frontend**: 256Mi RAM, 200m CPU × 2 replicas
- **PostgreSQL**: 2Gi RAM, 1 CPU

See [Production-Grade Resource Specifications](https://docs.actyze.io/docs/deployment/helm#production-grade-resource-specifications) for:
- Complete YAML examples for each tier
- Cluster size calculators
- Autoscaling configurations
- Storage requirements

### Operational Configuration

Production deployments require proper configuration of:

**Cache Configuration:**
- Query cache (100-500 queries)
- LLM response cache (100-500 responses)
- Schema cache (512Mi-2Gi)
- Metadata cache (256Mi-1Gi)

**Timeout Configuration:**
- SQL execution: 60-300 seconds
- LLM API calls: 60-120 seconds
- Trino queries: 120-600 seconds
- Ingress timeouts: 120-300 seconds

**Connection Pools:**
- 20-50 connections per Nexus replica
- Connection recycling every 1-3 hours
- Proper timeout and overflow settings

**Rate Limiting:**
- Ingress: 100-500 requests/min per IP
- Application: 50-200 requests/min per user
- LLM API: 10-50 calls/min (cost control)

**Retry & Circuit Breaker:**
- Exponential backoff for external services
- Circuit breaker for Schema Service and LLM API
- Trino query retries with proper limits

See [Operational Configuration Guide](https://docs.actyze.io/docs/deployment/helm#operational-configuration) for complete YAML examples and production-ready values.

## Architecture

```
┌─────────────┐
│   Frontend  │  (React + Tailwind)
└──────┬──────┘
       │
┌──────▼──────┐
│    Nexus    │  (FastAPI Orchestration)
└──────┬──────┘
       │
       ├────────────────┬────────────────┐
       │                │                │
┌──────▼──────┐  ┌──────▼──────┐  ┌─────▼─────┐
│   Schema    │  │   Trino     │  │ PostgreSQL│
│   Service   │  │   Engine    │  │           │
└─────────────┘  └──────┬──────┘  └───────────┘
                        │
                 ┌──────▼──────────┐
                 │  Your Databases │
                 │  (PostgreSQL,   │
                 │   MongoDB,      │
                 │   Snowflake,    │
                 │   BigQuery...)  │
                 └─────────────────┘
```

**Architecture Highlights:**
- Frontend communicates with Nexus API
- Nexus orchestrates Schema Service, Trino, and PostgreSQL
- Schema Service uses FAISS for intelligent table recommendations
- Trino federates queries across multiple data sources
- PostgreSQL stores application metadata and user data

## Documentation

- **[Complete Helm Guide](https://docs.actyze.io/docs/deployment/helm)** - Comprehensive deployment reference
- **[Getting Started](https://docs.actyze.io/docs/getting-started/helm-setup)** - Step-by-step setup guide
- **[VALUES_README.md](dashboard/VALUES_README.md)** - Configuration reference
- **[LLM_PROVIDERS.md](dashboard/LLM_PROVIDERS.md)** - LLM provider setup
- **[MIGRATIONS_README.md](dashboard/MIGRATIONS_README.md)** - Database migrations
- **[Features Guide](https://docs.actyze.io/docs/features/overview)** - Platform features

## Configuration

### AI Provider Setup

Connect Actyze to your preferred AI provider with simple configuration.

**Direct Connection** (Recommended for most organizations)

```yaml
# values.yaml
modelStrategy:
  externalLLM:
    enabled: true
    model: "claude-sonnet-4-20250514"  # or gpt-4, gemini/gemini-pro, etc.

# values-secrets.yaml
secrets:
  externalLLM:
    apiKey: "sk-ant-xxxxx"  # Provider-specific API key
```

**Enterprise Gateway** (For IT-managed AI access)

```yaml
# values.yaml
modelStrategy:
  externalLLM:
    enabled: true
    mode: "openai-compatible"
    model: "your-internal-model"
    baseUrl: "https://llm-gateway.company.com/v1/chat/completions"
    authType: "bearer"
    extraHeaders: '{"X-Department": "engineering"}'

# values-secrets.yaml
secrets:
  externalLLM:
    apiKey: "your-enterprise-token"
```

**Popular AI Providers:**
- **Anthropic Claude (Recommended)** - Best for most users with excellent SQL accuracy
- **OpenAI GPT-4** - Best for enterprises already using OpenAI services
- **Google Gemini** - Best for cost-conscious users needing fast responses
- **AWS Bedrock** - Best for organizations on AWS infrastructure
- **Azure OpenAI** - Best for Microsoft Azure customers with compliance requirements
- **Perplexity, Groq, and 90+ more**

**Benefits:**
- ✅ **No Vendor Lock-in** - Switch providers anytime
- ✅ **Simple Setup** - Just 2 configuration settings
- ✅ **Use What You Have** - Works with existing accounts
- ✅ **Enterprise Ready** - Connect through your company gateway
- ✅ **Cost Transparency** - Track usage and spending

See [LLM Provider Configuration](https://docs.actyze.io/docs/configuration/llm-providers) for detailed provider-specific examples and enterprise integration.

### Database Connectors (Trino Catalogs)

Configure Trino catalogs in `values.yaml` to connect to your data sources:

```yaml
trino:
  catalogs:
    postgres:
      connector.name: postgresql
      connection-url: jdbc:postgresql://your-host:5432/database
      connection-user: your-user
      connection-password: your-password
    
    snowflake:
      connector.name: snowflake
      snowflake.account: your-account
      snowflake.user: your-user
      snowflake.password: your-password
```

**Supported Data Sources:**
- Relational: PostgreSQL, MySQL, SQL Server, Oracle, MariaDB
- Cloud Data Warehouses: Snowflake, Databricks, BigQuery, Redshift
- NoSQL: MongoDB, Cassandra, Elasticsearch
- Data Lakes: Iceberg, Delta Lake, Hudi, Hive

See [Database Connectors Guide](https://docs.actyze.io/docs/features/database-connectors) for configuration examples.

### Ingress Configuration

Configure ingress for external access:

```yaml
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
```

## Development

### Testing Charts Locally

```bash
# Lint the chart
helm lint ./dashboard

# Dry run to see what will be deployed
helm install dashboard ./dashboard \
  --dry-run --debug \
  --values dashboard/values.yaml \
  --values dashboard/values-secrets.yaml

# Template the chart to see rendered manifests
helm template dashboard ./dashboard \
  --values dashboard/values.yaml \
  --values dashboard/values-secrets.yaml > output.yaml
```

### Upgrading Charts

```bash
# Upgrade an existing release
helm upgrade dashboard ./dashboard \
  --namespace actyze \
  --values dashboard/values.yaml \
  --values dashboard/values-secrets.yaml

# Check upgrade status
helm status dashboard --namespace actyze

# Rollback if needed
helm rollback dashboard --namespace actyze
```

## Management

### Common Operations

```bash
# Check deployment status
helm list --namespace actyze
kubectl get pods --namespace actyze

# View logs
kubectl logs -f deployment/dashboard-nexus --namespace actyze
kubectl logs -f deployment/dashboard-schema-service --namespace actyze

# Update images (with pullPolicy: Always, just restart)
kubectl rollout restart deployment/dashboard-nexus --namespace actyze
kubectl rollout restart deployment/dashboard-frontend --namespace actyze
kubectl rollout restart deployment/dashboard-schema-service --namespace actyze

# Scale services
kubectl scale deployment/dashboard-nexus --replicas=5 --namespace actyze

# Access services directly (for debugging)
kubectl port-forward svc/dashboard-frontend 3000:80 --namespace actyze
kubectl port-forward svc/dashboard-nexus 8002:8002 --namespace actyze
```

### Uninstall

```bash
# Uninstall Actyze (preserves PVCs)
helm uninstall dashboard --namespace actyze

# Delete PVCs if needed
kubectl delete pvc --all --namespace actyze

# Delete namespace
kubectl delete namespace actyze
```

## Features

**Core Capabilities:**
- Natural Language to SQL conversion using LLMs
- Multilingual support (50+ languages via sentence-transformers)
- FAISS-based intelligent schema recommendations
- CSV/Excel file upload for ad-hoc analysis
- Role-Based Access Control (Admin, User, Read-Only)
- Schema boosting (user-defined table preferences)
- Organization-level metadata descriptions
- Query caching for performance and cost optimization
- Multi-database federation via Trino

See [Features Overview](https://docs.actyze.io/docs/features/overview) for detailed descriptions.

## Support

- **Documentation**: https://docs.actyze.io
- **GitHub Issues**: https://github.com/actyze/helm-charts/issues
- **Docker Hub**: https://hub.docker.com/u/actyze
- **Main Project**: https://github.com/actyze/dashboard-docker

## Related Repositories

- **Dashboard Docker**: https://github.com/actyze/dashboard-docker (Local development)
- **Documentation**: https://github.com/actyze/dashboard-marketing (Documentation site)

## License

Proprietary - Actyze Analytics Platform

---

**Built for production. Optimized for performance. Ready to scale.**
