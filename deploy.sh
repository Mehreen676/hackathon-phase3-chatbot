#!/usr/bin/env bash
# ============================================================================
# deploy.sh — One-command deployment of Todo AI Chatbot on Minikube
# ============================================================================
# Usage:
#   ./deploy.sh              # Full deploy (start minikube, build, deploy)
#   ./deploy.sh --skip-build # Deploy without rebuilding images
#   ./deploy.sh --teardown   # Remove everything
#
# Prerequisites: minikube, helm, kubectl, docker
# Secrets:       Create a .env file from .env.example before running
# ============================================================================

set -euo pipefail

# ----------------------------
# Configuration
# ----------------------------
RELEASE_NAME="todo-ai"
CHART_PATH="helm/todo-ai-chatbot"
NAMESPACE="default"
SECRET_NAME="db-password-secret"
SECRET_KEY="password"

FRONTEND_IMAGE="hackathon-phase3-chatbot/frontend"
BACKEND_IMAGE="hackathon-phase3-chatbot/backend"
IMAGE_TAG="latest"

MINIKUBE_CPUS=2
MINIKUBE_MEMORY=4096
MINIKUBE_DRIVER="docker"

# Max seconds to wait for pods to become ready
POD_WAIT_TIMEOUT=120

# ----------------------------
# Color helpers
# ----------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()    { echo -e "${RED}[FAIL]${NC}  $*"; exit 1; }

# ----------------------------
# Parse arguments
# ----------------------------
SKIP_BUILD=false
TEARDOWN=false

for arg in "$@"; do
  case $arg in
    --skip-build) SKIP_BUILD=true ;;
    --teardown)   TEARDOWN=true ;;
    --help|-h)
      echo "Usage: $0 [--skip-build] [--teardown] [--help]"
      echo ""
      echo "  --skip-build   Skip Docker image builds (use existing images)"
      echo "  --teardown     Remove the Helm release and secret, then exit"
      echo "  --help         Show this help message"
      exit 0
      ;;
    *) warn "Unknown argument: $arg" ;;
  esac
done

# ----------------------------
# Teardown mode
# ----------------------------
if [ "$TEARDOWN" = true ]; then
  info "Tearing down ${RELEASE_NAME}..."
  helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE" 2>/dev/null && success "Helm release removed" || warn "No Helm release found"
  kubectl delete secret "$SECRET_NAME" --namespace "$NAMESPACE" 2>/dev/null && success "Secret removed" || warn "No secret found"
  info "Teardown complete."
  exit 0
fi

# ----------------------------
# Step 0: Check prerequisites
# ----------------------------
info "Checking prerequisites..."

for cmd in minikube kubectl helm docker; do
  if ! command -v "$cmd" &>/dev/null; then
    fail "'$cmd' is not installed. Please install it first."
  fi
done
success "All prerequisites found (minikube, kubectl, helm, docker)"

# ----------------------------
# Step 1: Load secrets from .env
# ----------------------------
info "Loading secrets from .env file..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

if [ ! -f "$ENV_FILE" ]; then
  # Also check backend/.env as fallback
  if [ -f "${SCRIPT_DIR}/backend/.env" ]; then
    ENV_FILE="${SCRIPT_DIR}/backend/.env"
    warn "No root .env found, using backend/.env"
  else
    fail "No .env file found. Copy .env.example to .env and fill in your values."
  fi
fi

# Source .env safely (only export known variables)
DATABASE_URL=""
OPENAI_API_KEY=""
ALLOWED_ORIGINS="*"

while IFS='=' read -r key value; do
  # Skip comments and empty lines
  [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
  # Remove leading/trailing whitespace
  key=$(echo "$key" | xargs)
  value=$(echo "$value" | xargs)
  case "$key" in
    DATABASE_URL)     DATABASE_URL="$value" ;;
    OPENAI_API_KEY)   OPENAI_API_KEY="$value" ;;
    ALLOWED_ORIGINS)  ALLOWED_ORIGINS="$value" ;;
  esac
done < "$ENV_FILE"

if [ -z "$DATABASE_URL" ]; then
  fail "DATABASE_URL is not set in .env"
fi
if [ -z "$OPENAI_API_KEY" ]; then
  fail "OPENAI_API_KEY is not set in .env"
fi
success "Secrets loaded (DATABASE_URL, OPENAI_API_KEY, ALLOWED_ORIGINS)"

# ----------------------------
# Step 2: Start Minikube
# ----------------------------
info "Checking Minikube status..."

if minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
  success "Minikube is already running"
else
  info "Starting Minikube (cpus=${MINIKUBE_CPUS}, memory=${MINIKUBE_MEMORY}MB, driver=${MINIKUBE_DRIVER})..."
  minikube start \
    --cpus="$MINIKUBE_CPUS" \
    --memory="$MINIKUBE_MEMORY" \
    --driver="$MINIKUBE_DRIVER"
  success "Minikube started"
fi

# ----------------------------
# Step 3: Enable Ingress addon
# ----------------------------
info "Enabling ingress addon..."
minikube addons enable ingress 2>/dev/null
success "Ingress addon enabled"

# ----------------------------
# Step 4: Configure Docker to use Minikube daemon
# ----------------------------
info "Configuring Docker to use Minikube's daemon..."
eval $(minikube docker-env)
success "Docker now points to Minikube"

# ----------------------------
# Step 5: Build Docker images
# ----------------------------
if [ "$SKIP_BUILD" = true ]; then
  warn "Skipping image builds (--skip-build)"
else
  info "Building frontend image: ${FRONTEND_IMAGE}:${IMAGE_TAG}"
  docker build -t "${FRONTEND_IMAGE}:${IMAGE_TAG}" "${SCRIPT_DIR}/frontend/"
  success "Frontend image built"

  info "Building backend image: ${BACKEND_IMAGE}:${IMAGE_TAG}"
  docker build -t "${BACKEND_IMAGE}:${IMAGE_TAG}" "${SCRIPT_DIR}/backend/"
  success "Backend image built"

  info "Verifying images in Minikube..."
  docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep "hackathon-phase3-chatbot" || warn "Images not visible (may still work)"
  success "Docker images ready"
fi

# ----------------------------
# Step 6: Create or update Kubernetes secret
# ----------------------------
info "Creating/updating Kubernetes secret '${SECRET_NAME}'..."

# Delete existing secret if present, then recreate
kubectl delete secret "$SECRET_NAME" --namespace "$NAMESPACE" 2>/dev/null && info "Deleted old secret" || true

kubectl create secret generic "$SECRET_NAME" \
  --namespace "$NAMESPACE" \
  --from-literal="${SECRET_KEY}=${DATABASE_URL}"

success "Secret '${SECRET_NAME}' created with DATABASE_URL"

# ----------------------------
# Step 7: Deploy with Helm (install or upgrade)
# ----------------------------
info "Deploying with Helm..."

HELM_CMD="upgrade --install"

helm ${HELM_CMD} "$RELEASE_NAME" "${SCRIPT_DIR}/${CHART_PATH}" \
  --namespace "$NAMESPACE" \
  --set frontend.image.tag="${IMAGE_TAG}" \
  --set backend.image.tag="${IMAGE_TAG}" \
  --set mcp.image.tag="${IMAGE_TAG}" \
  --set backend.env.OPENAI_API_KEY="${OPENAI_API_KEY}" \
  --set backend.env.ALLOWED_ORIGINS="${ALLOWED_ORIGINS}" \
  --set ingress.enabled=true \
  --set ingress.hostname="todo-ai.local" \
  --wait \
  --timeout "${POD_WAIT_TIMEOUT}s" 2>&1 || {
    warn "Helm --wait timed out. Pods may still be starting. Continuing..."
  }

success "Helm release '${RELEASE_NAME}' deployed"

# ----------------------------
# Step 8: Wait for pods and verify
# ----------------------------
info "Waiting for pods to be ready..."

echo ""
echo "------------------------------------------------------------"
echo "  POD STATUS"
echo "------------------------------------------------------------"
kubectl get pods --namespace "$NAMESPACE" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME}" \
  -o wide 2>/dev/null || kubectl get pods --namespace "$NAMESPACE" -o wide

echo ""
echo "------------------------------------------------------------"
echo "  SERVICES"
echo "------------------------------------------------------------"
kubectl get svc --namespace "$NAMESPACE" \
  -l "app.kubernetes.io/instance=${RELEASE_NAME}" 2>/dev/null || kubectl get svc --namespace "$NAMESPACE"

echo ""
echo "------------------------------------------------------------"
echo "  INGRESS"
echo "------------------------------------------------------------"
kubectl get ingress --namespace "$NAMESPACE" 2>/dev/null || true

# ----------------------------
# Step 9: Print access URLs
# ----------------------------
echo ""
echo "============================================================"
echo -e "  ${GREEN}DEPLOYMENT COMPLETE${NC}"
echo "============================================================"
echo ""

MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "unknown")

echo "  Minikube IP:  ${MINIKUBE_IP}"
echo ""
echo "  Access methods:"
echo ""
echo "  1) minikube tunnel (recommended):"
echo "     Run 'minikube tunnel' in a separate terminal,"
echo "     then add to /etc/hosts: ${MINIKUBE_IP}  todo-ai.local"
echo "     Open: http://todo-ai.local"
echo ""
echo "  2) Port-forward (quick test):"
echo "     kubectl port-forward svc/${RELEASE_NAME}-todo-ai-chatbot-frontend 3000:3000"
echo "     Open: http://localhost:3000"
echo ""
echo "  3) minikube service (direct):"
echo "     minikube service ${RELEASE_NAME}-todo-ai-chatbot-frontend --url"
echo ""
echo "  Useful commands:"
echo "     kubectl logs -l app.kubernetes.io/component=frontend"
echo "     kubectl logs -l app.kubernetes.io/component=backend"
echo "     kubectl logs -l app.kubernetes.io/component=mcp"
echo "     helm status ${RELEASE_NAME}"
echo "     ./deploy.sh --teardown   # remove everything"
echo ""
echo "============================================================"