#!/bin/bash
set -e

# Default values
ENVIRONMENT=${1:-}
VERSION=${2:-}
NAMESPACE=${3:-"airweave"}
USE_KEY_VAULT=${4:-"true"}

# Check required parameters
if [ -z "$ENVIRONMENT" ] || [ -z "$VERSION" ]; then
  echo "Usage: $0 <environment> <version> [namespace] [use_key_vault]"
  echo "  environment: Target environment (dev, stg, prd)"
  echo "  version: Version to deploy (e.g. v0.1.0)"
  echo "  namespace: Kubernetes namespace (default: airweave)"
  echo "  use_key_vault: Enable Azure Key Vault integration (default: true)"
  exit 1
fi

echo "Deploying version $VERSION to $ENVIRONMENT environment"
echo "Namespace: $NAMESPACE"
echo "Use Key Vault: $USE_KEY_VAULT"

# Determine resource group and cluster name
RESOURCE_GROUP="airweave-core-${ENVIRONMENT}-rg"
CLUSTER_NAME="airweave-core-${ENVIRONMENT}-aks"

# Check if az CLI is installed
if ! command -v az &> /dev/null; then
  echo "Error: Azure CLI is required but not installed. Please install it first."
  exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "Error: kubectl is required but not installed. Please install it first."
  exit 1
fi

# Azure login prompt (interactive)
echo "Please login to Azure..."
az login

# Get AKS credentials
echo "Getting AKS credentials for cluster $CLUSTER_NAME in $RESOURCE_GROUP..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing

# Run pre-deployment smoke tests for staging and production
if [ "$ENVIRONMENT" == "stg" ] || [ "$ENVIRONMENT" == "prd" ]; then
  echo "Running pre-deployment smoke tests for $ENVIRONMENT environment"
  # TODO: Add pre-deployment smoke test logic here
  # Example: kubectl apply -f tests/pre-deployment.yaml
fi

# Execute deployment
echo "Starting deployment of version $VERSION to $ENVIRONMENT..."

# TODO: Add your deployment logic here
# Examples:
# - Update image versions in Kubernetes manifests
# - Apply Kubernetes manifests
# - Trigger Helm chart installations

if [ "$USE_KEY_VAULT" == "true" ]; then
  echo "Using Azure Key Vault for secrets..."
  # TODO: Add Key Vault integration logic
fi

# Apply Kubernetes resources (example)
# kubectl apply -f kubernetes/$ENVIRONMENT/ -n $NAMESPACE

# Verify deployment
echo "Verifying deployment..."

# Check deployments and pods in the namespace
echo "Checking deployments in namespace $NAMESPACE:"
kubectl get deployments -n $NAMESPACE

echo "Checking pods in namespace $NAMESPACE:"
kubectl get pods -n $NAMESPACE

# Wait for deployments to be ready
echo "Waiting for frontend deployment to be ready..."
kubectl rollout status deployment/airweave-${ENVIRONMENT}-frontend -n $NAMESPACE --timeout=5m || echo "Frontend deployment not ready"

echo "Waiting for backend deployment to be ready..."
kubectl rollout status deployment/airweave-${ENVIRONMENT}-backend -n $NAMESPACE --timeout=5m || echo "Backend deployment not ready"

# Run post-deployment smoke tests for staging and production
if [ "$ENVIRONMENT" == "stg" ] || [ "$ENVIRONMENT" == "prd" ]; then
  echo "Running post-deployment smoke tests for $ENVIRONMENT environment"
  # TODO: Add post-deployment smoke test logic
  # Example: kubectl apply -f tests/smoke-tests.yaml
fi

# Send deployment status notification
DEPLOY_STATUS=$?
if [ $DEPLOY_STATUS -eq 0 ]; then
  echo "Deployment of version $VERSION to $ENVIRONMENT completed successfully"
else
  echo "Deployment of version $VERSION to $ENVIRONMENT failed with status: $DEPLOY_STATUS"
fi

# TODO: Add notification logic here (e.g., curl to send to Slack webhook)

exit $DEPLOY_STATUS 