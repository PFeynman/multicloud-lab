resource "google_project_service" "compute" {
  service = "compute.googleapis.com"

  disable_on_destroy = false
  depends_on         = [google_project_service.cloud_resource_manager]
}

resource "google_project_service" "service_usage" {
  provider = google.bootstrap
  service  = "serviceusage.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloud_resource_manager" {
  provider = google.bootstrap
  service  = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = false
  depends_on         = [google_project_service.service_usage]
}

resource "google_project_service" "iam" {
  provider = google.bootstrap
  service  = "iam.googleapis.com"

  disable_on_destroy = false
}