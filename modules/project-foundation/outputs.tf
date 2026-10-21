output "project_id" {
  description = "The created project ID (use it to target the project in later modules)."
  value       = google_project.this.project_id
}

output "project_number" {
  description = "The numeric project number (needed by some APIs and IAM bindings)."
  value       = google_project.this.number
}

output "enabled_apis" {
  description = "The APIs enabled on the project."
  value       = [for s in google_project_service.apis : s.service]
}
