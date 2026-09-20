variable "name" {
  description = "ECR repository name."
  type        = string
}

variable "image_tag_mutability" {
  description = "Tag mutability of the repository."
  type        = string
  default     = "IMMUTABLE"
}

variable "force_delete" {
  description = "Delete the repository even if it contains images (dev convenience)."
  type        = bool
  default     = false
}

variable "untagged_expire_days" {
  description = "Days after which untagged images expire."
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
