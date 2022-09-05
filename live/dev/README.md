## SO1S 개발 환경 사용법 - v0.1.0

bootstrap.sh을 통해 쉽게 개발 환경 구축이 가능합니다.

다음과 같은 사전 설치 조건이 필요합니다.

1. kubernetes 1.22+
2. Terraform 4.28.0
3. KubeSeal 0.18.1
4. helm 3.8.2
5. helm repo argo (argo-cd 5.4.1)

하나라도 설치가 안되어 있을 시 쉘 스크립트가 정상동작을 안하니 유의해주시길 바랍니다.

```bash
chmod 777 ./bootstrap.sh

export SO1S_GLOBAL_NAME=<GLOBAL_NAME>

export SO1S_DEPLOY_REPO_PATH=<DEPLOY_REPO_PATH>

./bootstrap.sh

# argocd ui 포트포워딩
kubectl port-forward service/argocd-server -n argocd 8080:443

# sealed-secret chart, backend chart 실행 후 사용
./bootstrap-sealed-secrets.sh


# 종료시
helm uninstall argocd -n argocd
terraform destroy

```

각종 이슈 신고는 지라로 받겠습니다.
