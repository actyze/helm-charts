# Actyze Helm Charts

This repository contains Helm charts for deploying Actyze applications on Kubernetes.

## Available Charts

### Dashboard Chart (`dashboard/`)

AI-powered analytics dashboard with Natural Language to SQL capabilities.

**Components:**
- **Frontend**: React-based web interface
- **Nexus**: FastAPI orchestration service (Python)
- **Schema Service**: FAISS-powered schema recommendation service
- **PostgreSQL**: Primary database
- **Trino**: Distributed SQL query engine

## Installation

### Prerequisites

- Kubernetes cluster (v1.24+)
- Helm 3.x installed
- `kubectl` configured to access your cluster

### Quick Start

```bash
# Add the repository (if using a Helm repository)
helm repo add actyze https://actyze.github.io/helm-charts
helm repo update

# Install the dashboard chart
helm install my-dashboard actyze/dashboard \
  --namespace actyze \
  --create-namespace \
  --values custom-values.yaml
```

### Local Installation

```bash
# Clone this repository
git clone https://github.com/actyze/helm-charts.git
cd helm-charts

# Install from local chart
helm install my-dashboard ./dashboard \
  --namespace actyze \
  --create-namespace \
  --values dashboard/values.yaml \
  --values dashboard/values-secrets.yaml
```

## Configuration

### Dashboard Chart

See [dashboard/VALUES_README.md](dashboard/VALUES_README.md) for detailed configuration options.

**Key configuration files:**
- `values.yaml` - Main configuration (works for all environments)
- `values-secrets.yaml.template` - Secrets template
- `values-secrets.yaml` - Your actual secrets (gitignored, not committed)

### Minimal Configuration

```yaml
# custom-values.yaml
services:
  frontend:
    enabled: true
  nexus:
    enabled: true
  schemaService:
    enabled: true
  postgres:
    enabled: true
  trino:
    enabled: true

ingress:
  enabled: true
  host: dashboard.example.com
```

## Development

### Testing Charts Locally

```bash
# Lint the chart
helm lint ./dashboard

# Dry run to see what will be deployed
helm install my-dashboard ./dashboard \
  --dry-run --debug \
  --values dashboard/values.yaml \
  --values dashboard/values-secrets.yaml

# Template the chart to see rendered manifests
helm template my-dashboard ./dashboard \
  --values dashboard/values.yaml \
  --values dashboard/values-secrets.yaml > output.yaml
```

### Upgrading Charts

```bash
# Upgrade an existing release
helm upgrade my-dashboard ./dashboard \
  --namespace actyze \
  --values custom-values.yaml

# Rollback if needed
helm rollback my-dashboard 1 --namespace actyze
```

## Documentation

- **Deployment Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Schema Reference**: [dashboard/SCHEMA_REFERENCE.md](dashboard/SCHEMA_REFERENCE.md)
- **Migration Guide**: [dashboard/MIGRATIONS_README.md](dashboard/MIGRATIONS_README.md)
- **Values Reference**: [dashboard/VALUES_README.md](dashboard/VALUES_README.md)

## Architecture

```
┌─────────────┐
│   Frontend  │  (React + Tailwind)
│   :3000     │
└──────┬──────┘
       │
┌──────▼──────┐
│    Nexus    │  (FastAPI Orchestration)
│    :8000    │
└──────┬──────┘
       │
       ├────────────────┬────────────────┐
       │                │                │
┌──────▼──────┐  ┌──────▼──────┐  ┌─────▼─────┐
│   Schema    │  │   Trino     │  │ PostgreSQL│
│   Service   │  │   :8080     │  │   :5432   │
│   :8001     │  └─────────────┘  └───────────┘
└─────────────┘
```

## Support

For issues, questions, or contributions, please open an issue in this repository or contact the Actyze team.

## License

Proprietary - Actyze Analytics Platform

