#!/bin/bash

# Check Deploy Repositroy Path
if [ -z $SO1S_DEPLOY_REPO_PATH ]; then
  echo "Please Set Deploy Repository Path using command 'export SO1S_DEPLOY_REPO_PATH=<DEPLOY_REPO_PATH>'"
  exit 1
else
  echo "Complete Check DEPLOY_REPO_PATH Variable -> $SO1S_DEPLOY_REPO_PATH"
fi

echo -e "\n\n"
echo "Applying Certificate..."
kubectl apply -f $SO1S_DEPLOY_REPO_PATH/cert.yaml --wait
echo "Complete!"