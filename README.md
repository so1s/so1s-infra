<div align="center">

<img src="https://raw.githubusercontent.com/so1s/.github/main/static/logo.png" alt="So1s Logo" width="50%" />

# So1s Infrastructure as Code

Terraform 기반 EKS 클러스터 프로비저닝 스크립트

[프로젝트 소개 페이지로 돌아가기](https://github.com/so1s)

</div>

## 사용 방법

[매뉴얼 보러가기](./live/README.md)

## 주요 기능

- EKS 기반 Multi Node 쿠버네티스 클러스터 프로비저닝
- Public / Application / Library / Database / Model Builder Node Group으로 나뉘어진 Node 분리 및 Taint 지원
- 네트워크 보안을 위해 VPC Subnet을 통해 public node 영역과 private node 영역을 분리 - Inbound Gateway 역할
- ELB와 TLS 인증서 연동을 위한 IAM Role 생성
- Bootstrap Script 개발을 통한 편리한 프로비저닝 지원
- Accelerated AMI를 통한 GPU 노드 생성 지원
- 비용 절감을 위한 EC2 Spot Instance 모드 선택 기능

## 사용 기술

- HCL / Terraform
- AWS
  - EKS
  - EC2
  - VPC
  - IAM
  - ELB
  - S3
