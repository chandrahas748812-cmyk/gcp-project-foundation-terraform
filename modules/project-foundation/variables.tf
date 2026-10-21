variable "project_name" {
  description = "Human-readable display name of the GCP project."
  type        = string
}

variable "project_id" {
  description = "Globally unique GCP project ID (lowercase, 6-30 chars)."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be 6-30 lowercase letters, digits or hyphens."
  }
}

variable "folder_id" {
  description = "Parent folder (e.g. \"folders/123456\"). Mutually exclusive with org_id."
  type        = string
  default     = null
}

variable "org_id" {
  description = "Organization ID. Used only when folder_id is null."
  type        = string
  default     = null
}

variable "billing_account" {
  description = "Billing account ID."
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment label: dev | staging | prod."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "extra_labels" {
  description = "Additional labels merged into the project."
  type        = map(string)
  default     = {}
}

variable "enable_apis" {
  description = "GCP APIs to enable. Keep minimal (least privilege)."
  type        = list(string)
}

variable "monthly_budget_usd" {
  description = "Monthly budget alert threshold in USD. 0 disables the budget."
  type        = number
  default     = 0
}

variable "deletion_protection" {
  description = "True -> deletion_policy PREVENT (Terraform refuses to delete the project). False -> ABANDON (project left orphaned, not deleted)."
  type        = bool
  default     = true
}
variable "essential_contacts" {
  description = "Email contacts for GCP notifications. Map of email -> list of categories (BILLING, SECURITY, TECHNICAL)."
  type        = map(list(string))
  default     = {}

  validation {
    condition = alltrue([
      for cats in values(var.essential_contacts) :
      alltrue([for c in cats : contains(["BILLING", "SECURITY", "TECHNICAL"], c)])
    ])
    error_message = "Categories must be BILLING, SECURITY, or TECHNICAL."
  }
}
