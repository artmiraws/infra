variable "hostname" {
  description = "Hostname the certificate is issued for."
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID used for DNS validation."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
