resource "google_compute_network" "multicloud-lab-vpc" {
  name = "multicloud-lab-vpc"

  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  mtu                             = 1460
  routing_mode                    = "REGIONAL"

  depends_on = [google_project_service.compute]
}

resource "google_compute_subnetwork" "private-subnet" {
  name                     = "private-subnet"
  ip_cidr_range            = "10.30.0.0/24"
  private_ip_google_access = false
  region                   = "europe-west2"
  network                  = google_compute_network.multicloud-lab-vpc.id
  stack_type               = "IPV4_ONLY"
}

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
