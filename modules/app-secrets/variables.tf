variable "name" {
  description = "Secrets Manager secret name for the application credentials."
  type        = string
}

variable "admin_user" {
  description = "Application admin username."
  type        = string
  default     = "admin"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
