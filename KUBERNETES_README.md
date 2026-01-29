# Todo AI Chatbot - Cloud Native Deployment

This project implements a cloud-native deployment of the Todo AI Chatbot using Kubernetes and Helm charts, following the Phase IV Constitution for Local Kubernetes Deployment.

## Architecture Overview

The system consists of three main components deployed as independent, stateless containers:

1. **Frontend** - Next.js application with ChatKit UI
2. **Backend** - FastAPI application with OpenAI Agents SDK
3. **MCP Server** - Official MCP SDK for tool communication

## Kubernetes Resources

The deployment creates the following Kubernetes resources:

- Deployments for each component with liveness/readiness probes
- Services for internal communication
- Ingress for external access
- ConfigMaps for configuration
- Secrets for sensitive data

## Deployment Process

The deployment follows Spec-Driven Development principles:
1. Specifications are defined in the Helm chart
2. Claude Code generates Kubernetes manifests from specs
3. Helm deploys the complete system with a single command

## AIOps Integration

The system is designed for AI-assisted operations:
- `kubectl-ai` for Kubernetes operations
- `kagent` for health analysis and scaling
- Docker AI (Gordon) for container optimization

## Getting Started

See [KUBERNETES_DEPLOYMENT_GUIDE.md](KUBERNETES_DEPLOYMENT_GUIDE.md) for detailed deployment instructions.