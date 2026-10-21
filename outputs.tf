output "project_id" {
  description = "The created project ID."
  value       = module.project_foundation.project_id
}

output "project_number" {
  description = "The numeric project number."
  value       = module.project_foundation.project_number
}

output "enabled_apis" {
  description = "APIs enabled on the project."
  value       = module.project_foundation.enabled_apis
}
