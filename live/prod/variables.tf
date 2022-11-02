variable "global_name" {
  description = "This name will use as prefix for AWS resource so, Please write unique and distinct word e.g. sungbin, backend-test..."
  type        = string
  default     = "prod"
}

variable "inference_node_instance_types" {
  description = "This type will use inference node that use eks"
  type        = list(string)
  default     = ["t3a.large"]
}

variable "model_builder_node_instance_types" {
  description = "This type will use inference node that use eks"
  type        = list(string)
  default     = ["r5a.large"]
}
