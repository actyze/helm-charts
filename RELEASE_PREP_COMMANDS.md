# Release prep commands — actyze/helm-charts

Run these after the polish PR is merged. Each is reversible.

```bash
# Set repo description (currently empty on github.com)
gh repo edit actyze/helm-charts \
  --description "Production-ready Helm charts for Actyze — open-source self-hosted AI analytics. NL→SQL, federated queries via Trino, ML predictions, AGPL v3."

# Set homepage
gh repo edit actyze/helm-charts --homepage "https://docs.actyze.io/docs/deployment/helm"

# Add GitHub topics (currently empty — kills discovery)
gh repo edit actyze/helm-charts \
  --add-topic helm \
  --add-topic helm-charts \
  --add-topic kubernetes \
  --add-topic k8s \
  --add-topic actyze \
  --add-topic ai-analytics \
  --add-topic self-hosted \
  --add-topic trino \
  --add-topic federated-query \
  --add-topic agpl \
  --add-topic llm \
  --add-topic text-to-sql
```

## Notes

- Topics drive GitHub search visibility — empty topics = invisible to anyone browsing Helm or Kubernetes ecosystem tags.
- Coordinate version pinning with `actyze/dashboard` releases. When `dashboard` tags v0.1.0, this chart should tag a compatible version too (e.g., v0.1.0 or chart-0.1.0).
- Consider publishing the chart to a Helm registry (GitHub Pages or OCI on GHCR) so users can `helm repo add` instead of cloning.
