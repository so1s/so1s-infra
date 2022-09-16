locals {
  region = "ap-northeast-2"
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
    Environment = var.is_prod ? "production" : "develop"
  }

  private_subnet_tags = {
    Name                                                                        = "${var.global_name}-cluster-private-subnet"
    "kubernetes.io/cluster/${var.global_name}-so1s-${var.is_prod ? "" : "dev"}" = "shared"
    "kubernetes.io/role/internal-elb"                                           = "1"
  }

  public_subnet_tags = {
    Name                                                                        = "${var.global_name}-cluster-public-subnet"
    "kubernetes.io/cluster/${var.global_name}-so1s-${var.is_prod ? "" : "dev"}" = "shared"
    "kubernetes.io/role/elb"                                                    = "1"
  }
}
