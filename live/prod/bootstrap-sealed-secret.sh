#!/bin/bash

# Check Deploy Repositroy Path
if [ -z $SO1S_DEPLOY_REPO_PATH ]; then
  echo "Please Set Deploy Repository Path using command 'export SO1S_DEPLOY_REPO_PATH=<DEPLOY_REPO_PATH>'"
  exit 1
else
  echo "Complete Check DEPLOY_REPO_PATH Variable -> $SO1S_DEPLOY_REPO_PATH"
fi

echo -e "\n\n"
echo "Inject Sealed Secret Certificate"
echo "-> kubectl apply -f $SO1S_DEPLOY_REPO_PATH/cert.yaml"
kubectl apply -f $SO1S_DEPLOY_REPO_PATH/cert.yaml --wait
kubectl rollout restart deployment -n sealed-secrets so1s-sealed-secrets
# IMAGE PULL ERROR난 backend deployment의 Replicas를 지우고 다시 생성한다.
echo "Wait for Sealed-Secret to be created"
sleep 10
REPLICA_NAME=`kubectl get deployment -n backend | grep so1s | cut -d ' ' -f1`
kubectl rollout restart deployment -n backend $REPLICA_NAME 