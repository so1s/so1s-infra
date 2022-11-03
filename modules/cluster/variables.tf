variable "is_prod" {
  description = "This type will check deploy type."
  type        = bool
  default     = false
}

variable "global_name" {
  description = "This name will use as prefix for AWS resource so, Please write unique and distinct word e.g. sungbin, backend-test..."
  type        = string
}

variable "public_node_size_spec" {
  description = "This type will use public node that use eks"
  type        = map(any)
  default = {
    min_size     = 1
    max_size     = 1
    desired_size = 1

    disk_size = 10
  }
}

variable "public_node_spot" {
  description = "This type will use public node that use eks"
  type        = bool
  default     = true
}

variable "public_node_instance_types" {
  description = "This type will use public node that use eks"
  type        = list(string)
  default     = ["t3a.small"]
}


variable "inference_node_size_spec" {
  description = "This type will use inference node that use eks"
  type        = map(any)
  default = {
    min_size     = 1
    max_size     = 1
    desired_size = 1

    disk_size = 30
  }
}

variable "inference_node_spot" {
  description = "This type will use inference node that use eks"
  type        = bool
  default     = true
}

variable "inference_node_instance_types" {
  description = "This type will use inference node that use eks"
  type        = list(string)
  default     = ["t3a.large"]
}

variable "application_node_size_spec" {
  description = "This type will use application node that use eks"
  type        = map(any)
  default = {
    min_size     = 3
    max_size     = 3
    desired_size = 3

    disk_size = 30
  }
}

variable "application_node_spot" {
  description = "This type will use application node that use eks"
  type        = bool
  default     = true
}

variable "application_node_instance_types" {
  description = "This type will use application node that use eks"
  type        = list(string)
  default     = ["t3.small"]
}

variable "database_node_size_spec" {
  description = "This type will use database node that use eks"
  type        = map(any)
  default = {
    min_size     = 1
    max_size     = 1
    desired_size = 1

    disk_size = 50
  }
}

variable "database_node_spot" {
  description = "This type will use database node that use eks"
  type        = bool
  default     = true
}

variable "database_node_instance_types" {
  description = "This type will use database node that use eks"
  type        = list(string)
  default     = ["t3.small"]
}

variable "library_node_size_spec" {
  description = "This type will use library node that use eks"
  type        = map(any)
  default = {
    min_size     = 3
    max_size     = 3
    desired_size = 3

    disk_size = 30
  }
}

variable "library_node_spot" {
  description = "This type will use library node that use eks"
  type        = bool
  default     = true
}

variable "library_node_instance_types" {
  description = "This type will use library node that use eks"
  type        = list(string)
  default     = ["t3.small"]
}

variable "model_builder_node_size_spec" {
  description = "This type will use model_builder node that use eks"
  type        = map(any)
  default = {
    min_size     = 1
    max_size     = 1
    desired_size = 1

    disk_size = 100
  }
}

variable "model_builder_node_spot" {
  description = "This type will use model_builder node that use eks"
  type        = bool
  default     = true
}

variable "model_builder_node_instance_types" {
  description = "This type will use model_builder node that use eks"
  type        = list(string)
  default     = ["r5a.large"]
}

variable "vpc_id" {
  description = "VPC ID to use EKS Cluster"
  type        = string
}

variable "vpc_private_subnets" {
  description = "VPC Private Subnets to use EKS Cluster"
  type        = list(string)
}

variable "vpc_public_subnets" {
  description = "VPC Public Subnets to use EKS Cluster"
  type        = list(string)
}
