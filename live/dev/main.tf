module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.name}-vpc"
  cidr = "10.0.0.0/16"

  azs = ["ap-northeast-2a", "ap-northeast-2c", "ap-northeast-2b", "ap-northeast-2d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false

  tags = {
    Name = "Terraform EKS VPC"
    Terraform = "true"
    Environment = "develop"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.name}-cluster" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.name}-cluster" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "${var.name}-so1s-dev"
  cluster_version = "1.22" 

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      addon_version = "v1.8.7-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      addon_version = "v1.22.6-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      addon_version = "v1.11.2-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    public = {
      name         = "public"
      min_size     = 1
      max_size     = 1
      desired_size = 1

      disk_size = 10

      instance_types = ["t3.small"]
      capacity_type  = "SPOT"
    }

    inference = {
      name         = "inference"
      min_size     = 1
      max_size     = 1
      desired_size = 1

      disk_size = 30

      instance_types = ["t3.small"]
      capacity_type  = "SPOT"

      taints = {
        kind = {
          key    = "kind"
          effect = "NO_SCHEDULE"
          value  = "inference"
        }
      }

      labels = {
        kind = "inference"
      }
    }

    api = {
      name         = "api"
      min_size     = 1
      max_size     = 1
      desired_size = 1

      disk_size = 30

      instance_types = ["t3.small"]
      capacity_type  = "SPOT"

      taints = {
        kind = {
          key    = "kind"
          effect = "NO_SCHEDULE"
          value  = "api"
        }
      }

      labels = {
        kind = "api"
      }
    }
  }

  tags = {
    Name = "Terraform EKS Cluster"
    Terraform = "true"
    Environment = "develop"
  }
}