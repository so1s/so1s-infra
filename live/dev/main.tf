locals {
  region = "ap-northeast-2"
}

module "vpc" {
  source = "../../modules/vpc"

  global_name = var.global_name
  region      = local.region
  is_prod     = false

  cidr            = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
}

module "eks" {
  source = "../../modules/cluster"

  global_name = var.global_name
  is_prod     = false

  vpc_id              = module.vpc.vpc_id
  vpc_public_subnets  = module.vpc.vpc_public_subnets
  vpc_private_subnets = module.vpc.vpc_private_subnets

  public_node_spot = true
  public_node_size_spec = {
    min_size     = 1
    max_size     = 1
    desired_size = 1

    disk_size = 10
  }
  public_node_instance_types = ["t3a.small"]

  inference_node_spot = true
  inference_node_size_spec = {
    min_size     = 1
    max_size     = 1
    desired_size = 1

    disk_size = 30
  }
  inference_node_instance_types = var.inference_node_instance_types

  application_node_spot = true
  application_node_size_spec = {
    min_size     = 1
    max_size     = 3
    desired_size = 1

    disk_size = 30
  }
  application_node_instance_types = ["t3.small"]

  library_node_spot = true
  library_node_size_spec = {
    min_size     = 3
    max_size     = 3
    desired_size = 3

    disk_size = 30
  }
  library_node_instance_types = ["t3.small"]


  database_node_spot = true
  database_node_size_spec = {
    min_size     = 1
    max_size     = 1
    desired_size = 1

    disk_size = 50
  }
  database_node_instance_types = ["t3.small"]
}
