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
  ip_cidr_range            = local.gcp_private_subnet_cidr
  private_ip_google_access = true
  region                   = local.gcp_region
  network                  = google_compute_network.multicloud_lab_vpc.id
  stack_type               = "IPV4_ONLY"
}

resource "google_compute_route" "internet_route" {
  name             = "internet-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.multicloud_lab_vpc.name
  next_hop_gateway = "default-internet-gateway"
}
