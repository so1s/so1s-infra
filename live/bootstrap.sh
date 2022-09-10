#!/bin/bash

echo -e "어떤 환경으로 개발을 할 것인지 번호를 입력 해주세요. \n-> (1) prod (2) dev "
read NUMBER

echo -e "Deploy Repository 경로를 입력 해주세요."
read DEPLOY_REPO_PATH
export $DEPLOY_REPO_PATH

if [ -z $NUMBER ]; then
  echo "Terraform에 적용 할 GLOBAL_NAME을 설정해주세요."
  read GLOBAL_NAME
  export $GLOBAL_NAME
fi


if [ -z $NUMBER ]; then
    echo -e "\n\n"
    echo "Terraform Initialize"
    echo "-> terraform init -backend-config=key=live/dev/$SO1S_GLOBAL_NAME"
    terraform init -backend-config="key=live/dev/$SO1S_GLOBAL_NAME"

    echo -e "\n"
    echo "Terraform Initialize"
    echo "-> terraform apply -var=global_name=$SO1S_GLOBAL_NAME"
    terraform apply -var="global_name=$SO1S_GLOBAL_NAME"

    echo -e "\n\n"
    echo "Update KubeConfig"
    echo "-> aws eks update-kubeconfig --region "ap-northeast-2" --name "$SO1S_GLOBAL_NAME-so1s-dev" --alias $SO1S_GLOBAL_NAME"
    aws eks update-kubeconfig --region "ap-northeast-2" --name "$SO1S_GLOBAL_NAME-so1s-dev" --alias $SO1S_GLOBAL_NAME
    kubectl config use-context $SO1S_GLOBAL_NAME
else
    echo -e "\n\n"
    echo "Terraform Initialize"
    echo "-> terraform init"
    terraform init

    echo -e "\n"
    echo "Terraform Initialize"
    echo "-> terraform apply"
    terraform apply
    RESULT=`terraform apply`
    CLUSTER_NAME=`echo $RESULT | grep cluster_id | cut -d ' ' -f3`
    echo $CLUSTER_NAME
    VPC_ID=`echo $RESULT | grep vpc_id | cut -d ' ' -f3`
    echo $VPC_ID
    ROLE_ARN=`echo $RESULT | grep external_dns_role_arn | cut -d ' ' -f3`
    echo $ROLE_ARN


    echo -e "\n\n"
    echo "Update KubeConfig"
    echo "-> aws eks update-kubeconfig --region "ap-northeast-2" --name "prod-so1s" --alias prod-so1s"
    aws eks update-kubeconfig --region "ap-northeast-2" --name "prod-so1s" --alias prod-so1s
    kubectl config use-context prod-so1s
fi


