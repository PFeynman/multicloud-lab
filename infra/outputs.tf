output "aws_vpc_id" {
  description = "ID of the AWS lab VPC."
  value       = aws_vpc.multicloud_lab_vpc.id
}

output "aws_subnet_id" {
  description = "ID of the first private AWS subnet."
  value       = aws_subnet.private_subnet.id
}

output "aws_route_table_id" {
  description = "ID of the route table associated with the private AWS subnet."
  value       = aws_route_table.private_subnet_route_table.id
}

output "gcp_network_self_link" {
  description = "Self-link of the GCP lab VPC network."
  value       = google_compute_network.multicloud_lab_vpc.self_link
}

output "gcp_subnetwork_self_link" {
  description = "Self-link of the first private GCP subnet."
  value       = google_compute_subnetwork.private_subnet.self_link
}

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
  value       = aws_vpc_endpoint.s3_interface.dns_entry
}

output "sts_interface_endpoint_dns" {
  description = "DNS name of the AWS STS interface endpoint."
  value       = aws_vpc_endpoint.sts_interface.dns_entry
}
