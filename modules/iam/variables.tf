variable "cluster_oidc_provider_arn" {
  description = "AWS EKS Cluster ARN"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "AWS EKS OpenID Connect provider URL"
  type        = string
}