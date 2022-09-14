#!/bin/bash

SO1S_REGEX="^[1-2]$"
while [[ ! $SO1S_ENV_NUMBER =~ $SO1S_REGEX ]]
do
  echo -e "어떤 개발 환경을 삭제 할 것인지 번호를 입력 해주세요. \n-> (1) prod (2) dev "
  read SO1S_ENV_NUMBER
done

echo -e "\n"

SO1S_REGEX="^(.+)\/([^\/]+)$"
while [[ ! $SO1S_DEPLOY_REPO_PATH =~ $SO1S_REGEX ]]
do
  echo -e "Deploy Repository 경로를 입력 해주세요."
  read SO1S_DEPLOY_REPO_PATH
done

# 환경에 따른 글로벌 이름 설정 -> Prod은 고정 값
if [ $SO1S_ENV_NUMBER -eq 2 ]; then
  echo -e "\n"
  echo "Terraform에서 삭제 할 GLOBAL_NAME을 설정해주세요."
  read SO1S_GLOBAL_NAME
  # 추후 values.yaml 환경 지정을 위한 설정
  SO1S_ENV_NAME="dev"
  SO1S_ENV_PATH="./dev"
elif [ $SO1S_ENV_NUMBER -eq 1 ]; then
  SO1S_GLOBAL_NAME="prod"
  # 추후 values.yaml 환경 지정을 위한 설정
  SO1S_ENV_NAME="prod"
  SO1S_ENV_PATH="./prod"
fi

cd $SO1S_ENV_PATH

kubectl delete -f $SO1S_DEPLOY_REPO_PATH/root-$SO1S_ENV_NAME.yaml --wait
kubectl delete -f $SO1S_DEPLOY_REPO_PATH/project/project-$SO1S_ENV_NAME.yaml --wait

helm uninstall argocd -n argocd --wait

if [ $SO1S_ENV_NUMBER -eq 1 ]; then
  helm uninstall external-dns -n kube-system --wait
  helm uninstall alb -n kube-system --wait 
fi

terraform destroy -var="global_name=$SO1S_GLOBAL_NAME"
