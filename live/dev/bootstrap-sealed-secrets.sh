# Check Deploy Repositroy Path
if [ -z $SO1S_DEPLOY_REPO_PATH ]; then
  echo "Please Set Deploy Repository Path using command 'export SO1S_DEPLOY_REPO_PATH=<DEPLOY_REPO_PATH>'"
  exit 1
else
  echo "Complete Check DEPLOY_REPO_PATH Variable -> $SO1S_DEPLOY_REPO_PATH"
fi


# create sealed secrets
echo -e "\n\n"
echo "Create Sealed Secret"
kubectl create secret generic application-secret --dry-run=client --from-env-file=$SO1S_DEPLOY_REPO_PATH/secrets.env -o json > $SO1S_DEPLOY_REPO_PATH/secrets.json
kubeseal --controller-name so1s-sealed-secrets --controller-namespace sealed-secrets --scope cluster-wide -o yaml < $SO1S_DEPLOY_REPO_PATH/secrets.json > $SO1S_DEPLOY_REPO_PATH/sealed-secret.yaml

kubectl create secret docker-registry so1s --dry-run=client --from-file=.dockerconfigjson=$SO1S_DEPLOY_REPO_PATH/docker-config.json -o json > $SO1S_DEPLOY_REPO_PATH/docker-pull-secret.json
kubeseal --controller-name so1s-sealed-secrets --controller-namespace sealed-secrets --scope cluster-wide -o yaml < $SO1S_DEPLOY_REPO_PATH/docker-pull-secret.json > $SO1S_DEPLOY_REPO_PATH/docker-pull-secret.yaml

kubectl apply -f $SO1S_DEPLOY_REPO_PATH/sealed-secret.yaml -n backend
kubectl apply -f $SO1S_DEPLOY_REPO_PATH/docker-pull-secret.yaml -n backend