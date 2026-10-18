resource "google_service_account" "multicloud_lab_vm_sa" {
  account_id   = "multicloud-lab-vm-sa"
  display_name = "Multicloud Lab VM Service Account"
}

resource "google_compute_instance" "multicloud_lab_vm" {
  name         = "multicloud-lab-vm"
  zone         = "europe-west2-a"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }

    auto_delete = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
    network_ip = "10.30.0.10"
  }

  service_account {
    email  = google_service_account.multicloud_lab_vm_sa.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = file("${path.module}/../artifacts/install-awscli.sh")

  tags = ["iap-ssh"]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "multicloud-lab-allow-iap-ssh"
  network = google_compute_network.multicloud_lab_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]
}

resource "google_compute_firewall" "allow_icmp" {
  name    = "multicloud-lab-allow-icmp"
  network = google_compute_network.multicloud_lab_vpc.name

  allow {
    protocol = "icmp"
  }

  source_ranges = [aws_subnet.private_subnet.cidr_block]
}
