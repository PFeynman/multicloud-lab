resource "aws_s3_bucket" "connectivity_test" {
  bucket_prefix = "multicloud-connectivity-test-"
  force_destroy = true

  tags = {
    Name = "multicloud-connectivity-test"
  }
}

resource "aws_s3_bucket_public_access_block" "connectivity_test" {
  bucket = aws_s3_bucket.connectivity_test.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
