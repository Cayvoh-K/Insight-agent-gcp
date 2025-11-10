# 1. Enable required APIs
resource "google_project_service" "enabled_apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com"
  ])
  project = var.project_id
  service = each.key
}

# 2. Create Artifact Registry repository
resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.region
  repository_id = "insight-agent-repo"
  format        = "DOCKER"
  description   = "Artifact Registry for Insight-Agent container images"
  depends_on    = [google_project_service.enabled_apis]
}

# 3. Create a dedicated Service Account
resource "google_service_account" "cloud_run_sa" {
  account_id   = "insight-agent-sa"
  display_name = "Insight Agent Cloud Run Service Account"
}

# 4. Assign minimal permissions to the Service Account
resource "google_project_iam_member" "run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# 5. Deploy Cloud Run service
resource "google_cloud_run_service" "service" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      containers {
        image = var.image
        ports {
          container_port = 8080
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  depends_on = [
    google_artifact_registry_repository.repo,
    google_project_service.enabled_apis
  ]
}

# 6. Restrict Cloud Run ingress (internal only)
resource "google_cloud_run_service_iam_policy" "no_public_access" {
  location = google_cloud_run_service.service.location
  project  = var.project_id
  service  = google_cloud_run_service.service.name

  policy_data = jsonencode({
    bindings = []
  })
}

