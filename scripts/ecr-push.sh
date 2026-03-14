#!/usr/bin/env bash
# scripts/ecr-push.sh
# Usage: ./scripts/ecr-push.sh
#
# Prerequisites:
#   - AWS CLI configured (aws configure)
#   - Docker running
#   - Set AWS_ACCOUNT_ID and AWS_REGION below or export them as env vars

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD)}"

BACKEND_REPO="cryptoscope-backend"
FRONTEND_REPO="cryptoscope-frontend"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# ── Validation ────────────────────────────────────────────────────────────────
if [[ -z "$AWS_ACCOUNT_ID" ]]; then
  echo "ERROR: AWS_ACCOUNT_ID is not set."
  echo "Run: export AWS_ACCOUNT_ID=\$(aws sts get-caller-identity --query Account --output text)"
  exit 1
fi

echo ">>> Deploying tag: ${IMAGE_TAG}"
echo ">>> Registry:      ${ECR_REGISTRY}"

# ── Step 1: Authenticate Docker with ECR ─────────────────────────────────────
echo ""
echo "==> Authenticating with ECR..."
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

# ── Step 2: Create ECR repos if they don't exist ─────────────────────────────
echo ""
echo "==> Ensuring ECR repositories exist..."
for repo in "${BACKEND_REPO}" "${FRONTEND_REPO}"; do
  aws ecr describe-repositories --repository-names "${repo}" --region "${AWS_REGION}" \
    > /dev/null 2>&1 || \
  aws ecr create-repository \
    --repository-name "${repo}" \
    --region "${AWS_REGION}" \
    --image-scanning-configuration scanOnPush=true \
    > /dev/null
  echo "    ${repo} OK"
done

# ── Step 3: Build images ──────────────────────────────────────────────────────
echo ""
echo "==> Building backend..."
docker build \
  --platform linux/amd64 \
  -t "${BACKEND_REPO}:${IMAGE_TAG}" \
  -t "${BACKEND_REPO}:latest" \
  ./backend

echo ""
echo "==> Building frontend..."
docker build \
  --platform linux/amd64 \
  -t "${FRONTEND_REPO}:${IMAGE_TAG}" \
  -t "${FRONTEND_REPO}:latest" \
  ./frontend

# ── Step 4: Tag for ECR ───────────────────────────────────────────────────────
echo ""
echo "==> Tagging images for ECR..."
docker tag "${BACKEND_REPO}:${IMAGE_TAG}"  "${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}"
docker tag "${BACKEND_REPO}:latest"        "${ECR_REGISTRY}/${BACKEND_REPO}:latest"
docker tag "${FRONTEND_REPO}:${IMAGE_TAG}" "${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}"
docker tag "${FRONTEND_REPO}:latest"       "${ECR_REGISTRY}/${FRONTEND_REPO}:latest"

# ── Step 5: Push to ECR ───────────────────────────────────────────────────────
echo ""
echo "==> Pushing backend to ECR..."
docker push "${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}"
docker push "${ECR_REGISTRY}/${BACKEND_REPO}:latest"

echo ""
echo "==> Pushing frontend to ECR..."
docker push "${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}"
docker push "${ECR_REGISTRY}/${FRONTEND_REPO}:latest"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "✓ Done! Images pushed:"
echo "  ${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}"
echo "  ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}"
