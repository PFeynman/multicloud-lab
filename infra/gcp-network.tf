resource "google_compute_network" "multicloud_lab_vpc" {
  name = "multicloud-lab-vpc"

  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  mtu                             = 1460
  routing_mode                    = "REGIONAL"

  depends_on = [google_project_service.compute]
}

resource "google_compute_subnetwork" "private_subnet" {
  name                     = "private-subnet"
  ip_cidr_range            = "10.30.0.0/24"
  private_ip_google_access = true
  region                   = "europe-west2"
  network                  = google_compute_network.multicloud_lab_vpc.id
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

resource "google_project_service" "iam" {
  provider = google.bootstrap
  service  = "iam.googleapis.com"

  disable_on_destroy = false
}

resource "google_compute_route" "internet_route" {
  name             = "internet-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.multicloud_lab_vpc.name
  next_hop_gateway = "default-internet-gateway"
}
