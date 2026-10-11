resource "aws_customer_gateway" "multicloud_lab" {
  bgp_asn    = google_compute_router.multicloud_lab.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.multicloud_lab.vpn_interfaces[0].ip_address
  type       = "ipsec.1"

  tags = {
    Name = "multicloud-lab-1"
  }
}

resource "aws_vpn_gateway" "multicloud_lab" {
  vpc_id          = aws_vpc.multicloud_lab_vpc.id
  amazon_side_asn = 65433

  tags = {
    Name = "multicloud-lab-1"
  }
}

resource "aws_vpn_gateway_route_propagation" "private_subnet" {
  vpn_gateway_id = aws_vpn_gateway.multicloud_lab.id
  route_table_id = aws_route_table.private_subnet_route_table.id
}

resource "aws_vpn_connection" "multicloud_lab" {
  customer_gateway_id = aws_customer_gateway.multicloud_lab.id
  vpn_gateway_id      = aws_vpn_gateway.multicloud_lab.id
  type                = aws_customer_gateway.multicloud_lab.type
}
