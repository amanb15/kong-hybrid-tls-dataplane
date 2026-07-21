#!/bin/bash
set -e

ENV_NAME=$1
CERT_FILE=$2
KEY_FILE=$3
if [ -z "$ENV_NAME" ] || [ -z "$CERT_FILE" ] || [ -z "$KEY_FILE" ]; then
  echo "Usage: ./kong-gateway-dataplanedeploy.sh <env> <tls.crt path> <tls.key path>"
  exit 1
fi

./deploy-kong-operator.sh $ENV_NAME
./deploy-kong-gateway.sh $ENV_NAME $CERT_FILE $KEY_FILE
