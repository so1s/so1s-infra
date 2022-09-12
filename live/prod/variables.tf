variable "global_name" {
  description = "This name will use as prefix for AWS resource so, Please write unique and distinct word e.g. sungbin, backend-test..."
  type        = string
  default     = "prod"
}
variable "public_instance_types" {
  description = "This type will use public node that use eks"
  type        = list(string)
  default     = ["t3a.medium"]
}

variable "inference_instance_types" {
  description = "This type will use inference node that use eks"
  type        = list(string)
  default     = ["t3a.large"]
}

variable "api_instance_types" {
  description = "This type will use api node that use eks"
  type        = list(string)
  default     = ["t3a.large"]
}
