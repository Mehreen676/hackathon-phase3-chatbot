# Kubernetes Deployment Guide for Todo AI Chatbot

This guide explains how to deploy the Todo AI Chatbot application to a Kubernetes cluster using Helm charts.

## Prerequisites

- Kubernetes cluster (tested with Minikube)
- Helm 3.x installed
- kubectl configured to connect to your cluster
- Docker daemon running (for building images)

## Setup Instructions

### 1. Start Minikube (if using local cluster)

```bash
minikube start
```

### 2. Enable Ingress addon (if using ingress)

```bash
minikube addons enable ingress
```

### 3. Build Docker Images

First, build the Docker images for each component:

```bash
# Navigate to the project root directory
cd C:\Users\Lenovo\Desktop\phase-04\hackathon-phase3-chatbot

# Build frontend image
docker build -t todo-ai-frontend:latest frontend/

# Build backend image
docker build -t todo-ai-backend:latest backend/

# Build MCP server image
docker build -t todo-ai-mcp:latest mcp/
```

If using Minikube, load the images into the cluster:

```bash
# Load images into minikube
eval $(minikube docker-env)
docker build -t todo-ai-frontend:latest frontend/
docker build -t todo-ai-backend:latest backend/
docker build -t todo-ai-mcp:latest mcp/
```

### 4. Create Kubernetes Secrets

Create a Kubernetes secret containing your sensitive configuration:

```bash
kubectl create secret generic todo-ai-secrets \
  --from-literal=openai-api-key="YOUR_OPENAI_API_KEY_HERE" \
  --from-literal=database-url="YOUR_DATABASE_URL_HERE"
```

### 5. Deploy Using Helm

Navigate to the helm directory and install the chart:

```bash
cd helm

# Install the chart
helm install todo-ai . \
  --set frontend.env.NEXT_PUBLIC_API_BASE_URL="http://todo-ai.local/api" \
  --set backend.env.ALLOWED_ORIGINS="*"
```

### 6. Verify Installation

Check if all pods are running:

```bash
kubectl get pods
```

Check the services:

```bash
kubectl get svc
```

Check the ingress (if enabled):

```bash
kubectl get ingress
```

### 7. Access the Application

If using Minikube with ingress:

```bash
minikube tunnel
```

Then access the application at `http://todo-ai.local` (or the host specified in values.yaml)

If ingress is not available, you can port-forward to access the services:

```bash
# Port forward to frontend
kubectl port-forward svc/todo-ai-frontend 3000:3000

# Port forward to backend
kubectl port-forward svc/todo-ai-backend 7860:7860
```

## Customization

You can customize the deployment by modifying the `values.yaml` file or overriding values during installation:

```bash
helm install todo-ai . \
  --set frontend.replicaCount=2 \
  --set backend.resources.requests.cpu=200m \
  --set ingress.hosts[0].host="your-custom-domain.com"
```

## Updating the Deployment

To update an existing deployment:

```bash
# Update the chart
helm upgrade todo-ai .

# Or update with new values
helm upgrade todo-ai . --set frontend.replicaCount=3
```

## Uninstalling

To remove the application:

```bash
helm uninstall todo-ai
kubectl delete secret todo-ai-secrets
```

## Troubleshooting

### Check Pod Logs

```bash
# Check frontend logs
kubectl logs -l app=frontend

# Check backend logs
kubectl logs -l app=backend

# Check MCP server logs
kubectl logs -l app=mcp
```

### Debug Helm Template

Before installing, you can render the templates to check for errors:

```bash
helm template todo-ai .
```

### Check Resource Status

```bash
# Describe pods for detailed information
kubectl describe pod -l app=frontend
kubectl describe pod -l app=backend
kubectl describe pod -l app=mcp

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## AIOps Integration

The deployment is designed to work with AI-assisted DevOps tools:

- Use `kubectl-ai` for Kubernetes operations
- Use `kagent` for health checks and scaling recommendations
- Use Docker AI (Gordon) for container build optimization

Example kubectl-ai commands:

```bash
kubectl-ai "show me the status of all pods in the todo-ai deployment"
kubectl-ai "scale the frontend deployment to 3 replicas"
kubectl-ai "check the health of the backend service"
```