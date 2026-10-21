# GCP Project Foundation — Terraform

> **Learning / interview-demonstration project.** Built to study GCP landing-zone patterns: project hierarchy, IAM, org policies, networking, Terraform automation, and CI/CD. Not production-hardened, and not presented as professional experience.

A small, reusable Terraform module that provisions a GCP project with secure defaults, plus a safe GitHub Actions CI workflow. Sized for a 20-minute technical interview: architecture, code, security decisions, validation.

## Architecture

Google Cloud Organization
- Folder (e.g. platform-dev): org policies attach here per env
  - Project (this module creates it): IAM, billing, APIs attach here
    - APIs (least-privilege set)
    - Billing budget (spend guardrail)

What the module creates:

- google_project: the project — identity, hierarchy, billing, labels, deletion safeguard
- google_project_service (xN): enables APIs one by one via for_each — only what the workload needs
- google_billing_budget: alerts at 50 percent / 90 percent / 100 percent of the monthly budget

Intentionally out of scope (say this in the interview — it shows judgment):

- IAM bindings: separate iam module (google_project_iam_member, no primitive roles)
- Org policies: google_org_policy_policy (e.g. require OS Login, block SA key creation)
- Networking: Shared VPC host/service attachment
- Notifications: wire the budget all_updates_rule to Pub/Sub to Slack/email

## Repository structure

- versions.tf: Terraform + provider version constraints
- providers.tf: provider google — ONLY here, never in the module
- variables.tf: root inputs (project_id, folder, billing, ...)
- main.tf: root — thin wiring, calls the child module
- outputs.tf: root — re-exports module outputs
- terraform.tfvars.example: copy to terraform.tfvars, fill in your values
- modules/project-foundation/: versions.tf, variables.tf, main.tf, outputs.tf
- .github/workflows/terraform-ci.yml: fmt to validate to tfsec to plan (no auto-apply)

Root vs child responsibilities: the root owns providers, state backend, and environment wiring. The child module is pure and reusable — same code provisions dev, staging, and prod. Child modules never declare provider blocks or backends; they inherit them.

## Prerequisites

1. A Google Cloud organization (or at minimum a folder you control).
2. A billing account with permission to link projects (roles/billing.admin or roles/billing.projectManager).
3. An identity with these IAM roles on the org/folder: roles/resourcemanager.projectCreator, roles/serviceusage.serviceUsageAdmin, roles/billing.projectManager, roles/billing.budgetsAdmin (or viewer).
4. Terraform >= 1.5 installed locally.

Required Google Cloud APIs: cloudresourcemanager.googleapis.com, serviceusage.googleapis.com, billingbudgets.googleapis.com (only if monthly_budget_usd > 0), iam.googleapis.com.

## Setup

git clone https://github.com/chandrahas748812-cmyk/gcp-project-foundation-terraform.git
cd gcp-project-foundation-terraform
cp terraform.tfvars.example terraform.tfvars
(edit terraform.tfvars with YOUR project_id, folder_id, billing_account)
terraform init
terraform validate
terraform plan

## Authentication (no long-lived keys)

Locally: gcloud auth application-default login.

In CI — Workload Identity Federation (WIF):
1. In GCP create a Workload Identity Pool + OIDC provider trusting token.actions.githubusercontent.com, restricted to your repo.
2. Grant the pool principal a least-privilege service account (e.g. roles/resourcemanager.projectCreator scoped to the target folder — not roles/owner).
3. Store two repo secrets: GCP_WIF_PROVIDER and GCP_TF_SERVICE_ACCOUNT.
4. The workflow google-github-actions/auth step mints a short-lived token per run. No JSON key ever exists.

Why not a service-account JSON key? Keys leak, never expire by default, and cannot be scoped to a single repo. WIF tokens live for minutes and are bound to the exact workflow run.

## Commands

- terraform fmt -check -recursive: style check, always safe
- terraform init: install providers, safe
- terraform validate: syntax check, no cloud calls, safe
- terraform plan -out=tfplan: preview changes, safe (read-only)
- terraform apply tfplan: applies exactly the reviewed plan — human-gated
- terraform destroy: tear down — blocked by deletion_protection

## Destroying test resources safely

1. deletion_protection = true (default) makes terraform destroy fail on the project — deliberate.
2. With false, destroy uses ABANDON: the project leaves state but stays alive in GCP — delete manually afterwards.
3. Always run terraform plan -destroy first and read it.

## State, locking, and recovery

- Remote state: uncomment the gcs backend in versions.tf after creating the bucket (versioning on). GCS locking is free — concurrent applies cannot corrupt state.
- Least privilege: CI service account gets only project-creator-class roles on the target folder.
- Plan review: apply tfplan applies the exact bytes reviewed.
- Failed apply: state records partial progress; fix the cause, re-plan, re-apply (idempotent). Never hand-edit state without a defensible reason.
- Accidental deletion: deletion_policy = PREVENT is the guardrail; keep prod applies human-gated via a GitHub Environment with required reviewers.

## Troubleshooting

- 403 on resourcemanager.projects.create: missing projectCreator on the org/folder — grant at folder level.
- 400 Invalid project ID: uppercase, too short, or taken — IDs are global, pick a unique lowercase one.
- Billing account errors: verify ID in the Billing console; need billing.projectManager.
- API not enabled during apply: enable serviceusage.googleapis.com where you run Terraform.
- Error acquiring state lock: stale lock from a killed run — terraform force-unlock only if no apply is running.
- CI plan fails on fork PRs: expected — forks cannot read repo secrets, workflow skips plan there by design.
- tfsec findings: triage each; soft_fail is on while learning.

## Interview talking points and trade-offs

1. Why a module, not flat resources? Reuse across envs, one tested path, versioned interface.
2. Why for_each over count for APIs? Keyed by API name — removing one does not shift indexes.
3. Why provider block only at root? One credential source; child modules inherit.
4. What does deletion_policy PREVENT do? terraform destroy errors instead of deleting.
5. Why disable_on_destroy = false? Removing an API from config will not break running workloads.
6. Why no auto-apply in CI? Untrusted PR + auto-apply = arbitrary cloud spend. Plan is reviewed; apply is human-gated.
7. Why WIF over JSON keys? Short-lived, repo-scoped, nothing to rotate or leak.
8. How does state locking work? GCS backend locks natively.
9. Plan exit code 2 — fail or pass? Pass: 2 means changes present, which is what you review. Only 1 fails.
10. Apply fails halfway — now what? State records partial progress; fix, re-plan, re-apply. Idempotent.

## What was actually run vs generated

- Actually run locally: terraform init, terraform validate, terraform fmt -check (all clean).
- Never run: terraform plan / apply against real GCP (no credentials or billing were used). No real project was created. CI results are described, not claimed.

## Verification commands

terraform fmt -check -recursive
terraform init -backend=false
terraform validate
cd modules/project-foundation && terraform init -backend=false && terraform validate
