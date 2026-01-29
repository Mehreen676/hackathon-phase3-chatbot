# Todo AI Chatbot Helm Chart

This Helm chart deploys the Todo AI Chatbot application on Kubernetes. The application consists of three main components:
- Frontend: Next.js web application
- Backend: FastAPI API server
- MCP Server: Model Context Protocol server for AI agent tools

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Minikube or a Kubernetes cluster
- Access to container images (either public or in a registry accessible to your cluster)

## Installation

### Quick Start

```bash
# Add your container images to the values.yaml or use the --set flag
helm install todo-ai ./helm
```

### With Custom Values

```bash
# Create a custom values file
helm install todo-ai ./helm -f my-values.yaml
```

### For Neon PostgreSQL (External Database)

```bash
# Use the provided sample values file as a template
helm install todo-ai ./helm -f values-neon.yaml
```

## Configuration

The following table lists the configurable parameters of the todo-ai-chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imagePullPolicy` | Image pull policy | `"IfNotPresent"` |
| `frontend.enabled` | Enable frontend deployment | `true` |
| `frontend.image.repository` | Frontend image repository | `"hackathon-phase3-chatbot/frontend"` |
| `frontend.image.tag` | Frontend image tag | `""` (defaults to appVersion) |
| `frontend.replicaCount` | Frontend replica count | `1` |
| `frontend.service.type` | Frontend service type | `"ClusterIP"` |
| `frontend.service.port` | Frontend service port | `3000` |
| `backend.enabled` | Enable backend deployment | `true` |
| `backend.image.repository` | Backend image repository | `"hackathon-phase3-chatbot/backend"` |
| `backend.image.tag` | Backend image tag | `""` (defaults to appVersion) |
| `backend.replicaCount` | Backend replica count | `1` |
| `backend.service.type` | Backend service type | `"ClusterIP"` |
| `backend.service.port` | Backend service port | `7860` |
| `mcp.enabled` | Enable MCP server deployment | `true` |
| `mcp.image.repository` | MCP server image repository | `"hackathon-phase3-chatbot/backend"` |
| `mcp.image.tag` | MCP server image tag | `""` (defaults to appVersion) |
| `mcp.replicaCount` | MCP server replica count | `1` |
| `mcp.service.type` | MCP server service type | `"ClusterIP"` |
| `mcp.service.port` | MCP server service port | `8000` |
| `externalDatabase.host` | External database host | `"neon-db.example.com"` |
| `externalDatabase.port` | External database port | `5432` |
| `externalDatabase.database` | External database name | `"todo_chatbot"` |
| `externalDatabase.username` | External database username | `"todo_user"` |
| `externalDatabase.passwordSecret` | Secret name for database password | `"db-password-secret"` |
| `ingress.enabled` | Enable ingress resource | `false` |
| `ingress.hostname` | Ingress hostname | `"todo-ai.local"` |

## Upgrading

```bash
# Upgrade the release
helm upgrade todo-ai ./helm -f my-values.yaml
```

## Uninstallation

```bash
# Uninstall the release
helm uninstall todo-ai
```

## AI DevOps Integration

The chart is designed to work with AI-assisted DevOps tools:

- **kubectl-ai**: Use for intelligent Kubernetes operations
- **kagent**: Use for health checks and diagnostics
- **Docker AI (Gordon)**: Use for container build optimization

## Troubleshooting

### Common Issues

1. **Images not found**: Ensure your container images are available in the registry specified in values.yaml
2. **Database connectivity**: Verify your external database configuration and credentials
3. **Service access**: Check if the ingress is enabled or use port forwarding to access services

### Useful Commands

```bash
# Check pod status
kubectl get pods

# Check service endpoints
kubectl get svc

# View application logs
kubectl logs -l app.kubernetes.io/component=backend

# Port forward for local access
kubectl port-forward svc/todo-ai-todo-ai-chatbot-frontend 3000:3000

# Scale deployments
kubectl scale deployment todo-ai-todo-ai-chatbot-backend --replicas=2
```

## Development

To customize this chart for your specific environment:

1. Modify `values.yaml` with your specific configurations
2. Update image repositories and tags to match your container registry
3. Adjust resource limits based on your requirements
4. Configure ingress settings for your domain