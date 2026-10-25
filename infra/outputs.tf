output "aws_ami_id" {
  description = "ID of the latest Amazon Linux 2023 AMI for ARM64 architecture."
  value       = data.aws_ami.al2023_arm64.id
}

output "aws_instance_id" {
  description = "ID of the AWS EC2 instance."
  value       = aws_instance.multicloud_lab_vm.id
}

output "eice_id" {
  description = "ID of the AWS EC2 Instance Connect Endpoint (EICE)."
  value       = aws_ec2_instance_connect_endpoint.multicloud_lab_eice.id
}

output "aws_s3_bucket_name" {
  description = "Name of the temporary S3 bucket used to test private connectivity."
  value       = aws_s3_bucket.connectivity_test.bucket
}

output "s3_interface_endpoint_dns" {
  description = "DNS name of the AWS S3 interface endpoint."
  value       = aws_vpc_endpoint.s3_interface.dns_entry[*].dns_name
}

output "sts_interface_endpoint_dns" {
  description = "DNS name of the AWS STS interface endpoint."
  value       = aws_vpc_endpoint.sts_interface.dns_entry[*].dns_name
}

output "aws_federated_role_arn" {
  description = "ARN of the AWS IAM role for GCP workload identity federation."
  value       = aws_iam_role.multicloud_lab_gcp_vm_role.arn
}

output "gcp_bucket_name" {
  description = "Name of the temporary GCP bucket used to test private connectivity."
  value       = google_storage_bucket.basic_bucket.name
}