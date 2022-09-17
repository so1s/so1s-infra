output "vpc_id" {
  description = "vpc id for your EKS Cluster"
  value       = module.vpc.vpc_id
}
output "cluster_id" {
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = module.eks.cluster_id
}
