# terraform variables check
if [ -z $SO1S_GLOBAL_NAME ]; then
  echo "Please Set global name using command 'export SO1S_GLOBAL_NAME=<GLOBAL_NAME>'"
  exit 1
else
  echo "Complete Check global_name Variable -> $SO1S_GLOBAL_NAME"
fi

kubectl delete -f $SO1S_DEPLOY_REPO_PATH/root-prod.yaml --wait
kubectl delete -f $SO1S_DEPLOY_REPO_PATH/project/project-prod.yaml --wait

helm uninstall argocd -n argocd

terraform destroy -var="global_name=$SO1S_GLOBAL_NAME"
