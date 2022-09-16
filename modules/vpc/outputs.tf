output "vpc_id" {
  description = "VPC ID to use EKS Cluster"
  value       = module.vpc.vpc_id
}

output "vpc_private_subnets" {
  description = "VPC Private Subnets to use EKS Cluster"
  value       = module.vpc.private_subnets
}

output "vpc_public_subnets" {
  description = "VPC Public Subnets to use EKS Cluster"
  value       = module.vpc.public_subnets
}
