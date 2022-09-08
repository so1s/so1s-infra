# terraform variables check
if [ -z $SO1S_GLOBAL_NAME ]; then
  echo "Please Set global name using command 'export SO1S_GLOBAL_NAME=<GLOBAL_NAME>'"
  exit 1
else
  echo "Complete Check global_name Variable -> $SO1S_GLOBAL_NAME"
fi

kubectl config use-context $SO1S_GLOBAL_NAME

kubectl delete -f $SO1S_DEPLOY_REPO_PATH/root-dev.yaml --wait
kubectl delete -f $SO1S_DEPLOY_REPO_PATH/project/project-dev.yaml --wait

helm uninstall argocd -n argocd

terraform destroy -var="global_name=$SO1S_GLOBAL_NAME"
