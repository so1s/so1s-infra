## Terraform을 통한 EKS 클러스터 구성 매뉴얼

### Requirements

1. Kubernetes 1.22+
2. Helm
3. Terraform
4. AWS CLI version 2

### 환경 변수 설정

```bash
# ~/.bashrc | ~/.zshrc
export AWS_ACCESS_KEY_ID=${ID}
export AWS_SECRET_ACCESS_KEY=${SECRET_KEY}

# 1 - prod | 2 - env
SO1S_ENV_NUMBER=${"1" | "2"}
# ex) ~/programming/so1s/so1s-deploy
SO1S_DEPLOY_REPO_PATH=${ABSOLUTE_DEPLOY_REPO_PATH}
```

### Development 클러스터 프로비저닝

```bash
# =====================
# Terraform 프로비저닝
./bootstrap.sh

# ArgoCD UI 포트포워딩
kubectl port-forward service/argocd-server -n argocd 8080:443

# Sealed-Secret 인증서 주입
./bootstrap-sealed-secret.sh

# Istio Gateway 포트포워딩
kubectl port-forward -n istio-system svc/istio 9443:80

# =====================

# Istio Gateway를 로컬에서 확인하기 위해 포트포워딩이 필요합니다.
# 서브도메인을 개별적으로 /etc/hosts에 작성하거나, dnsmasq를 사용하는 방법이 있습니다.
# 두개 중 하나의 방법만 적용하시면 됩니다.

# 1 - /etc/hosts 사용

# sudo vim /etc/hosts
# 사용하고자 하는 서브도메인을 작성해 주세요.
# ...
127.0.0.1 test-www.so1s.io
# ...

# 2 - dnsmasq 사용

# https://serverfault.com/a/569936

brew install dnsmasq

# vim /etc/resolv.conf
nameserver 127.0.0.1

# vim /etc/dnsmasq.conf
listen-address=127.0.0.1
address=/so1s.io/127.0.0.1
address=/*.so1s.io/127.0.0.1

sudo brew services stop dnsmasq
sudo brew services start dnsmasq


# =====================

# 접속 확인은 이렇게 하실 수 있습니다.

# 1 - dig 사용

dig test-www.so1s.io

# 2 - 브라우저 사용

http://test-www.so1s.io:9443

# =====================


# 클러스터 삭제
./clean-up.sh

```


### Production 클러스터 프로비저닝

```bash

# Terraform 프로비저닝
./bootstrap.sh

# Sealed-Secret 인증서 주입
./bootstrap-sealed-secret.sh

# 클러스터 삭제
./clean-up.sh
```

### Kiali 토큰 확인

```bash
kubectl get secret -n istio-system $(kubectl get secret -n istio-system --no-headers -o custom-columns=":metadata.name" | grep kiali-token) -o jsonpath={.data.token} | base64 -d
```

### Sealed Secrets 인증서 보관 / 재사용

여러번의 클러스터 프로비저닝을 하며, 같은 인증서로 암호화된 Sealed Secrets를 쓰기 위해서는 현재 클러스터의 인증서를 로컬에 보관해야 합니다.

```bash
kubectl get secret -n sealed-secrets -o name | grep sealed-secrets-key | kubectl get secret -n sealed-secrets -o yaml > ./cert.yaml
```

추출된 cert.yaml을 로컬 Deploy 폴더 루트 경로에 보관해 주세요.

이 인증서를 기반으로 [Deploy Sealed Secrets](https://github.com/so1s/so1s-deploy) 암호화가 가능합니다.

다른 클러스터에 Sealed Secrets 인증서를 주입하려면 현재 kubectl context를 주입할 클러스터로 변경한 뒤 이 명령어를 입력해 주세요.

```bash
./bootstrap-sealed-secret.sh
```
