resource "google_compute_ha_vpn_gateway" "multicloud_lab" {
  name    = "multicloud-lab-1"
  network = google_compute_network.multicloud_lab_vpc.id
  region  = "europe-west2"
}

resource "google_compute_router" "multicloud_lab" {
  name    = "multicloud-lab-1"
  network = google_compute_network.multicloud_lab_vpc.name
  region  = "europe-west2"

  bgp {
    asn = 65432
  }
}

resource "google_compute_external_vpn_gateway" "multicloud_lab" {
  name            = "multicloud-lab-1"
  redundancy_type = "TWO_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = aws_vpn_connection.multicloud_lab.tunnel1_address
  }

  interface {
    id         = 1
    ip_address = aws_vpn_connection.multicloud_lab.tunnel2_address
  }
}

resource "google_compute_vpn_tunnel" "multicloud_lab_tunnel1" {
  name                            = "tunnel1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.multicloud_lab.id
  peer_external_gateway           = google_compute_external_vpn_gateway.multicloud_lab.id
  peer_external_gateway_interface = 0
  shared_secret                   = aws_vpn_connection.multicloud_lab.tunnel1_preshared_key
  router                          = google_compute_router.multicloud_lab.name
  vpn_gateway_interface           = 0
  ike_version                     = 2
}

resource "google_compute_vpn_tunnel" "multicloud_lab_tunnel2" {
  name                            = "tunnel2"
  vpn_gateway                     = google_compute_ha_vpn_gateway.multicloud_lab.id
  peer_external_gateway           = google_compute_external_vpn_gateway.multicloud_lab.id
  peer_external_gateway_interface = 1
  shared_secret                   = aws_vpn_connection.multicloud_lab.tunnel2_preshared_key
  router                          = google_compute_router.multicloud_lab.name
  vpn_gateway_interface           = 0
  ike_version                     = 2
}

resource "google_compute_router_interface" "multicloud_lab_interface1" {
  name       = "multicloud-lab-interface-1"
  router     = google_compute_router.multicloud_lab.name
  vpn_tunnel = google_compute_vpn_tunnel.multicloud_lab_tunnel1.id
  ip_range   = "${aws_vpn_connection.multicloud_lab.tunnel1_cgw_inside_address}/30"
}

resource "google_compute_router_interface" "multicloud_lab_interface2" {
  name       = "multicloud-lab-interface-2"
  router     = google_compute_router.multicloud_lab.name
  vpn_tunnel = google_compute_vpn_tunnel.multicloud_lab_tunnel2.id
  ip_range   = "${aws_vpn_connection.multicloud_lab.tunnel2_cgw_inside_address}/30"
}

resource "google_compute_router_peer" "multicloud_lab_peer_1" {
  name                      = "multicloud-lab-peer-1"
  router                    = google_compute_router.multicloud_lab.name
  peer_asn                  = aws_vpn_connection.multicloud_lab.tunnel1_bgp_asn
  peer_ip_address           = aws_vpn_connection.multicloud_lab.tunnel1_vgw_inside_address
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.multicloud_lab_interface1.name
}

resource "google_compute_router_peer" "multicloud_lab_peer_2" {
  name                      = "multicloud-lab-peer-2"
  router                    = google_compute_router.multicloud_lab.name
  peer_asn                  = aws_vpn_connection.multicloud_lab.tunnel2_bgp_asn
  peer_ip_address           = aws_vpn_connection.multicloud_lab.tunnel2_vgw_inside_address
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.multicloud_lab_interface2.name
}