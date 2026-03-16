#!/usr/bin/env bash
# scripts/deploy.sh
#
# Builds, pushes, and deploys CryptoScope to EKS.
# Updates the image tag in K8s manifests to the current git SHA.
#
# Usage: ./scripts/deploy.sh

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_TAG=$(git rev-parse --short HEAD)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
CLUSTER_NAME="cryptoscope-dev-cluster"

echo "==> Deploying tag: ${IMAGE_TAG}"

# ── Step 1: Build and push images ────────────────────────────────────────────
echo ""
echo "==> Pushing images to ECR..."
IMAGE_TAG="${IMAGE_TAG}" ./scripts/ecr-push.sh

# ── Step 2: Update image tags in manifests ───────────────────────────────────
echo ""
echo "==> Updating image tags in manifests..."

# Use kubectl set image for a clean rolling update
# This avoids sed-editing YAML files directly
aws eks update-kubeconfig \
  --region "${AWS_REGION}" \
  --name "${CLUSTER_NAME}" > /dev/null

kubectl set image deployment/backend \
  backend="${ECR_REGISTRY}/cryptoscope-backend:${IMAGE_TAG}" \
  -n cryptoscope

kubectl set image deployment/frontend \
  frontend="${ECR_REGISTRY}/cryptoscope-frontend:${IMAGE_TAG}" \
  -n cryptoscope

# ── Step 3: Wait for rollout ─────────────────────────────────────────────────
echo ""
echo "==> Waiting for backend rollout..."
kubectl rollout status deployment/backend -n cryptoscope --timeout=300s

echo "==> Waiting for frontend rollout..."
kubectl rollout status deployment/frontend -n cryptoscope --timeout=300s

# ── Step 4: Show status ───────────────────────────────────────────────────────
echo ""
echo "==> Deployment complete!"
echo ""
kubectl get pods -n cryptoscope
echo ""
echo "==> Ingress:"
kubectl get ingress -n cryptoscope
