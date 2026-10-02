output "aws_vpc_id" {
  description = "ID of the AWS lab VPC."
  value       = aws_vpc.multicloud-lab-vpc.id
}

output "aws_subnet_id" {
  description = "ID of the first private AWS subnet."
  value       = aws_subnet.private-subnet.id
}

output "aws_route_table_id" {
  description = "ID of the route table associated with the private AWS subnet."
  value       = aws_route_table.private-subnet-route-table.id
}

output "gcp_network_self_link" {
  description = "Self-link of the GCP lab VPC network."
  value       = google_compute_network.multicloud-lab-vpc.self_link
}

output "gcp_subnetwork_self_link" {
  description = "Self-link of the first private GCP subnet."
  value       = google_compute_subnetwork.private-subnet.self_link
}
