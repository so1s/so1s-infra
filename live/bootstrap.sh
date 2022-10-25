#!/bin/bash

SO1S_REGEX="^[1-2]$"
while [[ ! $SO1S_ENV_NUMBER =~ $SO1S_REGEX ]]
do
  echo -e "어떤 환경으로 개발을 할 것인지 번호를 입력 해주세요. \n-> (1) prod (2) dev "
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
  echo "Terraform에 적용 할 GLOBAL_NAME을 설정해주세요."
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

SO1S_REGEX="^[1-2]$"
while [[ ! $SO1S_USE_GPU =~ $SO1S_REGEX ]]
do
  echo -e "Inference Server에서 GPU를 사용할 것인지 번호를 입력해주세요. \n-> (1) 미사용 (2) 사용 "
  read SO1S_USE_GPU
done

# 환경에 따른 글로벌 이름 설정 -> Prod은 고정 값
if [ $SO1S_USE_GPU -eq 2 ]; then
  INFERENCE_INSTANCE='["g4dn.xlarge"]'
elif [ $SO1S_USE_GPU -eq 1 ]; then
  INFERENCE_INSTANCE='["t3a.large"]'
fi

while [[ ! $SO1S_USE_GPU_IN_BUILDER =~ $SO1S_REGEX ]]
do
  echo -e "Builder에서 GPU를 사용할 것인지 번호를 입력해주세요. \n-> (1) 미사용 (2) 사용 "
  read SO1S_USE_GPU_IN_BUILDER
done

# 환경에 따른 글로벌 이름 설정 -> Prod은 고정 값
if [ $SO1S_USE_GPU_IN_BUILDER -eq 2 ]; then
  BUILDER_INSTANCE='["g4dn.xlarge"]'
elif [ $SO1S_USE_GPU_IN_BUILDER -eq 1 ]; then
  BUILDER_INSTANCE='["r6a.large"]'
fi

cd $SO1S_ENV_PATH

# Check Terraform Version
if [ terraform != 0 ]; then
  echo "Your Terraform Version -> " `terraform version | head -n 1`
fi

echo -e "\n"
echo "Terraform Initialize"
if [ $SO1S_ENV_NUMBER -eq 1 ]; then
  echo "terraform init"
  terraform init
elif [ $SO1S_ENV_NUMBER -eq 2 ]; then
  echo "-> terraform init -backend-config=key=live/dev/$SO1S_GLOBAL_NAME"
  terraform init -backend-config="key=live/dev/$SO1S_GLOBAL_NAME"
fi

echo -e "\n"
echo "Start Resource Provisioning"
echo "-> terraform apply -var=global_name=$SO1S_GLOBAL_NAME"
terraform apply -var="global_name=$SO1S_GLOBAL_NAME" -var="inference_node_instance_types=$INFERENCE_INSTANCE" -var="model_builder_node_instance_types=$BUILDER_INSTANCE"

# Using for ALB, External DNS Chart
RESULT=`terraform output`
CLUSTER_NAME=`echo -e $RESULT | grep cluster_id | cut -d '"' -f2`
echo $CLUSTER_NAME
ROLE_ARN=`echo -e $RESULT | grep external_dns_role_arn | cut -d '"' -f4`
echo $ROLE_ARN
VPC_ID=`echo -e $RESULT | grep vpc_id | cut -d '"' -f6`
echo $VPC_ID

[[ $SO1S_ENV_NUMBER = 1 ]] && SO1S_CLUSTER_NAME="$SO1S_GLOBAL_NAME-so1s" || SO1S_CLUSTER_NAME="$SO1S_GLOBAL_NAME-so1s-dev"

echo -e "\n"
echo "Update KubeConfig"
echo "-> aws eks update-kubeconfig --region "ap-northeast-2" --name "$SO1S_CLUSTER_NAME" --alias $SO1S_GLOBAL_NAME"
aws eks update-kubeconfig --region "ap-northeast-2" --name "$SO1S_CLUSTER_NAME" --alias $SO1S_GLOBAL_NAME
kubectl config use-context $SO1S_GLOBAL_NAME

# Check Helm Version
if [ helm != 0 ]; then
  echo -e "\n"
  echo "Your Helm Version -> " `helm version --short | head -n 1`
fi

if [ $SO1S_ENV_NUMBER -eq 1 ]; then
  # install alb chart
  echo -e "\n"
  echo "Install ALB"
  echo "-> helm install alb -n kube-system -f $SO1S_DEPLOY_REPO_PATH/charts/public/aws-load-balancer-controller/dev-values.yaml eks/aws-load-balancer-controller --create-namespace --wait --set clusterName=$CLUSTER_NAME --set vpcId=$VPC_ID"
  helm install alb -n kube-system -f $SO1S_DEPLOY_REPO_PATH/charts/public/aws-load-balancer-controller/dev-values.yaml eks/aws-load-balancer-controller --create-namespace --wait --set clusterName=$CLUSTER_NAME --set vpcId=$VPC_ID

  # install external-dns chart
  echo "Install external-dns"
  echo "-> helm install external-dns -n kube-system -f $SO1S_DEPLOY_REPO_PATH/charts/public/external-dns/dev-values.yaml $SO1S_DEPLOY_REPO_PATH/charts/public/external-dns --create-namespace --wait --set serviceAccount.roleArn=$ROLE_ARN"
  helm install external-dns -n kube-system -f $SO1S_DEPLOY_REPO_PATH/charts/public/external-dns/dev-values.yaml $SO1S_DEPLOY_REPO_PATH/charts/public/external-dns --create-namespace --wait --set serviceAccount.roleArn=$ROLE_ARN
fi

# install argocd 
echo -e "\n"
echo "Install ArgoCD"
echo "-> helm install argocd -n argocd -f $SO1S_DEPLOY_REPO_PATH/charts/argocd/argocd-$SO1S_ENV_NAME-values.yaml argo/argo-cd --create-namespace --wait"
HAVE_ARGO_HELM_REPO=`helm repo list | grep "https://argoproj.github.io/argo-helm"`
  if [ HAVE_ARGO_HELM_REPO ]; then
    echo `helm repo add argo https://argoproj.github.io/argo-helm`
  fi
helm install argocd -n argocd -f $SO1S_DEPLOY_REPO_PATH/charts/argocd/argocd-$SO1S_ENV_NAME-values.yaml argo/argo-cd --create-namespace --wait

echo -e "\n\n"
echo "ArgoCD Password -> " `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

if [ $SO1S_USE_GPU -eq 2 ] || [ $SO1S_USE_GPU_IN_BUILDER -eq 2 ]; then
  echo -e "\n"
  echo "Start GPU Setting"
  echo "-> helm install "
  HAVE_GPU_HELM_REPO=`helm repo list | grep "https://nvidia.github.io/gpu-operator"`
  if [ HAVE_GPU_HELM_REPO ]; then
    echo `helm repo add nvidia https://nvidia.github.io/gpu-operator`
  fi
  helm install gpu -n gpu -f $SO1S_DEPLOY_REPO_PATH/charts/extension/gpu/$SO1S_ENV_NAME-values.yaml $SO1S_DEPLOY_REPO_PATH/charts/extension/gpu --create-namespace --wait
fi


# Create argocd project resource
echo -e "\n"
echo "Create ArgoCD Project Resource"
echo "-> kubectl apply -f $SO1S_DEPLOY_REPO_PATH/project/project-$SO1S_ENV_NAME.yaml"
kubectl apply -f $SO1S_DEPLOY_REPO_PATH/project/project-$SO1S_ENV_NAME.yaml --wait

# Run root application
echo -e "\n"
echo "Run root-$SO1S_ENV_NAME.yaml application"
echo "-> kubectl apply -f $SO1S_DEPLOY_REPO_PATH/root-$SO1S_ENV_NAME.yaml"
kubectl apply -f $SO1S_DEPLOY_REPO_PATH/root-$SO1S_ENV_NAME.yaml --wait
