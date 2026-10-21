variable "project_name" {
  description = "Human-readable display name of the GCP project."
  type        = string
}

variable "project_id" {
  description = "Globally unique GCP project ID (lowercase, 6-30 chars)."
  type        = string
}

variable "folder_id" {
  description = "Parent folder, e.g. \"folders/123456789012\". Leave null to attach directly to the org (not recommended)."
  type        = string
  default     = null
}

variable "org_id" {
  description = "Organization ID (numeric string). Used only when folder_id is null."
  type        = string
  default     = null
}

variable "billing_account" {
  description = "Billing account ID, e.g. \"XXXXXX-XXXXXX-XXXXXX\"."
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "extra_labels" {
  description = "Extra labels merged onto the project (cost centre, owner, ...)."
  type        = map(string)
  default     = {}
}

variable "enable_apis" {
  description = "GCP APIs to enable. Keep minimal — least privilege."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
  ]
}

variable "monthly_budget_usd" {
  description = "Monthly budget alert threshold in USD. 0 disables the budget resource."
  type        = number
  default     = 0
}

variable "deletion_protection" {
  description = "When true, Terraform refuses to delete the project (deletion_policy = PREVENT). Keep true in every shared environment."
  type        = bool
  default     = true
}
variable "essential_contacts" {
  description = "Email contacts for GCP notifications. Map of email -> list of categories (BILLING, SECURITY, TECHNICAL)."
  type        = map(list(string))
  default     = {}
}
