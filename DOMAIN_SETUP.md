# Domain Setup for demo.actyze.ai

This guide helps you set up the production domain for Actyze Dashboard.

## Current Configuration

- **Domain:** `demo.actyze.ai`
- **Frontend:** `https://demo.actyze.ai/`
- **API:** `https://demo.actyze.ai/api`
- **SSL:** Automatic via cert-manager + Let's Encrypt

---

## Prerequisites

1. **DNS Access** - Ability to create A/CNAME records for `actyze.ai`
2. **Kubernetes Cluster** - Running cluster with Nginx Ingress Controller
3. **cert-manager** - For automatic SSL certificate generation

---

## Step 1: Install cert-manager

If not already installed:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Verify installation
kubectl get pods -n cert-manager

# Should show:
# cert-manager-xxxxxx-xxxx        1/1     Running
# cert-manager-cainjector-xxxxx   1/1     Running
# cert-manager-webhook-xxxxx      1/1     Running
```

---

## Step 2: Create Let's Encrypt ClusterIssuer

```yaml
# Save as letsencrypt-prod.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # Production Let's Encrypt server
    server: https://acme-v02.api.letsencrypt.org/directory
    
    # Your email for certificate expiration notifications
    email: admin@actyze.ai  # 👈 CHANGE THIS
    
    # Secret to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod
    
    # HTTP-01 challenge solver
    solvers:
    - http01:
        ingress:
          class: nginx
```

Apply it:
```bash
kubectl apply -f letsencrypt-prod.yaml

# Verify
kubectl get clusterissuer
# NAME                READY   AGE
# letsencrypt-prod    True    10s
```

---

## Step 3: Get Your Ingress IP/Hostname

```bash
# Get the external IP/hostname of your ingress controller
kubectl get svc -n ingress-nginx

# Example output:
# NAME                    TYPE           EXTERNAL-IP      PORT(S)
# ingress-nginx-controller LoadBalancer  34.123.45.67    80:30080/TCP,443:30443/TCP
```

**Note the EXTERNAL-IP** (e.g., `34.123.45.67` or `a1b2c3.us-west-2.elb.amazonaws.com`)

---

## Step 4: Configure DNS

Create an A record (or CNAME) pointing to your ingress:

### Option A: A Record (for IP addresses)

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | demo | 34.123.45.67 | 300 |

### Option B: CNAME Record (for ELB/ALB hostnames)

| Type | Name | Value | TTL |
|------|------|-------|-----|
| CNAME | demo | a1b2c3.us-west-2.elb.amazonaws.com | 300 |

**Verify DNS propagation:**
```bash
# Check DNS resolution
nslookup demo.actyze.ai

# Or use dig
dig demo.actyze.ai +short

# Should return your ingress IP
```

---

## Step 5: Deploy Dashboard

```bash
# Deploy with Helm
helm upgrade --install dashboard ./dashboard \
  -f dashboard/values.yaml \
  -f dashboard/values-secrets.yaml \
  -n dashboard \
  --create-namespace

# Watch certificate creation
kubectl get certificate -n dashboard -w

# Expected output:
# NAME                  READY   SECRET                AGE
# demo-actyze-ai-tls   True    demo-actyze-ai-tls   30s
```

---

## Step 6: Verify SSL Certificate

```bash
# Check certificate status
kubectl describe certificate demo-actyze-ai-tls -n dashboard

# Test HTTPS access
curl -I https://demo.actyze.ai

# Should return:
# HTTP/2 200
# strict-transport-security: max-age=31536000; includeSubDomains
# x-robots-tag: noindex, nofollow, noarchive, nosnippet
```

---

## Troubleshooting

### Issue: Certificate not issuing

**Check cert-manager logs:**
```bash
kubectl logs -n cert-manager deployment/cert-manager
```

**Check certificate events:**
```bash
kubectl describe certificate demo-actyze-ai-tls -n dashboard
kubectl describe certificaterequest -n dashboard
```

**Common causes:**
- DNS not pointing to ingress IP
- Port 80 not accessible (required for HTTP-01 challenge)
- Rate limit hit (Let's Encrypt: 5 certificates per week per domain)

**Solution:**
```bash
# Delete and retry
kubectl delete certificate demo-actyze-ai-tls -n dashboard
helm upgrade dashboard ./dashboard -f dashboard/values.yaml -f dashboard/values-secrets.yaml -n dashboard
```

---

### Issue: "default backend - 404"

**Check ingress controller:**
```bash
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

**Verify ingress:**
```bash
kubectl get ingress -n dashboard
kubectl describe ingress -n dashboard
```

---

### Issue: SSL redirect loop

**Check if both ingress and nginx have SSL redirect:**
```yaml
# In values.yaml, ensure:
nginx.ingress.kubernetes.io/ssl-redirect: "true"  # Only at ingress level
```

**Check nginx.conf:**
```bash
kubectl exec -n dashboard deployment/dashboard-frontend -- cat /etc/nginx/nginx.conf
# Should NOT have separate SSL redirect in nginx
```

---

### Issue: Certificate expired or invalid

**Renew certificate:**
```bash
# cert-manager auto-renews 30 days before expiry
# Force renewal:
kubectl delete certificate demo-actyze-ai-tls -n dashboard
# cert-manager will recreate it automatically
```

---

## Testing Checklist

- [ ] DNS resolves to ingress IP: `nslookup demo.actyze.ai`
- [ ] HTTP redirects to HTTPS: `curl -I http://demo.actyze.ai`
- [ ] HTTPS works: `curl -I https://demo.actyze.ai`
- [ ] Certificate is valid: `openssl s_client -connect demo.actyze.ai:443 -servername demo.actyze.ai`
- [ ] Frontend loads: `https://demo.actyze.ai/`
- [ ] API accessible: `https://demo.actyze.ai/api/health`
- [ ] Security headers present: Check for `X-Robots-Tag`, `X-Frame-Options`
- [ ] robots.txt accessible: `https://demo.actyze.ai/robots.txt`

---

## Production Checklist

- [ ] cert-manager installed and ClusterIssuer created
- [ ] DNS A/CNAME record created
- [ ] SSL certificate issued successfully
- [ ] HTTPS working with valid certificate
- [ ] Security headers configured
- [ ] robots.txt blocking crawlers
- [ ] Admin password changed from default
- [ ] Monitoring and alerts configured
- [ ] Backup and disaster recovery plan in place

---

## Accessing the Dashboard

**Production URL:** https://demo.actyze.ai

**Default Credentials:**
- Username: `nexus_admin`
- Password: `admin` ⚠️ **CHANGE THIS IN PRODUCTION!**

**Change admin password:**
```bash
# TODO: Add password change instructions
# For now, update in database or values-secrets.yaml
```

---

## Support

For issues:
1. Check logs: `kubectl logs -n dashboard <pod-name>`
2. Check events: `kubectl get events -n dashboard --sort-by='.lastTimestamp'`
3. Review configuration: `helm get values dashboard -n dashboard`
4. Check cert-manager: `kubectl logs -n cert-manager deployment/cert-manager`

**Useful commands:**
```bash
# Restart all pods
kubectl rollout restart deployment -n dashboard

# Force certificate renewal
kubectl delete certificate demo-actyze-ai-tls -n dashboard

# View ingress configuration
kubectl get ingress dashboard-ingress -n dashboard -o yaml

# Test from inside cluster
kubectl run test-curl --rm -it --image=curlimages/curl -- curl http://dashboard-frontend.dashboard.svc.cluster.local
```
