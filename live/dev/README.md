## SO1S 개발 환경 사용법 - v0.1.0

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
chmod 777 ./bootstrap.sh
chmod 777 ./clean-up.sh

export SO1S_GLOBAL_NAME=<GLOBAL_NAME>

export SO1S_DEPLOY_REPO_PATH=<DEPLOY_REPO_PATH>

# Terraform 프로비저닝
./bootstrap.sh

# ArgoCD UI 포트포워딩
kubectl port-forward service/argocd-server -n argocd 8080:443

# Istio Gateway 포트포워딩
kubectl port-forward -n istio-system svc/istio 9443:80

# =====================

# Istio Gateway를 로컬에서 확인하기 위해 포트포워딩이 필요합니다.
# 서브도메인을 개별적으로 /etc/hosts에 작성하거나, dnsmasq를 사용하는 방법이 있습니다.
# 두개 중 하나의 방법만 적용하시면 됩니다.

# 1 - /etc/hosts 사용

# vim /etc/hosts
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

# dig test-www.so1s.io
# 
# ; <<>> DiG 9.18.1-1ubuntu1.1-Ubuntu <<>> test-www.so1s.io
# ;; global options: +cmd
# ;; Got answer:
# ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 21457
# ;; flags: qr aa rd ra ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

# ;; OPT PSEUDOSECTION:
# ; EDNS: version: 0, flags:; udp: 65494
# ;; QUESTION SECTION:
# ;test-www.so1s.io.              IN      A

# ;; ANSWER SECTION:
# test-www.so1s.io.       0       IN      A       127.0.0.1

# ;; Query time: 0 msec
# ;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
# ;; WHEN: Wed Sep 07 20:32:27 KST 2022
# ;; MSG SIZE  rcvd: 61

# 2 - 브라우저 사용

http://test-www.so1s.io:9443

# =====================


# 클러스터 삭제
./clean-up.sh

```

각종 이슈 신고는 지라로 받겠습니다.
