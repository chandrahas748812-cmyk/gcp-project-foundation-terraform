terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 7.0"
    }
  }

  # Remote state with locking (GCS supports both natively).
  # Create the bucket first (see README), then uncomment:
  # backend "gcs" {
  #   bucket = "REPLACE_WITH_YOUR_STATE_BUCKET"
  #   prefix = "gcp-project-foundation/dev"
  # }
}
