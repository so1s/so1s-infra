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
    for node_name in slice(local.node_names, 0, length(local.node_names)) : merge(local.default_taint, { value = node_name })
  ]
  uses_gpu = length(regexall("xlarge", var.inference_node_instance_types[0])) > 0
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
      ami_id = "ami-07615daea13cb7a76"
      ami_type = "AL2_x86_64"
      capacity_type  = var.public_node_spot ? "SPOT" : "ON_DEMAND"

      # Original code from https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1770#issuecomment-1227047342

      create_launch_template = false
      launch_template_name = ""

      pre_bootstrap_user_data = <<-EOT
      #!/bin/bash
      set -ex
      cat <<-EOF > /etc/profile.d/bootstrap.sh
      export CONTAINER_RUNTIME="containerd"
      export USE_MAX_PODS=false
      EOF
      # Source extra environment variables in bootstrap script
      sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
      EOT

      subnet_ids = var.vpc_public_subnets

      create_iam_role              = true
      iam_role_name                = "So1s-dataplane-${local.node_names[3]}"
      iam_role_additional_policies = concat(local.eks_nodegroup_default_iam_policies, local.eks_nodegroup_public_iam_policies)

      taints = {
        custom_taint = {
          key    = "kind"
          effect = "PREFER_NO_SCHEDULE"
          value  = local.node_names[3]
        }
      }

      labels = {
        kind = local.node_names[3]
      }
    }

    inference = {
      name         = "${var.global_name}-cluster-${local.node_names[0]}"
      min_size     = var.inference_node_size_spec.min_size
      max_size     = var.inference_node_size_spec.max_size
      desired_size = var.inference_node_size_spec.desired_size

      disk_size = local.uses_gpu ? 125 : var.inference_node_size_spec.disk_size

      instance_types = var.inference_node_instance_types
      ami_type = local.uses_gpu ? "AL2_x86_64_GPU" : "AL2_x86_64"
      ami_id = local.uses_gpu ? "ami-0779aefb0ca1f55f3" : "ami-07615daea13cb7a76"
      capacity_type  = var.inference_node_spot ? "SPOT" : "ON_DEMAND"

      # Original code from https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1770#issuecomment-1227047342

      enable_bootstrap_user_data = true

      pre_bootstrap_user_data = <<-EOT
      #!/bin/bash
      set -ex
      cat <<-EOF > /etc/profile.d/bootstrap.sh
      export CONTAINER_RUNTIME="containerd"
      export USE_MAX_PODS=false
      EOF
      # Source extra environment variables in bootstrap script
      sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
      EOT

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

      instance_types = var.application_node_spot
      ami_id = "ami-07615daea13cb7a76"
      ami_type = "AL2_x86_64"
      capacity_type  = var.application_node_spot ? "SPOT" : "ON_DEMAND"

      # Original code from https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1770#issuecomment-1227047342

      enable_bootstrap_user_data = true

      pre_bootstrap_user_data = <<-EOT
      #!/bin/bash
      set -ex
      cat <<-EOF > /etc/profile.d/bootstrap.sh
      export CONTAINER_RUNTIME="containerd"
      export USE_MAX_PODS=false
      EOF
      # Source extra environment variables in bootstrap script
      sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
      EOT

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
      ami_id = "ami-07615daea13cb7a76"
      ami_type = "AL2_x86_64"
      capacity_type  = var.database_node_spot ? "SPOT" : "ON_DEMAND"

      # Original code from https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1770#issuecomment-1227047342

      enable_bootstrap_user_data = true

      pre_bootstrap_user_data = <<-EOT
      #!/bin/bash
      set -ex
      cat <<-EOF > /etc/profile.d/bootstrap.sh
      export CONTAINER_RUNTIME="containerd"
      export USE_MAX_PODS=false
      EOF
      # Source extra environment variables in bootstrap script
      sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
      EOT

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
      name         = "${var.global_name}-cluster-${local.node_names[4]}"
      min_size     = var.library_node_size_spec.min_size
      max_size     = var.library_node_size_spec.max_size
      desired_size = var.library_node_size_spec.desired_size

      disk_size = var.library_node_size_spec.disk_size

      instance_types = var.library_node_instance_types
      ami_id = "ami-07615daea13cb7a76"
      ami_type = "AL2_x86_64"
      capacity_type  = var.library_node_spot ? "SPOT" : "ON_DEMAND"

      # Original code from https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1770#issuecomment-1227047342

      enable_bootstrap_user_data = true

      pre_bootstrap_user_data = <<-EOT
      #!/bin/bash
      set -ex
      cat <<-EOF > /etc/profile.d/bootstrap.sh
      export CONTAINER_RUNTIME="containerd"
      export USE_MAX_PODS=false
      EOF
      # Source extra environment variables in bootstrap script
      sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
      EOT

      subnet_ids = var.vpc_private_subnets

      create_iam_role              = true
      iam_role_name                = "So1s-dataplane-${local.node_names[4]}"
      iam_role_additional_policies = local.eks_nodegroup_default_iam_policies

      taints = {
        kind = local.taints[4]
      }

      labels = {
        kind = local.node_names[4]
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
