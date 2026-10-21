# Root module: thin wiring. All logic lives in the reusable child module
# so the same foundation can provision dev, staging and prod identically.

module "project_foundation" {
  source = "./modules/project-foundation"

  project_name        = var.project_name
  project_id          = var.project_id
  folder_id           = var.folder_id
  org_id              = var.org_id
  billing_account     = var.billing_account
  environment         = var.environment
  extra_labels        = var.extra_labels
  enable_apis         = var.enable_apis
  monthly_budget_usd  = var.monthly_budget_usd
  deletion_protection = var.deletion_protection
  essential_contacts  = var.essential_contacts
}
