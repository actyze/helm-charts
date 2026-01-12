# Dashboard Deployment Guide

> **Note:** All commands in this guide should be executed from the project root directory.

## 🚀 Quick Start

### **Development Deployment**

1. **Create your secrets file:**
   ```bash
   cp helm/dashboard/values-secrets.yaml.template helm/dashboard/values-secrets.yaml
   # Edit values-secrets.yaml with your actual:
   # - External LLM API key
   # - Trino credentials (username/password)
   # - Trino connection details (host/catalog/schema)
   # - PostgreSQL database password
   ```

2. **Deploy with Helm:**
   ```bash
   helm upgrade --install dashboard ./helm/dashboard \
     --namespace dashboard \
     --create-namespace \
     -f helm/dashboard/values.yaml \
     -f helm/dashboard/values-secrets.yaml \
     --wait
   ```

3. **Access the application:**
   ```bash
   kubectl port-forward -n dashboard svc/dashboard-frontend 3000:3000
   kubectl port-forward -n dashboard svc/dashboard-nexus 8000:8000
   ```

### **Production Deployment**

1. **Create your production secrets file:**
   ```bash
   cp helm/dashboard/values-secrets.yaml.template helm/dashboard/values-secrets.yaml
   # Edit values-secrets.yaml with your production credentials
   ```

2. **Deploy with production values:**
   ```bash
   helm upgrade --install dashboard ./helm/dashboard \
     --namespace dashboard \
     --create-namespace \
     -f helm/dashboard/values.yaml \
     -f helm/dashboard/values-secrets.yaml \
     --wait
   ```

## 📋 File Structure

```
helm/dashboard/
├── values.yaml                        # ✅ Safe to commit - no secrets (works for all environments)
├── values-secrets.yaml                # ❌ NOT in Git - your actual secrets
├── values-secrets.yaml.template       # ✅ Template for other developers
└── templates/secrets.yaml             # ✅ Helm template for Kubernetes secrets
```

## 🔐 Secret Management

### **Values-Based Approach (All Environments)**
- Secrets stored in `values-*-secrets.yaml` files (not committed to Git)
- Helm creates Kubernetes secrets from values
- Consistent approach for development and production
- Simple and secure

## 🛠️ Useful Commands

```bash
# Check deployment status
kubectl get pods -n dashboard

# View logs
kubectl logs -n dashboard -l app.kubernetes.io/name=dashboard

# Update secrets and restart
# Edit values-secrets.yaml, then:
helm upgrade dashboard ./helm/dashboard \
  -f helm/dashboard/values.yaml \
  -f helm/dashboard/values-secrets.yaml

# Uninstall
helm uninstall dashboard -n dashboard
```

## ⚠️ Security Notes

- ✅ **values.yaml** is safe to commit - contains no secrets
- ❌ **values-secrets.yaml** is in .gitignore - never commit this file
- 🔒 All secrets are stored as Kubernetes secrets, not in plain text
- 🔄 Use the template file (values-secrets.yaml.template) to help other developers set up their secrets
