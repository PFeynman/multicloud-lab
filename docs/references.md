# References

This bibliography collects the primary sources used during the lab. Entries
are grouped by phase and explain why each source is relevant. Product behavior
and pricing can change, so the access date is part of the record.

## Phase 2 - GCE and private administration

Sources reviewed on 2026-10-05.

### Compute Engine instances

- [Compute Engine instances overview](https://cloud.google.com/compute/docs/instances)
  - GCE instance lifecycle, placement and basic resource model.
  - Relevant to the `e2-micro` workload at `10.30.0.10`.
- [Create and start a Compute Engine instance](https://cloud.google.com/compute/docs/instances/create-start-instance)
  - Boot disk, machine type, network interface and access configuration.
- [Terraform `google_compute_instance`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance)
  - Provider schema and examples for the resource used by the lab.
- [VM metadata overview](https://cloud.google.com/compute/docs/metadata/overview)
  - Metadata server behavior, `169.254.169.254` and the required
    `Metadata-Flavor: Google` request header.
- [OS Login overview](https://cloud.google.com/compute/docs/oslogin)
  - IAM-based Linux access and the alternative to metadata-managed SSH keys.

### Identity-Aware Proxy SSH access

- [IAP TCP forwarding overview](https://cloud.google.com/iap/docs/tcp-forwarding-overview)
  - How IAP reaches private VMs without assigning public IP addresses.
- [Using IAP for TCP forwarding](https://cloud.google.com/iap/docs/using-tcp-forwarding)
  - Required IAM permissions, firewall source range and `gcloud` connection
    workflow.
- [Create firewall rules for IAP TCP forwarding](https://cloud.google.com/iap/docs/using-tcp-forwarding#create-firewall-rule)
  - Official source for allowing `35.235.240.0/20` to the required destination
    ports only.
- [Terraform `google_compute_firewall`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall)
  - Provider schema for the `allow-iap-ssh` rule and its target tags.

## Phase 3 - AWS to GCP IPsec VPN

Sources reviewed on 2026-10-11.

The lab uses HA VPN with BGP but deliberately starts with the two tunnels from
one AWS VPN connection terminating on GCP HA VPN interface 0. This does not
qualify for the 99.99% topology. A later growth iteration can add a second AWS
VPN connection and use GCP interface 1, bringing the total to four tunnels.

### Suggested reading order

1. Read **Cloud VPN overview**, focusing on HA VPN, IPsec/IKE and Cloud Router.
2. Read **Cloud VPN networks and tunnel routing**, focusing on the difference
   between traffic selectors and routes.
3. Read **Create HA VPN connections between Google Cloud and AWS**, focusing
   on the mapping between AWS tunnel parameters and Cloud Router interfaces.
4. Read the AWS concepts before creating the peer-side gateway resources.

### Concepts and design choice

- [Cloud VPN overview](https://cloud.google.com/network-connectivity/docs/vpn/concepts/overview)
  - Differences between HA VPN and Classic VPN, gateway behavior and IPsec
    terminology.
- [Cloud VPN networks and tunnel routing](https://cloud.google.com/network-connectivity/docs/vpn/concepts/choosing-networks-routing)
  - Static versus dynamic routing, route-based and policy-based tunnels,
    traffic selectors and their distinction from VPC routes.
- [Classic VPN topologies](https://cloud.google.com/network-connectivity/docs/vpn/concepts/classic-topologies)
  - Supported Classic VPN layouts and their availability limitations.
- [Create a Classic VPN using static routing](https://cloud.google.com/network-connectivity/docs/vpn/how-to/creating-static-vpns)
  - Required gateway, external address, forwarding rules, tunnel and custom
    routes.
- [AWS Site-to-Site VPN concepts](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPC_VPN.html)
  - AWS customer gateway, target gateway, VPN connection and dual-tunnel
    model.
- [How AWS Site-to-Site VPN works](https://docs.aws.amazon.com/vpn/latest/s2svpn/HowItWorks.html)
  - Routing, tunnel endpoint behavior and static versus dynamic options.
- [Create HA VPN connections between Google Cloud and AWS](https://cloud.google.com/network-connectivity/docs/vpn/tutorials/create-ha-vpn-connections-google-cloud-aws)
  - Official cross-cloud topology and mapping of outside addresses, PSKs,
    inside `/30` ranges, Cloud Router interfaces and BGP peers.

### Terraform resources

#### Classic VPN alternative evaluated

- [Terraform `google_compute_address`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address)
  - Regional static external address used by the Classic VPN gateway.
- [Terraform `google_compute_vpn_gateway`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_gateway)
  - Classic target VPN gateway attached to the lab VPC.
- [Terraform `google_compute_forwarding_rule`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule)
  - Forwarding rules for ESP, UDP/500 and UDP/4500.

#### Implemented HA VPN and BGP resources

- [Terraform `google_compute_router_interface`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_interface)
  - Cloud Router interface and RFC 3927 link-local `ip_range` configuration.
- [Terraform `google_compute_router_peer`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_peer)
  - BGP peer ASN and peer inside-address configuration.
- [Terraform `google_compute_ha_vpn_gateway`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ha_vpn_gateway)
  - Regional HA VPN gateway and its two outside interfaces.
- [Terraform `google_compute_external_vpn_gateway`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_external_vpn_gateway)
  - Representation of the two AWS peer tunnel endpoints.
- [Terraform `google_compute_vpn_tunnel`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_tunnel)
  - IKEv2 tunnel mapping between GCP and AWS interfaces.
- [Terraform `aws_customer_gateway`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/customer_gateway)
  - AWS representation of GCP interface 0 and its BGP ASN.
- [Terraform `aws_vpn_gateway`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway)
  - Virtual Private Gateway attachment and AWS-side ASN.
- [Terraform `aws_vpn_connection`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection)
  - Generated tunnel endpoints, PSKs, inside ranges and BGP attributes.
- [Terraform `aws_vpn_gateway_route_propagation`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway_route_propagation)
  - Propagation of learned routes into the private AWS route table.

### Cost

- [Google Cloud VPN pricing](https://cloud.google.com/network-connectivity/docs/vpn/pricing)
  - Hourly tunnel charges, external IP treatment and data transfer pricing.
- [AWS VPN pricing](https://aws.amazon.com/vpn/pricing/)
  - Site-to-Site VPN connection-hour, public IPv4 and data transfer charges.
