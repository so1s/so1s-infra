#!/bin/bash

# terraform existing check
if [ terraform != 0 ]; then
  echo "Your Terraform Version -> " `terraform version | head -n 1`
fi

# Check Deploy Repositroy Path
if [ -z $SO1S_DEPLOY_REPO_PATH ]; then
  echo "Please Set Deploy Repository Path using command 'export SO1S_DEPLOY_REPO_PATH=<DEPLOY_REPO_PATH>'"
  exit 1
else
  echo "Complete Check DEPLOY_REPO_PATH Variable -> $SO1S_DEPLOY_REPO_PATH"
fi

echo -e "\n\n"
echo "Terraform Initialize"
echo "-> terraform init"
terraform init

echo -e "\n"
echo "Terraform Initialize"
echo "-> terraform apply"
terraform apply
RESULT=`terraform apply`
CLUSTER_NAME=`echo $RESULT | grep cluster_id | cut -d '"' -f2`
echo $CLUSTER_NAME
VPC_ID=`echo $RESULT | grep vpc_id | cut -d '"' -f2`
echo $VPC_ID
ROLE_ARN=`echo $RESULT | grep external_dns_role_arn | cut -d ' ' -f3`
echo $ROLE_ARN


echo -e "\n\n"
echo "Update KubeConfig"
echo "-> aws eks update-kubeconfig --region "ap-northeast-2" --name "prod-so1s" --alias prod-so1s"
aws eks update-kubeconfig --region "ap-northeast-2" --name "prod-so1s" --alias prod-so1s
kubectl config use-context prod-so1s

echo -e "\n\n"

# helm existing check
if [ helm != 0 ]; then
  echo "Your Helm Version -> " `helm version --short | head -n 1`
  echo -e "\n"
fi

# install alb chart
echo "Install ALB"
helm install alb -n kube-system -f $SO1S_DEPLOY_REPO_PATH/charts/public/aws-load-balancer-controller/dev-values.yaml eks/aws-load-balancer-controller --create-namespace --wait --set clusterName=$CLUSTER_NAME --set vpcId=$VPC_ID

# install external-dns chart
echo "Install external-dns"
helm install external-dns -n kube-system -f $SO1S_DEPLOY_REPO_PATH/charts/public/external-dns/dev-values.yaml $SO1S_DEPLOY_REPO_PATH/charts/public/external-dns --create-namespace --wait --set serviceAccount.roleArn=$ROLE_ARN

# install argocd 
echo "Install ArgoCD"
echo "-> helm install argocd -n argocd -f $SO1S_DEPLOY_REPO_PATH/charts/argocd/argocd-prod-values.yaml argo/argo-cd --create-namespace --wait"
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd -n argocd -f $SO1S_DEPLOY_REPO_PATH/charts/argocd/argocd-prod-values.yaml argo/argo-cd --create-namespace --wait

echo -e "\n\n"
echo "ArgoCD Password -> " `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

# create argocd project resource
echo -e "\n\n"
echo "Create ArgoCD Project Resource"
echo "-> kubectl apply -f $SO1S_DEPLOY_REPO_PATH/project/project-prod.yaml"
kubectl apply -f $SO1S_DEPLOY_REPO_PATH/project/project-prod.yaml --wait

# run root application
echo -e "\n\n"
echo "Run root-prod.yaml application"
echo "-> kubectl apply -f $SO1S_DEPLOY_REPO_PATH/root-prod.yaml"
kubectl apply -f $SO1S_DEPLOY_REPO_PATH/root-prod.yaml --wait
