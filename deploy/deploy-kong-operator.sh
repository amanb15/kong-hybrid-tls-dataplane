#!/bin/bash
set -e

ENV_NAME=$1
if [ -z "$ENV_NAME" ]; then
  echo "Usage: ./deploy-kong-operator.sh <env>"
  exit 1
fi

source ../env/${ENV_NAME}.env

echo "Connecting to cluster..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$LOCATION --project=$PROJECT_ID
kubectl get nodes

echo "Adding Kong Helm repo..."
helm repo add kong https://charts.konghq.com
helm repo update

echo "Creating namespace $OPERATOR_NAMESPACE..."
kubectl create namespace $OPERATOR_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "Installing Kong Operator..."
helm upgrade --install kong-operator kong/kong-operator \
  --create-namespace -n $OPERATOR_NAMESPACE \
  --set env.ENABLE_CONTROLLER_KONNECT=true \
  --set replicaCount=$OPERATOR_REPLICAS \
  --set image.tag=$OPERATOR_IMAGE_TAG \
  --skip-crds

kubectl -n $OPERATOR_NAMESPACE rollout status deployment/kong-operator-kong-operator-controller-manager
kubectl get pods -n $OPERATOR_NAMESPACE
