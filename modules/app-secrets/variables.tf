variable "name" {
  description = "Secrets Manager secret name for the application credentials."
  type        = string
}

variable "admin_user" {
  description = "Application admin username."
  type        = string
  default     = "admin"
}

variable "recovery_window_in_days" {
  description = "Secrets Manager recovery window. 0 force-deletes on destroy, so the name is free to recreate (ephemeral environments)."
  type        = number
  default     = 0
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
