variable "is_prod" {
  description = "This type will check deploy type."
  type        = bool
  default     = false
}

variable "cluster_oidc_provider_arn" {
  description = "This type will check deploy type."
  type        = bool
  default     = false
}

variable "cluster_oidc_issuer_url" {
  description = "This type will check deploy type."
  type        = bool
  default     = false
}

variable "cluster_oidc_provider" {
  description = "This type will check deploy type."
  type        = bool
  default     = false
}
