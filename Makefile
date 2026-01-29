# ============================================================================
# Makefile — Todo AI Chatbot Kubernetes Deployment
# ============================================================================
# Usage:
#   make deploy         Full deploy (start, build, secrets, helm, verify)
#   make deploy-quick   Deploy without rebuilding images
#   make teardown       Remove everything from cluster
#   make status         Show pod/service/ingress status
#   make logs           Tail logs from all components
#   make tunnel         Start minikube tunnel (for ingress access)
# ============================================================================

.PHONY: help deploy deploy-quick teardown build-images start-minikube \
        secrets helm-deploy status logs tunnel port-forward lint clean

# ---- Configuration ----
RELEASE      := todo-ai
CHART        := helm/todo-ai-chatbot
NAMESPACE    := default
SECRET_NAME  := db-password-secret
SECRET_KEY   := password
FE_IMAGE     := hackathon-phase3-chatbot/frontend
BE_IMAGE     := hackathon-phase3-chatbot/backend
TAG          := latest
WAIT_TIMEOUT := 120

# ---- Load .env if present ----
ifneq (,$(wildcard ./.env))
  include .env
  export
endif

# ---- Default target ----
help: ## Show this help
	@echo ""
	@echo "Todo AI Chatbot - Kubernetes Deployment"
	@echo "========================================"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ============================================================
# Full workflows
# ============================================================

deploy: check-env start-minikube enable-addons docker-env build-images secrets helm-deploy status ## Full deploy: minikube + build + deploy + verify
	@echo ""
	@echo "=========================================="
	@echo "  Deployment complete! Run 'make access' for URL info."
	@echo "=========================================="

deploy-quick: check-env docker-env secrets helm-deploy status ## Deploy without rebuilding images
	@echo ""
	@echo "Quick deploy complete."

teardown: ## Remove Helm release and secret
	-helm uninstall $(RELEASE) --namespace $(NAMESPACE)
	-kubectl delete secret $(SECRET_NAME) --namespace $(NAMESPACE)
	@echo "Teardown complete."

# ============================================================
# Individual steps
# ============================================================

check-env: ## Verify required env vars are set
	@if [ -z "$(DATABASE_URL)" ]; then \
		echo "ERROR: DATABASE_URL not set. Create .env from .env.example"; exit 1; \
	fi
	@if [ -z "$(OPENAI_API_KEY)" ]; then \
		echo "ERROR: OPENAI_API_KEY not set. Create .env from .env.example"; exit 1; \
	fi
	@echo "[OK] Environment variables loaded"

start-minikube: ## Start Minikube if not running
	@if minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then \
		echo "[OK] Minikube already running"; \
	else \
		echo "[INFO] Starting Minikube..."; \
		minikube start --cpus=2 --memory=4096 --driver=docker; \
		echo "[OK] Minikube started"; \
	fi

enable-addons: ## Enable required Minikube addons
	minikube addons enable ingress
	@echo "[OK] Ingress addon enabled"

docker-env: ## Point Docker CLI to Minikube daemon
	@echo "[INFO] Configuring Docker for Minikube..."
	@echo "Run this in your shell first if builds fail:"
	@echo '  eval $$(minikube docker-env)'

build-images: ## Build frontend and backend Docker images
	eval $$(minikube docker-env) && \
	docker build -t $(FE_IMAGE):$(TAG) frontend/ && \
	echo "[OK] Frontend image built" && \
	docker build -t $(BE_IMAGE):$(TAG) backend/ && \
	echo "[OK] Backend image built"

secrets: ## Create or update Kubernetes secret with DB credentials
	-@kubectl delete secret $(SECRET_NAME) --namespace $(NAMESPACE) 2>/dev/null || true
	kubectl create secret generic $(SECRET_NAME) \
		--namespace $(NAMESPACE) \
		--from-literal=$(SECRET_KEY)=$(DATABASE_URL)
	@echo "[OK] Secret '$(SECRET_NAME)' created"

helm-deploy: ## Install or upgrade Helm release
	helm upgrade --install $(RELEASE) $(CHART) \
		--namespace $(NAMESPACE) \
		--set frontend.image.tag=$(TAG) \
		--set backend.image.tag=$(TAG) \
		--set mcp.image.tag=$(TAG) \
		--set "backend.env.OPENAI_API_KEY=$(OPENAI_API_KEY)" \
		--set "backend.env.ALLOWED_ORIGINS=$(or $(ALLOWED_ORIGINS),*)" \
		--set ingress.enabled=true \
		--set ingress.hostname=todo-ai.local \
		--wait --timeout $(WAIT_TIMEOUT)s || \
		echo "[WARN] Helm --wait timed out, pods may still be starting"
	@echo "[OK] Helm release '$(RELEASE)' deployed"

lint: ## Lint the Helm chart
	helm lint $(CHART)
	helm template $(RELEASE) $(CHART) > /dev/null
	@echo "[OK] Helm chart is valid"

# ============================================================
# Monitoring & access
# ============================================================

status: ## Show pod, service, and ingress status
	@echo ""
	@echo "--- PODS ---"
	kubectl get pods --namespace $(NAMESPACE) -o wide
	@echo ""
	@echo "--- SERVICES ---"
	kubectl get svc --namespace $(NAMESPACE)
	@echo ""
	@echo "--- INGRESS ---"
	-kubectl get ingress --namespace $(NAMESPACE)

logs: ## Tail logs from all components
	@echo "=== Frontend ===" && kubectl logs -l app.kubernetes.io/component=frontend --tail=20 2>/dev/null || true
	@echo ""
	@echo "=== Backend ===" && kubectl logs -l app.kubernetes.io/component=backend --tail=20 2>/dev/null || true
	@echo ""
	@echo "=== MCP ===" && kubectl logs -l app.kubernetes.io/component=mcp --tail=20 2>/dev/null || true

logs-follow: ## Follow backend logs live
	kubectl logs -f -l app.kubernetes.io/component=backend

tunnel: ## Start minikube tunnel for ingress access (run in separate terminal)
	@echo "Starting minikube tunnel..."
	@echo "Add to /etc/hosts:  $$(minikube ip)  todo-ai.local"
	minikube tunnel

port-forward: ## Port-forward frontend to localhost:3000
	@echo "Frontend accessible at http://localhost:3000"
	kubectl port-forward svc/$(RELEASE)-todo-ai-chatbot-frontend 3000:3000

access: ## Print all access methods
	@echo ""
	@echo "============================================"
	@echo "  ACCESS METHODS"
	@echo "============================================"
	@echo ""
	@echo "  Minikube IP: $$(minikube ip 2>/dev/null || echo 'unknown')"
	@echo ""
	@echo "  1) make tunnel"
	@echo "     Then add to /etc/hosts: $$(minikube ip)  todo-ai.local"
	@echo "     Open: http://todo-ai.local"
	@echo ""
	@echo "  2) make port-forward"
	@echo "     Open: http://localhost:3000"
	@echo ""
	@echo "  3) minikube service $(RELEASE)-todo-ai-chatbot-frontend --url"
	@echo ""

# ============================================================
# Cleanup
# ============================================================

clean: teardown ## Alias for teardown

stop: ## Stop Minikube
	minikube stop
	@echo "[OK] Minikube stopped"

destroy: teardown ## Teardown and delete Minikube cluster
	minikube delete
	@echo "[OK] Minikube cluster deleted"