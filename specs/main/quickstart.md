# Quickstart Guide: Todo AI Chatbot on Kubernetes

## Prerequisites

- Kubernetes 1.19+ (tested with Minikube)
- Helm 3.0+
- Docker (for building images if needed)
- kubectl
- Access to container images (or build from source)

## Setup Minikube

```bash
# Start Minikube with sufficient resources
minikube start --memory=4096 --cpus=2

# Enable ingress addon
minikube addons enable ingress

# Optionally enable metrics server for kubectl top commands
minikube addons enable metrics-server
```

## Prepare Container Images

The application requires container images for frontend and backend components:

```bash
# If building from source:
# Build frontend image
cd frontend
docker build -t hackathon-phase3-chatbot/frontend:latest .

# Build backend image
cd ../backend
docker build -t hackathon-phase3-chatbot/backend:latest .

# Load images into minikube
minikube image load hackathon-phase3-chatbot/frontend:latest
minikube image load hackathon-phase3-chatbot/backend:latest
```

## Configure Database Secrets

Create a Kubernetes secret with your Neon PostgreSQL connection details:

```bash
# Create namespace (optional but recommended)
kubectl create namespace todo-ai

# Create secret with database credentials
kubectl create secret generic neon-db-password-secret \
  --from-literal=password='YOUR_NEON_DB_PASSWORD' \
  --namespace todo-ai
```

## Deploy with Helm

```bash
# Navigate to the helm chart directory
cd helm/todo-ai-chatbot

# Install the chart (replace with your actual values)
helm install todo-ai . \
  --namespace todo-ai \
  --create-namespace \
  --set externalDatabase.host='ep-xxx-xxxxxxx.us-east-1.aws.neon.tech' \
  --set externalDatabase.database='todo_chatbot' \
  --set externalDatabase.username='todo_user' \
  --set externalDatabase.passwordSecret='neon-db-password-secret' \
  --set ingress.enabled=true \
  --set ingress.hostname='todo-ai.local'

# Or use the values file
helm install todo-ai . -f values-neon.yaml --namespace todo-ai --create-namespace
```

## Verify Installation

```bash
# Check all pods are running
kubectl get pods --namespace todo-ai

# Check all services are available
kubectl get svc --namespace todo-ai

# Check ingress
kubectl get ingress --namespace todo-ai

# View application logs
kubectl logs -l app.kubernetes.io/component=backend --namespace todo-ai
```

## Access the Application

If using ingress, add the Minikube IP to your hosts file:

```bash
# Get Minikube IP
minikube ip

# Add to hosts file (on Windows, edit C:\Windows\System32\drivers\etc\hosts)
# Add line: <MINIKUBE_IP> todo-ai.local

# Then access the application at:
# http://todo-ai.local
```

Alternatively, use port forwarding:

```bash
# Forward frontend service
kubectl port-forward svc/todo-ai-todo-ai-chatbot-frontend 3000:3000 --namespace todo-ai
```

## Scaling the Application

```bash
# Scale frontend replicas
kubectl scale deployment todo-ai-todo-ai-chatbot-frontend --replicas=2 --namespace todo-ai

# Scale backend replicas
kubectl scale deployment todo-ai-todo-ai-chatbot-backend --replicas=2 --namespace todo-ai
```

## AI DevOps Tools

### Using kubectl-ai

```bash
# Describe pods using AI
kubectl-ai describe pods --namespace todo-ai

# Diagnose issues
kubectl-ai diagnose --namespace todo-ai
```

### Using kagent

```bash
# Analyze resource usage
kagent analyze --namespace todo-ai

# Get optimization recommendations
kagent recommend --namespace todo-ai
```

### Using Docker AI (Gordon)

```bash
# Optimize images
gordon optimize hackathon-phase3-chatbot/frontend:latest
gordon optimize hackathon-phase3-chatbot/backend:latest
```

## Troubleshooting

### Common Issues

1. **Images not found**: Ensure images are available in the node's container runtime
2. **Database connection errors**: Verify the Neon PostgreSQL configuration and credentials
3. **Ingress not accessible**: Check that the ingress controller is running and the hostname is correctly configured
4. **Pods in CrashLoopBackOff**: Check the logs with `kubectl logs` to identify the issue

### Useful Commands

```bash
# Check pod status
kubectl get pods -n todo-ai

# View logs
kubectl logs -f deployment/todo-ai-todo-ai-chatbot-backend -n todo-ai

# Check service endpoints
kubectl get ep -n todo-ai

# Port forward for debugging
kubectl port-forward -n todo-ai deployment/todo-ai-todo-ai-chatbot-frontend 3000:3000

# Get all resources
kubectl get all -n todo-ai
```

## Cleanup

```bash
# Uninstall the Helm release
helm uninstall todo-ai --namespace todo-ai

# Delete namespace (if created)
kubectl delete namespace todo-ai

# Stop Minikube
minikube stop
```