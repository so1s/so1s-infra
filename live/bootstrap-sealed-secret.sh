#!/bin/bash

# Check Deploy Repositroy Path
SO1S_REGEX="^(.+)\/([^\/]+)$"
while [[ ! $SO1S_DEPLOY_REPO_PATH =~ $SO1S_REGEX ]]
do
  echo -e "Deploy Repository 경로를 입력 해주세요."
  read SO1S_DEPLOY_REPO_PATH
done

echo -e "\n\n"
echo "Inject Sealed Secret Certificate"
echo "-> kubectl apply -f $SO1S_DEPLOY_REPO_PATH/cert.yaml"
kubectl apply -f $SO1S_DEPLOY_REPO_PATH/cert.yaml --wait
kubectl rollout restart deployment -n sealed-secrets so1s-sealed-secrets
echo "Wait for Sealed-Secret to be created"
sleep 10
DEPLOYMENT_NAME=`kubectl get deployment -n backend | grep so1s | cut -d ' ' -f1`
kubectl rollout restart deployment -n backend $DEPLOYMENT_NAME 
kubectl rollout restart deployment -n frontend frontend

echo "Rollout Istio Deployment"
kubectl config set-context --current --namespace=argocd
argocd app sync so1s-istio-app-prod --core --prune --replace --force
kubectl config set-context --current --namespace=default