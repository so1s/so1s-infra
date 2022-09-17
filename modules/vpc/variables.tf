variable "region" {
  description = "This type will use vpc region setting."
  type        = string
}

variable "is_prod" {
  description = "This type will check deploy type."
  type        = bool
}

variable "global_name" {
  description = "This name will use as prefix for AWS resource so, Please write unique and distinct word e.g. sungbin, backend-test..."
  type        = string
}

variable "cidr" {
  description = "This type will use to set cidr"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "This type will use to set public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "This type will use to set private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "enable_nat_gateway" {
  description = "This type will check whether to use NAT Gateway or not"
  type        = bool
  default     = true
}
