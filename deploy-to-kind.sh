#!/bin/bash
set -e

echo "🚀 Actyze Dashboard - Kind Cluster Deployment Script"
echo "===================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Stop Docker Compose
echo "📦 Step 1: Stopping Docker Compose services..."
cd "/Users/rohitmangal/Documents/Actyze Content/dashboard"
docker compose --profile local down 2>/dev/null || echo "No Docker Compose services running"
echo -e "${GREEN}✅ Docker Compose services stopped${NC}"
echo ""

# Step 2: Check/Start Kind Cluster
echo "🔍 Step 2: Checking Kind cluster..."
if kind get clusters 2>&1 | grep -q "dashboard"; then
    echo -e "${GREEN}✅ Kind cluster 'dashboard' already exists${NC}"
else
    echo -e "${YELLOW}⚠️  No Kind cluster found. Creating new cluster 'dashboard'...${NC}"
    cat <<EOF | kind create cluster --name dashboard --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 30000
    hostPort: 3000
    protocol: TCP
  - containerPort: 30001
    hostPort: 8000
    protocol: TCP
EOF
    echo -e "${GREEN}✅ Kind cluster created${NC}"
fi

# Set kubectl context
kubectl cluster-info --context kind-dashboard
echo ""

# Step 3: Install Nginx Ingress Controller
echo "🌐 Step 3: Installing Nginx Ingress Controller..."
if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Nginx Ingress already installed${NC}"
else
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    echo "Waiting for Ingress Controller to be ready..."
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=90s || echo "Warning: Ingress controller may not be fully ready yet"
    echo -e "${GREEN}✅ Nginx Ingress installed${NC}"
fi
echo ""

# Step 4: Load Docker Images to Kind (Optional - for local images)
echo "🐳 Step 4: Checking for local Docker images..."
if docker images | grep -q "dashboard-"; then
    echo -e "${YELLOW}Found local images. Loading into Kind cluster...${NC}"
    docker images --format "{{.Repository}}:{{.Tag}}" | grep "^dashboard-" | while read image; do
        echo "  Loading: $image"
        kind load docker-image "$image" --name dashboard 2>/dev/null || echo "  (already loaded or not available)"
    done
    echo -e "${GREEN}✅ Local images loaded (if any)${NC}"
else
    echo -e "${YELLOW}⚠️  No local images found. Will pull from DockerHub (actyze/*)${NC}"
fi
echo ""

# Step 5: Deploy with Helm
echo "⎈ Step 5: Deploying dashboard with Helm..."
cd "/Users/rohitmangal/Documents/Actyze Content/helm-charts"

# Check if values-secrets.yaml exists
if [ ! -f "dashboard/values-secrets.yaml" ]; then
    echo -e "${RED}❌ ERROR: dashboard/values-secrets.yaml not found${NC}"
    echo "Please create it from the template:"
    echo "  cp dashboard/values-secrets.yaml.template dashboard/values-secrets.yaml"
    echo "  # Edit the file with your actual secrets"
    exit 1
fi

# Deploy or upgrade
helm upgrade --install dashboard ./dashboard \
  --namespace dashboard \
  --create-namespace \
  --values dashboard/values.yaml \
  --values dashboard/values-secrets.yaml \
  --timeout 15m \
  --wait

echo -e "${GREEN}✅ Helm deployment complete${NC}"
echo ""

# Step 6: Wait for pods to be ready
echo "⏳ Step 6: Waiting for pods to be ready..."
echo "This may take 5-10 minutes for initial deployment..."
kubectl wait --for=condition=ready pod \
  --all \
  --namespace=dashboard \
  --timeout=600s || echo "Some pods may still be starting..."
echo ""

# Step 7: Show deployment status
echo "📊 Step 7: Deployment Status"
echo "============================"
kubectl get pods -n dashboard
echo ""
kubectl get svc -n dashboard
echo ""

# Step 8: Port forwarding instructions
echo ""
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "======================="
echo ""
echo "Access the application:"
echo ""
echo "  Frontend:"
echo "    kubectl port-forward -n dashboard svc/dashboard-frontend 3000:3000"
echo "    Then open: http://localhost:3000"
echo ""
echo "  Nexus API:"
echo "    kubectl port-forward -n dashboard svc/dashboard-nexus 8000:8002"
echo "    Then open: http://localhost:8000"
echo ""
echo "  Or use NodePort (if configured):"
echo "    http://localhost:30000 (Frontend)"
echo "    http://localhost:30001 (Nexus API)"
echo ""
echo "Useful commands:"
echo "  - View logs: kubectl logs -f <pod-name> -n dashboard"
echo "  - Check status: kubectl get all -n dashboard"
echo "  - Restart deployment: kubectl rollout restart deployment/<name> -n dashboard"
echo "  - Delete deployment: helm uninstall dashboard -n dashboard"
echo ""

