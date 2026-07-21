#!/bin/bash
set -e

ENV_NAME=$1
if [ -z "$ENV_NAME" ]; then
  echo "Usage: ./kong-gateway-dataplanedeploy.sh <env>"
  exit 1
fi

./deploy-kong-operator.sh $ENV_NAME
./deploy-kong-gateway.sh $ENV_NAME
