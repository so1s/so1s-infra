kubectl delete -f $SO1S_DEPLOY_REPO_PATH/root-prod.yaml --wait
kubectl delete -f $SO1S_DEPLOY_REPO_PATH/project/project-prod.yaml --wait

helm uninstall argocd -n argocd

terraform destroy
