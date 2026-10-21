# Provider configuration lives ONLY here at the root.
# Child modules must never declare their own provider blocks —
# they inherit this one. That keeps credentials in one place.

provider "google" {
  # No credentials hardcoded, ever.
  # Local: run `gcloud auth application-default login`
  # CI:    Workload Identity Federation (see .github/workflows/terraform-ci.yml
  #        and the README's authentication section).
}
