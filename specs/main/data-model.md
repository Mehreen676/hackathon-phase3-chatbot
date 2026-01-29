# Data Model: Todo AI Chatbot Kubernetes Deployment

## Entities

### Frontend Deployment
- **Name**: Unique identifier for the frontend deployment
- **Replicas**: Number of pod instances (configurable via Helm values)
- **Image**: Container image reference (repository and tag)
- **Ports**: Service port mapping (3000 for Next.js)
- **Resources**: CPU and memory limits/requests
- **Environment**: Configuration variables for API endpoints
- **Probes**: Liveness and readiness probe configurations

### Backend Deployment
- **Name**: Unique identifier for the backend deployment
- **Replicas**: Number of pod instances (configurable via Helm values)
- **Image**: Container image reference (repository and tag)
- **Ports**: Service port mapping (7860 for FastAPI)
- **Resources**: CPU and memory limits/requests
- **Environment**: Configuration variables for database and frontend URLs
- **Probes**: Liveness and readiness probe configurations with custom paths

### MCP Server Deployment
- **Name**: Unique identifier for the MCP server deployment
- **Replicas**: Number of pod instances (configurable via Helm values)
- **Image**: Container image reference (repository and tag)
- **Ports**: Service port mapping (8000 for MCP server)
- **Resources**: CPU and memory limits/requests
- **Environment**: Configuration variables for database and backend URLs
- **Probes**: Liveness and readiness probe configurations

### Service
- **Name**: Unique service identifier
- **Type**: Service type (ClusterIP, NodePort, LoadBalancer)
- **Port**: External port exposed by the service
- **TargetPort**: Internal port of the pods
- **Selector**: Label selector to match pods

### ConfigMap
- **Name**: Unique identifier for the configuration map
- **Data**: Key-value pairs of configuration parameters
- **Environment Mapping**: References to mount specific keys as environment variables

### Secret
- **Name**: Unique identifier for the secret
- **Data**: Base64-encoded sensitive information
- **Type**: Secret type (Opaque for generic secrets)

### Ingress
- **Name**: Unique identifier for the ingress resource
- **Host**: Hostname for the ingress rule
- **Paths**: URL path mappings to backend services
- **TLS**: SSL/TLS configuration (optional)

### PersistentVolume (if needed)
- **Name**: Unique identifier for the persistent volume
- **Capacity**: Storage size requirement
- **Access Modes**: ReadWriteOnce, ReadOnlyMany, etc.
- **Storage Class**: Storage class for dynamic provisioning

## Relationships

### Frontend ↔ Backend
- Frontend deployment connects to backend service via internal DNS
- Backend service is referenced in frontend environment variables
- Ingress routes frontend traffic to frontend service

### Backend ↔ MCP Server
- Backend deployment connects to MCP service via internal DNS
- MCP service is referenced in backend environment variables

### Backend ↔ Database
- Backend deployment accesses external Neon PostgreSQL via secrets
- Database credentials stored in Kubernetes secret

### Deployments ↔ Services
- Each deployment has a corresponding service for network access
- Services use label selectors to route traffic to appropriate pods

### Services ↔ Ingress
- Frontend service is exposed through ingress for external access
- Backend and MCP services remain internal (ClusterIP)

## State Transitions

### Deployment States
- Pending → Running (when pods are scheduled and containers start)
- Running → Failed (when containers crash repeatedly)
- Running → Updating (during rolling updates)
- Updating → Running (after successful update)

### Service States
- Created → Available (when endpoints are ready)
- Available → Terminating (during deletion)

### Pod States
- Pending → Running (when containers start successfully)
- Running → Succeeded (for completed jobs)
- Running → Failed (when containers exit with error)
- Running → Unknown (when node state is unclear)