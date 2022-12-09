<div align="center">

<img src="https://raw.githubusercontent.com/so1s/.github/main/static/logo.png" alt="So1s Logo" width="50%" />

# So1s Infrastructure as Code

Terraform 기반 EKS 클러스터 구성

[프로젝트 소개 페이지로 돌아가기](https://github.com/so1s)

</div>

## 주요 기능

- EKS 기반 Multi Node 쿠버네티스 클러스터 프로비저닝 기능 지원
- Public / Application / Library / Database / Model Builder Node Group으로 나뉘어진 Node 분리 및 Taint 지원
- 네트워크 보안을 위한 VPC Public / Private Subnet 분리
- ELB와 TLS 인증서 연동을 위한 IAM Role 생성 기능 지원
- Bootstrap Script 개발을 통한 편리한 프로비저닝 지원
- Accelerated AMI를 통한 GPU 노드 생성 기능 지원
- 비용 절감을 위한 EC2 Spot Instance 모드 선택 기능 지원

## 사용 기술

- HCL / Terraform
- AWS EKS
- AWS EC2
- AWS VPC
- AWS IAM
- AWS ELB
- AWS S3

## 사용 방법

[프로비저닝 매뉴얼 보러가기](./live/README.md)

이 레포는 Public Template으로 제공됩니다. 보일러플레이트로 사용하시려면 상단의 `Use This Template` 버튼을 눌러주세요!
