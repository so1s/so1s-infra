variable "is_prod" {
  description = "This type will check deploy type."
  type        = bool
}

variable "global_name" {
  description = "This name will use as prefix for AWS resource so, Please write unique and distinct word e.g. sungbin, backend-test..."
  type        = string
}
