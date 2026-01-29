---
id: "5"
title: "Automate Minikube Deployment Script"
stage: "green"
date: "2026-01-29"
surface: "agent"
model: "claude-opus-4-5-20251101"
feature: "main"
branch: "main"
user: "Lenovo"
command: "user-request"
labels: ["kubernetes", "automation", "deploy", "minikube", "makefile"]
links:
  spec: "specs/main/spec.md"
  ticket: "null"
  adr: "null"
  pr: "null"
files:
  - deploy.sh
  - Makefile
  - .env.example
tests:
  - helm template with --set flags (PASS - 9 YAML documents, OPENAI_API_KEY injected, Ingress rendered)
  - helm lint (PASS)
---

## Prompt

I want to fully automate the deployment of my todo-ai app on Minikube. Currently, the manual steps are:
Build Docker images inside Minikube, Create a Kubernetes secret for the database credentials, Deploy the app using Helm, Verify that pods are running and frontend is accessible.
I want a single Bash script or Makefile that runs all these steps automatically without manual input.

## Response snapshot

Created three files:
1. `deploy.sh` - Single-command deployment script with flags (--skip-build, --teardown, --help)
2. `Makefile` - Granular targets (deploy, deploy-quick, teardown, status, logs, tunnel, port-forward, access, lint, stop, destroy)
3. `.env.example` - Template for required secrets (DATABASE_URL, OPENAI_API_KEY, ALLOWED_ORIGINS)

Key features of deploy.sh:
- Checks prerequisites (minikube, helm, kubectl, docker)
- Starts Minikube if not running (4GB RAM, 2 CPUs)
- Enables ingress addon
- Configures Docker to use Minikube daemon
- Builds frontend and backend images inside Minikube
- Reads secrets from .env (never hardcoded)
- Creates/updates K8s secret with DATABASE_URL
- Passes OPENAI_API_KEY via Helm --set (injected as env var)
- Deploys with helm upgrade --install (idempotent)
- Verifies pod/service/ingress status
- Prints access URLs (tunnel, port-forward, minikube service)

Verified: helm template with all --set flags renders 9 YAML docs correctly, OPENAI_API_KEY injected into backend pod, Ingress created with hostname.

## Outcome

- Impact: Full deployment automation achieved - single command deploys entire stack
- Tests: helm template PASS (9 docs), helm lint PASS, OPENAI_API_KEY injection verified
- Files: 3 files created (deploy.sh, Makefile, .env.example)
- Next prompts: Run deploy.sh on actual Minikube, verify end-to-end functionality
- Reflection: Script covers all manual steps and adds idempotency (upgrade --install), secret rotation, and teardown capability

## Evaluation notes (flywheel)

- Failure modes observed: None in template rendering
- Graders run and results (PASS/FAIL): helm template PASS, helm lint PASS
- Prompt variant (if applicable): N/A
- Next experiment (smallest change to try): Run deploy.sh end-to-end on live Minikube cluster