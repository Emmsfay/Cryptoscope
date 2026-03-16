#!/usr/bin/env bash
# scripts/setup-github-oidc.sh
# Creates the IAM role that GitHub Actions assumes via OIDC (no long-lived keys)
# Usage: GITHUB_ORG=Emmsfay GITHUB_REPO=cryptoscope ./scripts/setup-github-oidc.sh

set -euo pipefail

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="${AWS_REGION:-us-east-1}"
GITHUB_ORG="${GITHUB_ORG:-Emmsfay}"
GITHUB_REPO="${GITHUB_REPO:-cryptoscope}"
ROLE_NAME="cryptoscope-github-actions-role"

echo "==> Creating GitHub OIDC provider..."
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  2>/dev/null || echo "    OIDC provider already exists"

echo "==> Creating IAM role: ${ROLE_NAME}"
cat > /tmp/github-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
      }
    }
  }]
}
EOF

ROLE_ARN=$(aws iam create-role \
  --role-name "${ROLE_NAME}" \
  --assume-role-policy-document file:///tmp/github-trust-policy.json \
  --query 'Role.Arn' --output text 2>/dev/null || \
  aws iam get-role --role-name "${ROLE_NAME}" --query 'Role.Arn' --output text)

echo "==> Attaching policies..."
for policy in \
  "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser" \
  "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"; do
  aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${policy}" 2>/dev/null || true
done

# Allow kubectl access to EKS
cat > /tmp/eks-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["eks:DescribeCluster", "eks:ListClusters"],
    "Resource": "*"
  }]
}
EOF

aws iam put-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name "EKSAccess" \
  --policy-document file:///tmp/eks-policy.json

echo ""
echo "✓ Done! Add this to GitHub Secrets:"
echo ""
echo "  Secret name:  AWS_DEPLOY_ROLE_ARN"
echo "  Secret value: ${ROLE_ARN}"
echo ""
echo "Also run this to grant the role kubectl access:"
echo ""
echo "  kubectl edit configmap aws-auth -n kube-system"
echo ""
echo "  Add under mapRoles:"
echo "  - rolearn: ${ROLE_ARN}"
echo "    username: github-actions"
echo "    groups:"
echo "      - system:masters"
