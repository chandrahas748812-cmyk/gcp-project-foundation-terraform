# ---------------------------------------------------------------------------
# google_project — the foundation. Everything else (IAM, networking,
# workloads) hangs off the project this creates.
# ---------------------------------------------------------------------------
resource "google_project" "this" {
  # Identity
  name       = var.project_name # display name, e.g. "Data Platform Dev"
  project_id = var.project_id   # globally unique ID, e.g. "data-dev-412301"

  # Hierarchy: a project must hang under an org or a folder.
  # Folders let you apply org policies per environment (dev vs prod).
  org_id    = var.org_id
  folder_id = var.folder_id

  # Billing: every project needs a billing account or APIs stay disabled.
  billing_account = var.billing_account

  # Labels: metadata for cost attribution, ownership and policy targeting.
  labels = merge(
    {
      environment = var.environment
      managed_by  = "terraform"
    },
    var.extra_labels
  )

  # Deletion safeguard (provider-supported argument):
  #  PREVENT -> `terraform destroy` fails instead of deleting the project.
  #  ABANDON -> project is removed from state but left alive in GCP.
  # Never delete production data with a keystroke — this is the guardrail.
  deletion_policy = var.deletion_protection ? "PREVENT" : "ABANDON"
}

# ---------------------------------------------------------------------------
# google_project_service — enable APIs one by one (least privilege).
# for_each over a list keeps the config DRY: one block, N APIs.
# ---------------------------------------------------------------------------
resource "google_project_service" "apis" {
  for_each = toset(var.enable_apis)

  project = google_project.this.project_id
  service = each.value # e.g. "compute.googleapis.com"

  # If an API is removed from var.enable_apis later, keep it enabled rather
  # than breaking workloads that already depend on it.
  disable_on_destroy = false

  # APIs must exist before anything that uses them — implicit dependency
  # via google_project.this.project_id already orders this correctly.
}

# ---------------------------------------------------------------------------
# google_billing_budget — spend guardrail from day one.
# ---------------------------------------------------------------------------
resource "google_billing_budget" "this" {
  count = var.monthly_budget_usd > 0 ? 1 : 0

  billing_account = var.billing_account
  display_name    = "${var.project_id}-monthly-budget"

  budget_filter {
    projects = ["projects/${google_project.this.number}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_budget_usd)
    }
  }

  # Alert thresholds: 50%, 90%, 100% of the monthly budget.
  dynamic "threshold_rules" {
    for_each = [0.5, 0.9, 1.0]
    content {
      threshold_percent = threshold_rules.value
      spend_basis       = "CURRENT_SPEND"
    }
  }

  # Real alerting needs an `all_updates_rule` pointing at a Pub/Sub topic,
  # which fans out to email/Slack. Intentionally left unwired here:
  # notification channels differ per organization.
}
