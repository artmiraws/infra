output "name" {
  description = "Name of the Argo CD Application."
  value       = var.name
}

output "namespace" {
  description = "Destination namespace of the application."
  value       = var.namespace
}
