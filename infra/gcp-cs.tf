resource "google_storage_bucket" "basic_bucket" {
  name     = "multicloud-lab-test"
  location = "EU"

  uniform_bucket_level_access = true

  force_destroy = true
}

resource "google_storage_bucket_object" "aws_cli" {
  name   = "awscliv2.zip"
  bucket = google_storage_bucket.basic_bucket.name
  source = "${path.module}/../artifacts/awscliv2.zip"
}

resource "google_storage_bucket_iam_member" "vm_read_bucket" {
  bucket = google_storage_bucket.basic_bucket.name
  role   = "roles/storage.objectViewer"

  member = "serviceAccount:${google_service_account.multicloud_lab_vm_sa.email}"
}
