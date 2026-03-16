#!/usr/bin/env bash
# scripts/install-alb-controller.sh
#
# Installs the AWS Load Balancer Controller on the EKS cluster.
# This controller watches for Ingress resources and creates ALBs in AWS.
#
# Prerequisites:
#   - kubectl configured for cryptoscope-dev-cluster
#   - helm installed (https://helm.sh/docs/intro/install/)
#   - AWS CLI configured
#   - Terraform apply completed (OIDC provider must exist)
#
# Usage: ./scripts/install-alb-controller.sh

set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
CLUSTER_NAME="cryptoscope-dev-cluster"
SERVICE_ACCOUNT_NAME="aws-load-balancer-controller"
NAMESPACE="kube-system"

echo "==> Cluster:    ${CLUSTER_NAME}"
echo "==> Account:    ${AWS_ACCOUNT_ID}"
echo "==> Region:     ${AWS_REGION}"
echo ""

# ── Step 1: Create IAM policy for the controller ─────────────────────────────
echo "==> Downloading ALB Controller IAM policy..."
curl -sS -o /tmp/alb-iam-policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.1/docs/install/iam_policy.json

echo "==> Creating IAM policy..."
ALB_POLICY_ARN=$(aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file:///tmp/alb-iam-policy.json \
  --query 'Policy.Arn' \
  --output text 2>/dev/null || \
  aws iam list-policies \
    --query "Policies[?PolicyName=='AWSLoadBalancerControllerIAMPolicy'].Arn" \
    --output text)

echo "    Policy ARN: ${ALB_POLICY_ARN}"

# ── Step 2: Create IAM role + service account via eksctl or manually ──────────
echo ""
echo "==> Creating IAM service account for ALB controller..."

# Get OIDC issuer from the cluster
OIDC_ISSUER=$(aws eks describe-cluster \
  --name "${CLUSTER_NAME}" \
  --region "${AWS_REGION}" \
  --query "cluster.identity.oidc.issuer" \
  --output text | sed 's|https://||')

# Create the trust policy
cat > /tmp/alb-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_ISSUER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_ISSUER}:sub": "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT_NAME}",
          "${OIDC_ISSUER}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF

# Create the IAM role
ALB_ROLE_ARN=$(aws iam create-role \
  --role-name "${CLUSTER_NAME}-alb-controller-role" \
  --assume-role-policy-document file:///tmp/alb-trust-policy.json \
  --query 'Role.Arn' \
  --output text 2>/dev/null || \
  aws iam get-role \
    --role-name "${CLUSTER_NAME}-alb-controller-role" \
    --query 'Role.Arn' \
    --output text)

echo "    Role ARN: ${ALB_ROLE_ARN}"

# Attach the policy
aws iam attach-role-policy \
  --role-name "${CLUSTER_NAME}-alb-controller-role" \
  --policy-arn "${ALB_POLICY_ARN}" 2>/dev/null || true

# ── Step 3: Create Kubernetes service account ─────────────────────────────────
echo ""
echo "==> Creating Kubernetes service account..."
kubectl create serviceaccount "${SERVICE_ACCOUNT_NAME}" \
  -n "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

kubectl annotate serviceaccount "${SERVICE_ACCOUNT_NAME}" \
  -n "${NAMESPACE}" \
  eks.amazonaws.com/role-arn="${ALB_ROLE_ARN}" \
  --overwrite

# ── Step 4: Install via Helm ──────────────────────────────────────────────────
echo ""
echo "==> Adding eks Helm repo..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

echo ""
echo "==> Installing AWS Load Balancer Controller..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n "${NAMESPACE}" \
  --set clusterName="${CLUSTER_NAME}" \
  --set serviceAccount.create=false \
  --set serviceAccount.name="${SERVICE_ACCOUNT_NAME}" \
  --set region="${AWS_REGION}" \
  --set vpcId="$(aws eks describe-cluster \
    --name "${CLUSTER_NAME}" \
    --region "${AWS_REGION}" \
    --query 'cluster.resourcesVpcConfig.vpcId' \
    --output text)" \
  --wait

# ── Step 5: Verify ────────────────────────────────────────────────────────────
echo ""
echo "==> Verifying controller is running..."
kubectl get deployment aws-load-balancer-controller -n "${NAMESPACE}"

echo ""
echo "✓ AWS Load Balancer Controller installed successfully!"
echo ""
echo "Next: kubectl apply -k k8s/"
