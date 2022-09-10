locals {
  region                             = "ap-northeast-2"
  eks_nodegroup_default_iam_policies = [data.terraform_remote_state.global.outputs.iam_policy_alb_arn]
  eks_nodegroup_public_iam_policies  = ["arn:aws:iam::aws:policy/AmazonRoute53FullAccess"]
  eks_nodegroup_api_iam_policies     = ["arn:aws:iam::aws:policy/PowerUserAccess"]
  node_names                         = ["inference", "api", "database", "public"]
  default_taint = {
    key    = "kind"
    effect = "NO_SCHEDULE"
  }
  taints = [
    for node_name in slice(local.node_names, 0, length(local.node_names) - 1) : merge(local.default_taint, { value = node_name })
  ]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}c", "${local.region}b", "${local.region}d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Name        = "${var.global_name}-cluster-vpc"
    Terraform   = "true"
    Environment = "production"
  }

  private_subnet_tags = {
    Name                                            = "${var.global_name}-cluster-private-subnet"
    "kubernetes.io/cluster/${var.global_name}-so1s" = "shared"
    "kubernetes.io/role/internal-elb"               = "1"
  }

  public_subnet_tags = {
    Name                                            = "${var.global_name}-cluster-public-subnet"
    "kubernetes.io/cluster/${var.global_name}-so1s" = "shared"
    "kubernetes.io/role/elb"                        = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "${var.global_name}-so1s"
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

    ingress_cluster_api_ephemeral_ports_tcp = {
      description                   = "Cluster API to K8S services running on nodes"
      protocol                      = "tcp"
      from_port                     = 1025
      to_port                       = 65535
      type                          = "ingress"
      source_cluster_security_group = true
    }

    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
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
      name         = "${var.global_name}-cluster-${local.node_names[3]}"
      min_size     = 1
      max_size     = 1
      desired_size = 1

      disk_size = 30

      instance_types = ["t3a.medium"]

      subnet_ids = module.vpc.public_subnets

      create_iam_role              = true
      iam_role_name                = "So1s-dataplane-${local.node_names[3]}"
      iam_role_additional_policies = concat(local.eks_nodegroup_default_iam_policies, local.eks_nodegroup_public_iam_policies)

      labels = {
        kind = local.node_names[3]
      }
    }

    inference = {
      name         = "${var.global_name}-cluster-${local.node_names[0]}"
      min_size     = 1
      max_size     = 3
      desired_size = 2

      disk_size = 30

      instance_types = ["t3a.large"]

      subnet_ids = module.vpc.private_subnets

      create_iam_role              = true
      iam_role_name                = "So1s-dataplane-${local.node_names[0]}"
      iam_role_additional_policies = local.eks_nodegroup_default_iam_policies

      taints = {
        kind = local.taints[0]
      }

      labels = {
        kind = local.node_names[0]
      }
    }

    api = {
      name         = "${var.global_name}-cluster-${local.node_names[1]}"
      min_size     = 2
      max_size     = 4
      desired_size = 2

      disk_size = 100

      instance_types = ["t3a.large"]

      subnet_ids = module.vpc.private_subnets

      create_iam_role              = true
      iam_role_name                = "So1s-dataplane-${local.node_names[1]}"
      iam_role_additional_policies = concat(local.eks_nodegroup_default_iam_policies, local.eks_nodegroup_api_iam_policies)

      taints = {
        kind = local.taints[1]
      }

      labels = {
        kind = local.node_names[1]
      }
    }

    database = {
      name         = "${var.global_name}-cluster-${local.node_names[2]}"
      min_size     = 1
      max_size     = 1
      desired_size = 1

      disk_size = 50

      instance_types = ["t3.small"]

      subnet_ids = module.vpc.private_subnets

      create_iam_role              = true
      iam_role_name                = "So1s-dataplane-${local.node_names[2]}"
      iam_role_additional_policies = concat(local.eks_nodegroup_default_iam_policies, local.eks_nodegroup_api_iam_policies)

      taints = {
        kind = local.taints[2]
      }

      labels = {
        kind = local.node_names[2]
      }
    }
  }

  tags = {
    Name        = "${var.global_name}-so1s"
    Terraform   = "true"
    Environment = "production"
  }
}

data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket = "so1s-terraform-remote-state-storage"
    key    = "live/global/terraform.tfstate"
    region = "ap-northeast-2"
  }

}

resource "aws_iam_role" "external_dns" {
  name               = "external_dns"
  assume_role_policy = templatefile("oidc-policy.json", { OIDC_ARN = module.eks.oidc_provider_arn, OIDC_URL = replace(module.eks.cluster_oidc_issuer_url, "https://", "") })

  depends_on = [module.eks.oidc_provider]
}

resource "aws_iam_role_policy_attachment" "external_dns_attach" {
  role       = aws_iam_role.external_dns.name
  policy_arn = data.terraform_remote_state.global.outputs.iam_policy_external_dns_arn
}
