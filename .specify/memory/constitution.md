<!-- SYNC IMPACT REPORT
Version change: N/A -> 1.0.0
Modified principles: None (completely new constitution for Phase IV)
Added sections: All sections reflecting Phase IV Kubernetes deployment
Removed sections: Template placeholders
Templates requiring updates: ⚠ pending - plan-template.md, spec-template.md, tasks-template.md may need alignment
Follow-up TODOs: None
-->
# Todo AI Chatbot – Cloud Native Deployment (Minikube) Constitution

## Core Principles

### I. Spec-Driven Infrastructure
Every Kubernetes resource (Deployment, Service, Ingress, ConfigMap, Secret) must have a written specification. Claude Code must generate Helm charts from these specs.

### II. Cloud Native Architecture
Frontend, Backend, and MCP Server must run as independent, stateless containers. All services must be horizontally scalable.

### III. AI-Assisted DevOps (AIOps)
kubectl-ai for Kubernetes operations. kagent for health checks, scaling, and diagnostics. Docker AI (Gordon) for container build and optimization.

### IV. Security & Configuration
Secrets must be stored in Kubernetes Secrets. Configuration must be stored in ConfigMaps. No credentials may be hardcoded.

### V. Reproducibility
The complete system must be deployable with a single command: helm install todo-ai ./helm

### VI. Container-Based Deployment
All application components must run in Docker containers with optimized images. Container build processes must follow best practices for security and efficiency.

## Kubernetes Architecture Requirements

Frontend (Next.js + ChatKit) must run in a dedicated deployment with horizontal scaling capability. Backend (FastAPI + OpenAI Agents SDK) must run in a separate deployment with appropriate resource allocation. MCP Server (Official MCP SDK) must run in its own deployment with proper service discovery. Database connections must use Neon PostgreSQL via external secrets.

## Helm Chart Standards

Helm chart structure must follow the defined directory layout with proper separation of concerns. All Kubernetes resources must be defined in the templates directory with appropriate values.yaml configuration. Chart.yaml must contain accurate versioning and dependency information.

## Deployment Rules

All services must have liveness and readiness probes configured. Resource limits and requests must be defined for all deployments. Horizontal scaling must be supported for all stateless services. No manual YAML writing: Specs → Claude Code → Helm generation process must be followed.

## Success Criteria

Application must run successfully on Minikube. Frontend must be accessible via browser through Ingress or NodePort. Backend must communicate properly with MCP Server. Helm chart must deploy the complete system without errors. kubectl-ai and kagent must be able to manage the cluster effectively.

## Non-Goals (Out of Scope for Phase IV)

Kafka, Dapr, Cloud Providers (AKS, GKE, AWS), and Advanced Todo features are explicitly out of scope for this phase.

## Governance

This constitution governs all development activities for Phase IV Kubernetes deployment. All code changes, infrastructure definitions, and deployment procedures must comply with these principles. Amendments to this constitution require explicit approval and documentation of the changes and their impact on the system.

All team members must follow the AI-assisted DevOps workflow using kubectl-ai, kagent, and Docker AI (Gordon) for operations. The system must maintain reproducibility with the single-command deployment requirement.

**Version**: 1.0.0 | **Ratified**: 2026-01-28 | **Last Amended**: 2026-01-28