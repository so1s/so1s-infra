locals {
  region                                 = "ap-northeast-2"
  eks_nodegroup_default_iam_policies     = [data.terraform_remote_state.global.outputs.iam_policy_alb_arn]
  eks_nodegroup_public_iam_policies      = ["arn:aws:iam::aws:policy/AmazonRoute53FullAccess"]
  eks_nodegroup_application_iam_policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
  node_names                             = ["inference", "application", "database", "public", "library"]
  default_taint = {
    key    = "kind"
    effect = "NO_SCHEDULE"
  }
  taints = [
    for node_name in slice(local.node_names, 0, length(local.node_names) - 1) : merge(local.default_taint, { value = node_name })
  ]
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "${var.global_name}-so1s${var.is_prod ? "" : "-dev"}"
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

  vpc_id     = var.vpc_id
  subnet_ids = concat(var.vpc_private_subnets, var.vpc_public_subnets)

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
      min_size     = var.public_node_size_spec.min_size
      max_size     = var.public_node_size_spec.max_size
      desired_size = var.public_node_size_spec.desired_size

      disk_size = var.public_node_size_spec.disk_size

      instance_types = var.public_node_instance_types
      capacity_type  = var.public_node_spot ? "SPOT" : "ON_DEMAND"

      subnet_ids = var.vpc_public_subnets

      create_iam_role              = true
      iam_role_name                = "So1s-dataplane-${local.node_names[3]}"
      iam_role_additional_policies = concat(local.eks_nodegroup_default_iam_policies, local.eks_nodegroup_public_iam_policies)

      labels = {
        kind = local.node_names[3]
      }
    }

    inference = {
      name         = "${var.global_name}-cluster-${local.node_names[0]}"
      min_size     = var.inference_node_size_spec.min_size
      max_size     = var.inference_node_size_spec.max_size
      desired_size = var.inference_node_size_spec.desired_size

      disk_size = var.inference_node_size_spec.disk_size

      instance_types = var.inference_node_instance_types
      capacity_type  = var.inference_node_spot ? "SPOT" : "ON_DEMAND"

      subnet_ids = var.vpc_private_subnets

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

    application = {
      name         = "${var.global_name}-cluster-${local.node_names[1]}"
      min_size     = var.application_node_size_spec.min_size
      max_size     = var.application_node_size_spec.max_size
      desired_size = var.application_node_size_spec.desired_size

      disk_size = var.application_node_size_spec.disk_size

      instance_types = var.application_node_instance_types
      capacity_type  = var.application_node_spot ? "SPOT" : "ON_DEMAND"

      subnet_ids = var.vpc_private_subnets

      create_iam_role              = true
      iam_role_name                = "So1s-dataplane-${local.node_names[1]}"
      iam_role_additional_policies = concat(local.eks_nodegroup_default_iam_policies, local.eks_nodegroup_application_iam_policies)

      taints = {
        kind = local.taints[1]
      }

      labels = {
        kind = local.node_names[1]
      }
    }

    database = {
      name         = "${var.global_name}-cluster-${local.node_names[2]}"
      min_size     = var.database_node_size_spec.min_size
      max_size     = var.database_node_size_spec.max_size
      desired_size = var.database_node_size_spec.desired_size

      disk_size = var.database_node_size_spec.disk_size

      instance_types = var.database_node_instance_types
      capacity_type  = var.database_node_spot ? "SPOT" : "ON_DEMAND"

      subnet_ids = var.vpc_private_subnets

      create_iam_role              = true
      iam_role_name                = "So1s-dataplane-${local.node_names[2]}"
      iam_role_additional_policies = concat(local.eks_nodegroup_default_iam_policies, local.eks_nodegroup_application_iam_policies)

      taints = {
        kind = local.taints[2]
      }

      labels = {
        kind = local.node_names[2]
      }
    }

    library = {
      name         = "${var.global_name}-cluster-${local.node_names[3]}"
      min_size     = var.library_node_size_spec.min_size
      max_size     = var.library_node_size_spec.max_size
      desired_size = var.library_node_size_spec.desired_size

      disk_size = var.library_node_size_spec.disk_size

      instance_types = var.library_node_instance_types
      capacity_type  = var.library_node_spot ? "SPOT" : "ON_DEMAND"

      subnet_ids = var.vpc_private_subnets

      create_iam_role              = true
      iam_role_name                = "So1s-dataplane-${local.node_names[3]}"
      iam_role_additional_policies = local.eks_nodegroup_default_iam_policies

      taints = {
        kind = local.taints[3]
      }

      labels = {
        kind = local.node_names[3]
      }
    }
  }

  tags = {
    Name        = "${var.global_name}-so1s-${var.is_prod ? "" : "dev"}"
    Terraform   = "true"
    Environment = var.is_prod ? "production" : "develop"
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
