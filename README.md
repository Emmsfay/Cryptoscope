# CryptoScope

> Real-time cryptocurrency price tracker built as a full end-to-end DevOps project — from local development to production on AWS EKS with CI/CD and observability.

![Architecture](https://img.shields.io/badge/AWS-EKS-orange) ![Terraform](https://img.shields.io/badge/IaC-Terraform-purple) ![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-blue) ![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus_Grafana-red)

---

## Project Overview

CryptoScope is a production-grade web application that tracks live cryptocurrency prices using the CoinGecko API. The project is structured as six progressive phases, each introducing a distinct DevOps discipline — from writing the application code to full observability on a live Kubernetes cluster.

**Live stack:**
- Frontend: React + TypeScript served by nginx
- Backend: Python FastAPI with async CoinGecko integration
- Infrastructure: AWS EKS, VPC, ECR via Terraform
- CI/CD: GitHub Actions with OIDC authentication
- Monitoring: Prometheus + Grafana with custom dashboards and alert rules

---

## Project Phases

| Phase | Focus | Tools |
|-------|-------|-------|
| 1 | Application | FastAPI, React, TypeScript, CoinGecko API |
| 2 | Containerisation | Docker multi-stage builds, nginx, AWS ECR |
| 3 | Infrastructure | Terraform, AWS VPC, EKS, IAM, S3 remote state |
| 4 | Kubernetes Deploy | K8s Deployments, Services, HPA, Ingress, ALB |
| 5 | CI/CD Pipeline | GitHub Actions, OIDC, rolling deployments |
| 6 | Observability | Prometheus, Grafana, AlertManager, PrometheusRules |

---

## Repository Structure

```
cryptoscope/
├── backend/                        # Python FastAPI service
│   ├── app/
│   │   ├── main.py                 # App entry point + Prometheus metrics
│   │   ├── routers/
│   │   │   ├── prices.py           # GET /api/prices/
│   │   │   └── coins.py            # GET /api/coins/*
│   │   ├── services/
│   │   │   └── coingecko.py        # CoinGecko API client
│   │   └── models/
│   │       └── coin.py             # Pydantic schemas
│   ├── Dockerfile                  # Production multi-stage build
│   ├── Dockerfile.dev              # Development with hot reload
│   └── requirements.txt
│
├── frontend/                       # React + TypeScript SPA
│   ├── src/
│   │   ├── pages/Dashboard.tsx     # Main tracker UI
│   │   ├── components/             # Sparkline, PriceChange, CoinChart
│   │   ├── hooks/                  # usePrices (auto-poll), useCoinChart
│   │   └── services/api.ts         # Typed Axios client
│   ├── nginx.conf                  # Production nginx config with /api proxy
│   ├── Dockerfile                  # Production: Node builder + nginx runtime
│   └── Dockerfile.dev              # Development with Vite HMR
│
├── infra/                          # Terraform infrastructure
│   ├── main.tf                     # Root module — wires VPC, EKS, ECR
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Cluster endpoint, ECR URLs, kubectl cmd
│   ├── versions.tf                 # Provider versions + S3 remote state
│   ├── modules/
│   │   ├── vpc/                    # VPC, subnets, IGW, NAT gateways
│   │   ├── eks/                    # EKS cluster, node group, IAM, OIDC
│   │   └── ecr/                    # ECR repositories + lifecycle policies
│   └── environments/
│       └── dev/terraform.tfvars    # Dev environment values
│
├── k8s/                            # Kubernetes manifests
│   ├── kustomization.yaml          # Applies all manifests in correct order
│   ├── namespace/namespace.yaml    # cryptoscope namespace
│   ├── backend/
│   │   ├── deployment.yaml         # 2 replicas, probes, anti-affinity
│   │   ├── service.yaml            # ClusterIP service
│   │   └── hpa.yaml                # Scales 2->6 pods on CPU/memory
│   ├── frontend/
│   │   ├── deployment.yaml         # 2 replicas, nginx container
│   │   ├── service.yaml            # ClusterIP service
│   │   └── hpa.yaml                # Scales 2->4 pods on CPU
│   └── ingress/
│       └── ingress.yaml            # AWS ALB via Load Balancer Controller
│
├── monitoring/                     # Observability stack
│   ├── prometheus-values.yaml      # kube-prometheus-stack Helm values
│   ├── service-monitor.yaml        # Tells Prometheus to scrape /metrics
│   ├── dashboards/
│   │   └── cryptoscope-dashboard.yaml  # Grafana dashboard ConfigMap
│   └── alerts/
│       └── cryptoscope-rules.yaml  # PrometheusRule — 5 alert rules
│
├── scripts/
│   ├── bootstrap-state.sh          # Creates S3 + DynamoDB for Terraform state
│   ├── ecr-push.sh                 # Builds + pushes images to ECR
│   ├── install-alb-controller.sh   # Installs AWS Load Balancer Controller
│   ├── install-monitoring.sh       # Installs kube-prometheus-stack
│   ├── setup-github-oidc.sh        # Creates IAM role for GitHub Actions
│   └── deploy.sh                   # Manual build + deploy script
│
├── .github/
│   └── workflows/
│       └── cicd.yml                # CI/CD pipeline
│
├── docker-compose.yml              # Local dev environment
├── docker-compose.prod.yml         # Local production simulation
└── README.md
```

---

## Phase 1 — Application

### What was built

A full-stack web application with a FastAPI backend and React frontend that fetches and displays real-time cryptocurrency prices from the CoinGecko public API.

### Backend (FastAPI)

| Endpoint | Description |
|----------|-------------|
| `GET /api/prices/` | Top N coins with sparkline data |
| `GET /api/coins/search?q=` | Search coins by name or symbol |
| `GET /api/coins/{id}` | Detailed coin information |
| `GET /api/coins/{id}/chart` | Historical price data |
| `GET /health` | Health check for K8s probes |
| `GET /metrics` | Prometheus metrics endpoint |

**Key design decisions:**
- A single `httpx.AsyncClient` is created once at startup via FastAPI's lifespan context manager and shared across all requests — maintains a connection pool to CoinGecko rather than opening a new TCP connection per request
- All CoinGecko calls are in `CoinGeckoService` — service layer pattern keeps route handlers clean
- Pydantic models use `extra = "ignore"` to silently discard unneeded fields from CoinGecko's large response objects

### Frontend (React + TypeScript)

- `usePrices` hook auto-polls every 30 seconds, exposes a manual `refresh()` function
- `useCoinChart` fetches chart data on demand when a user clicks a coin
- All API responses are fully typed in `src/services/api.ts`
- Recharts renders sparklines (inline 7-day mini charts) and full area charts in the coin detail modal

### Running locally

```bash
# Docker Compose (recommended)
docker compose up --build
# Frontend: http://localhost:5173  |  API docs: http://localhost:8000/docs

# Manual
cd backend && pip install -r requirements.txt && uvicorn app.main:app --reload
cd frontend && npm install && npm run dev
```

---

## Phase 2 — Containerisation

### Multi-stage builds

**Backend:**
1. `builder` — installs gcc and Python packages into `/install`
2. `runtime` — copies only installed packages, runs as non-root `appuser`

**Frontend:**
1. `builder` — Node 20, `npm ci --frozen-lockfile`, `npm run build` produces `dist/`
2. `runtime` — nginx:alpine copies only `dist/` — no Node.js, no source code, no node_modules

### nginx configuration highlights

- `try_files $uri $uri/ /index.html` — SPA fallback routing for React Router
- `/api/*` proxied to `http://backend:8000` — Kubernetes service DNS name
- `Cache-Control: immutable` with 1-year expiry on Vite-fingerprinted assets
- Security headers on every response

### ECR push

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1
./scripts/ecr-push.sh
```

Images tagged with git commit SHA + `latest`. Commit SHA tag is immutable — permanently identifies the exact code version.

### Testing production build locally

```bash
docker compose -f docker-compose.prod.yml up --build
# App at http://localhost:80
```

---

## Phase 3 — Infrastructure (Terraform)

### Setup

```bash
# One-time: create S3 bucket + DynamoDB for remote state
./scripts/bootstrap-state.sh

# Update bucket name in infra/versions.tf, then:
cd infra
terraform init
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars

# Configure kubectl after apply
aws eks update-kubeconfig --region us-east-1 --name cryptoscope-dev-cluster
kubectl get nodes
```

### What gets created

**VPC module** — VPC (10.0.0.0/16), 2 public subnets (ALB), 2 private subnets (EKS nodes), Internet Gateway, 2 NAT Gateways (one per AZ for HA), route tables, ALB-required subnet tags

**EKS module** — EKS 1.29 with KMS secrets encryption and CloudWatch logging, managed node group (2x t3.small in private subnets), addons (vpc-cni, coredns, kube-proxy), IAM roles, OIDC provider for IRSA

**ECR module** — `cryptoscope-backend` and `cryptoscope-frontend` repositories with lifecycle policies (keep last 10 tagged, delete untagged after 1 day)

### Cost estimate

| Resource | Cost/hr |
|----------|---------|
| EKS control plane | $0.10 |
| 2x t3.small nodes | $0.046 |
| 2x NAT Gateways | $0.09 |
| **Total** | **~$0.24/hr (~$5.70/day)** |

Run `terraform destroy` when not working to avoid charges.

---

## Phase 4 — Kubernetes Deployment

```bash
# One-time: install AWS Load Balancer Controller
./scripts/install-alb-controller.sh

# Deploy everything
kubectl apply -k k8s/

# Verify
kubectl get pods -n cryptoscope
kubectl get ingress -n cryptoscope   # wait 2-3 min for ALB ADDRESS
```

### Key manifest decisions

- `maxUnavailable: 0` rolling update — new pods must be Ready before old ones terminate
- `podAntiAffinity` — spreads pods across nodes, one node failure doesn't kill all replicas
- Liveness + readiness + startup probes — different jobs: restart unhealthy, route traffic only to ready, allow slow startup
- HPA with slow scale-down (5min window) prevents replica flapping under variable load

---

## Phase 5 — CI/CD Pipeline

Every push to `main` automatically: lints and type-checks → builds Docker images → pushes to ECR → rolling deploys to EKS.

### OIDC setup (one-time)

```bash
GITHUB_ORG=Emmsfay GITHUB_REPO=Cryptoscope ./scripts/setup-github-oidc.sh
# Add printed ARN as AWS_DEPLOY_ROLE_ARN in GitHub repository secrets
# Add role to aws-auth ConfigMap in kube-system
```

### Pipeline jobs

**Test** (every push + PR): lint backend with `ruff`, type-check frontend with `tsc`, build frontend bundle

**Deploy** (push to main only, after Test passes): OIDC auth with AWS, build + push both images tagged with git SHA, `kubectl set image` rolling deploy, wait for rollout completion

No AWS access keys are stored in GitHub — OIDC generates short-lived tokens per workflow run.

---

## Phase 6 — Observability

```bash
# Install stack
./scripts/install-monitoring.sh

# Apply CryptoScope resources
kubectl apply -f monitoring/service-monitor.yaml
kubectl apply -f monitoring/dashboards/cryptoscope-dashboard.yaml
kubectl apply -f monitoring/alerts/cryptoscope-rules.yaml

# Access Grafana
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
# http://localhost:3000  |  admin / cryptoscope-admin
```

### Dashboard panels

| Panel | What it shows |
|-------|--------------|
| Request rate | HTTP requests/sec to the backend |
| p95 latency | 95th percentile response time |
| Error rate | Percentage of 5xx responses |
| Pod count | Ready pods in cryptoscope namespace |
| Memory / CPU | Per-pod resource usage |
| HPA replicas | Current vs maximum replica count |

### Alert rules

| Alert | Triggers when | Severity |
|-------|--------------|----------|
| `BackendDown` | 0 healthy backend pods for 2 min | critical |
| `HighErrorRate` | Error rate > 5% for 5 min | warning |
| `HighLatency` | p95 latency > 2s for 5 min | warning |
| `PodCrashLooping` | Pod restarts > 3 times in 15 min | warning |
| `HPAAtMaxReplicas` | HPA at max replicas for 10 min | warning |

---

## Images

<img width="1920" height="864" alt="Screenshot (234)" src="https://github.com/user-attachments/assets/be6ac0e1-de78-4d82-a45c-ae3f7a7a7ca3" />

<img width="1912" height="883" alt="Screenshot (273)" src="https://github.com/user-attachments/assets/7e138213-89dd-4cb0-9eb5-91e2fc5ec5be" />

<img width="1920" height="873" alt="Screenshot (268)" src="https://github.com/user-attachments/assets/d577d749-374f-44b2-a0e3-6ad990969ecc" />


## Prerequisites

| Tool | Version |
|------|---------|
| Docker | 24+ |
| Terraform | 1.6+ |
| kubectl | 1.29+ |
| Helm | 3+ |
| AWS CLI | 2+ |
| Node.js | 20+ |
| Python | 3.12+ |

---

## Teardown

```bash
kubectl delete namespace cryptoscope
kubectl delete namespace monitoring
cd infra && terraform destroy -var-file=environments/dev/terraform.tfvars
```

---

## Author

**Emms** — DevOps / Cloud Engineering Student
GitHub: [@Emmsfay](https://github.com/Emmsfay)
