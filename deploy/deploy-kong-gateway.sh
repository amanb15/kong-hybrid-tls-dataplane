#!/bin/bash
set -e

ENV_NAME=$1
CERT_FILE=$2
KEY_FILE=$3
if [ -z "$ENV_NAME" ] || [ -z "$CERT_FILE" ] || [ -z "$KEY_FILE" ]; then
  echo "Usage: ./deploy-kong-gateway.sh <env> <tls.crt path> <tls.key path>"
  exit 1
fi

source ../env/${ENV_NAME}.env
MANIFEST_DIR=../manifests/gateway

echo "Creating namespace $NAMESPACE..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "Creating cert secret $CLUSTER_CERT_SECRET_NAME..."
kubectl create secret generic $CLUSTER_CERT_SECRET_NAME \
  --from-file=tls.crt=$CERT_FILE \
  --from-file=tls.key=$KEY_FILE \
  -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "Applying GatewayConfiguration..."
sed \
  -e "s|NAMESPACE_PLACEHOLDER|$NAMESPACE|g" \
  -e "s|GATEWAY_CONFIG_NAME_PLACEHOLDER|$GATEWAY_CONFIG_NAME|g" \
  -e "s|DATAPLANE_REPLICAS_PLACEHOLDER|$DATAPLANE_REPLICAS|g" \
  -e "s|IMAGE_PATH_PLACEHOLDER|$IMAGE_PATH|g" \
  -e "s|CLUSTER_CONTROL_PLANE_PLACEHOLDER|$CLUSTER_CONTROL_PLANE|g" \
  -e "s|CLUSTER_SERVER_NAME_PLACEHOLDER|$CLUSTER_SERVER_NAME|g" \
  -e "s|CLUSTER_TELEMETRY_ENDPOINT_PLACEHOLDER|$CLUSTER_TELEMETRY_ENDPOINT|g" \
  -e "s|CLUSTER_TELEMETRY_SERVER_NAME_PLACEHOLDER|$CLUSTER_TELEMETRY_SERVER_NAME|g" \
  -e "s|DATAPLANE_CPU_REQUEST_PLACEHOLDER|$DATAPLANE_CPU_REQUEST|g" \
  -e "s|DATAPLANE_MEMORY_REQUEST_PLACEHOLDER|$DATAPLANE_MEMORY_REQUEST|g" \
  -e "s|DATAPLANE_CPU_LIMIT_PLACEHOLDER|$DATAPLANE_CPU_LIMIT|g" \
  -e "s|DATAPLANE_MEMORY_LIMIT_PLACEHOLDER|$DATAPLANE_MEMORY_LIMIT|g" \
  -e "s|CERT_SECRET_NAME_PLACEHOLDER|$CLUSTER_CERT_SECRET_NAME|g" \
  -e "s|INGRESS_SERVICE_TYPE_PLACEHOLDER|$INGRESS_SERVICE_TYPE|g" \
  $MANIFEST_DIR/gateway-config.yaml | kubectl apply -f -

echo "Applying GatewayClass..."
sed \
  -e "s|NAMESPACE_PLACEHOLDER|$NAMESPACE|g" \
  -e "s|GATEWAY_CLASS_NAME_PLACEHOLDER|$GATEWAY_CLASS_NAME|g" \
  -e "s|GATEWAY_CONFIG_NAME_PLACEHOLDER|$GATEWAY_CONFIG_NAME|g" \
  $MANIFEST_DIR/gatewayclass.yaml | kubectl apply -f -

echo "Applying Gateway..."
sed \
  -e "s|NAMESPACE_PLACEHOLDER|$NAMESPACE|g" \
  -e "s|GATEWAY_NAME_PLACEHOLDER|$GATEWAY_NAME|g" \
  -e "s|GATEWAY_CLASS_NAME_PLACEHOLDER|$GATEWAY_CLASS_NAME|g" \
  $MANIFEST_DIR/gateway.yaml | kubectl apply -f -

sleep 30
kubectl get all -n $NAMESPACE
kubectl get gateway -n $NAMESPACE
kubectl get dataplane -n $NAMESPACE
