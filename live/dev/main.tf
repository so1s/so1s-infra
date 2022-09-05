module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2c", "ap-northeast-2b", "ap-northeast-2d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Name        = "${var.global_name}-cluster-vpc"
    Terraform   = "true"
    Environment = "develop"
  }

  private_subnet_tags = {
    Name                                                = "${var.global_name}-cluster-private-subnet"
    "kubernetes.io/cluster/${var.global_name}-so1s-dev" = "shared"
    "kubernetes.io/role/internal-elb"                   = "1"
  }

  public_subnet_tags = {
    Name                                                = "${var.global_name}-cluster-public-subnet"
    "kubernetes.io/cluster/${var.global_name}-so1s-dev" = "shared"
    "kubernetes.io/role/elb"                            = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "${var.global_name}-so1s-dev"
  cluster_version = "1.22"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      addon_version     = "v1.8.7-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      addon_version     = "v1.22.6-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      addon_version     = "v1.11.2-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  cluster_security_group_name = "${var.global_name}-cluster-sg"
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }

  }

  node_security_group_name = "${var.global_name}-cluster-nodegroup-sg"
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }

    ingress_cluster_api_ephemeral_ports_tcp = {
      description                   = "Cluster API to K8S services running on nodes"
      protocol                      = "tcp"
      from_port                     = 1025
      to_port                       = 65535
      type                          = "ingress"
      source_cluster_security_group = true
    }

    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  eks_managed_node_groups = {
    public = {
      name         = "${var.global_name}-cluster-public"
      min_size     = 1
      max_size     = 1
      desired_size = 1

      disk_size = 10

      instance_types = ["t3a.small"]
      capacity_type  = "SPOT"

      subnet_ids = module.vpc.public_subnets

      create_iam_role = false
      iam_role_arn    = "arn:aws:iam::089143290485:role/So1s-data-plane-inference"

      network_interfaces = [{
        associate_public_ip_address = true
      }]

      labels = {
        kind = "public"
      }
    }

    inference = {
      name         = "${var.global_name}-cluster-inference"
      min_size     = 1
      max_size     = 1
      desired_size = 1

      disk_size = 30

      instance_types = ["t3a.medium"]
      capacity_type  = "SPOT"

      subnet_ids = module.vpc.private_subnets

      create_iam_role = false
      iam_role_arn    = "arn:aws:iam::089143290485:role/So1s-data-plane-inference"

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
      name         = "${var.global_name}-cluster-api"
      min_size     = 3
      max_size     = 3
      desired_size = 3

      disk_size = 30

      instance_types = ["t3.small"]
      capacity_type  = "SPOT"

      subnet_ids = module.vpc.private_subnets

      create_iam_role = false
      iam_role_arn    = "arn:aws:iam::089143290485:role/So1s-data-plane-api"

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
    Name        = "${var.global_name}-so1s-dev"
    Terraform   = "true"
    Environment = "develop"
  }
}
