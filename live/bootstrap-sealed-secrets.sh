#!/bin/bash

set -x

# Check Deploy Repositroy Path
SO1S_REGEX="^(.+)\/([^\/]+)$"
while [[ ! $SO1S_DEPLOY_REPO_PATH =~ $SO1S_REGEX ]]
do
  echo -e "Deploy Repository 경로를 입력 해주세요."
  read SO1S_DEPLOY_REPO_PATH
done

echo "Inject Sealed Secret Certificate"
kubectl apply -f $SO1S_DEPLOY_REPO_PATH/cert.yaml --wait
kubectl rollout restart deployment -n sealed-secrets so1s-sealed-secrets

kubectl wait --for condition=Available=True -n sealed-secrets deployment/so1s-sealed-secrets --timeout=2m