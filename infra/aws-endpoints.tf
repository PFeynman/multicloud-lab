resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id          = aws_vpc.multicloud_lab_vpc.id
  service_name    = "com.amazonaws.${local.aws_region}.s3"
  route_table_ids = [aws_route_table.private_subnet_route_table.id]

  tags = {
    Name = "multicloud-lab-s3-gateway-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3_interface" {
  vpc_id            = aws_vpc.multicloud_lab_vpc.id
  service_name      = "com.amazonaws.${local.aws_region}.s3"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.gcp_interface_endpoints.id,
  ]

  subnet_ids = [
    aws_subnet.private_subnet.id,
  ]

  private_dns_enabled = false

  tags = {
    Name = "multicloud-lab-s3-interface-endpoint"
  }
}

resource "aws_vpc_endpoint" "sts_interface" {
  vpc_id            = aws_vpc.multicloud_lab_vpc.id
  service_name      = "com.amazonaws.${local.aws_region}.sts"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.gcp_interface_endpoints.id,
  ]

  subnet_ids = [
    aws_subnet.private_subnet.id,
  ]

  private_dns_enabled = false

  tags = {
    Name = "multicloud-lab-sts-interface-endpoint"
  }
}

resource "aws_security_group" "gcp_interface_endpoints" {
  name        = "gcp-interface-endpoints"
  description = "Security group for interface endpoints."
  vpc_id      = aws_vpc.multicloud_lab_vpc.id

  tags = {
    Name = "gcp-interface-endpoints"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_gcp_interface_endpoints" {
  security_group_id = aws_security_group.gcp_interface_endpoints.id

  cidr_ipv4   = google_compute_subnetwork.private_subnet.ip_cidr_range
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  tags = {
    Name = "allow_https_from_gcp"
  }
}