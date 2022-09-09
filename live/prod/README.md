## SO1S 프로덕션 환경 사용법 - v0.1.0

bootstrap.sh을 통해 쉽게 개발 환경 구축이 가능합니다.

다음과 같은 사전 설치 조건이 필요합니다.

1. kubernetes 1.22+
2. Terraform 4.28.0
3. KubeSeal 0.18.1
4. helm 3.8.2
5. helm repo argo (argo-cd 5.4.1)
6. aws cli 혹은 aws 시크릿 키를 export하기 -> export AWS_ACCESS_KEY_ID="anaccesskey", export AWS_SECRET_ACCESS_KEY="asecretkey"

하나라도 설치가 안되어 있을 시 쉘 스크립트가 정상동작을 안하니 유의해주시길 바랍니다.

```bash
# =====================
# 사전 환경 작업
chmod +x ./bootstrap.sh
chmod +x ./clean-up.sh

export SO1S_DEPLOY_REPO_PATH=<DEPLOY_REPO_PATH>

# Terraform 프로비저닝
./bootstrap.sh

# ArgoCD Sealed-Secret 어플리케이션이 정상적으로 동작한 다음 실행
./bootstrap-sealed-secret.sh


# 클러스터 삭제
./clean-up.sh

```

각종 이슈 신고는 지라로 받겠습니다.
