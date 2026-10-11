# VPN and BGP

## Phase 3 Design

The lab connects AWS `eu-west-2` and GCP `europe-west2` with managed IPsec and
dynamic routing. It deliberately uses one AWS Site-to-Site VPN connection,
which supplies two tunnel endpoints, and one GCP HA VPN gateway.

| Side | Resource | Role |
| --- | --- | --- |
| AWS | Customer Gateway | Represents GCP HA VPN interface 0 and ASN 65432 |
| AWS | Virtual Private Gateway | Terminates VPN for the VPC and uses ASN 65433 |
| AWS | Site-to-Site VPN connection | Creates two outside endpoints, PSKs and inside `/30` ranges |
| GCP | External VPN Gateway | Represents the two AWS outside tunnel IPs |
| GCP | HA VPN gateway | Terminates both initial tunnels on interface 0 |
| GCP | Cloud Router | Runs two BGP sessions and installs dynamic routes |

AWS generates a distinct PSK and RFC 3927 link-local `/30` for each tunnel.
Terraform passes those values directly to GCP. Secrets remain in local
Terraform state and must never be output or committed.

## Availability Scope

Both IPsec tunnels and BGP sessions are healthy, but this is not the complete
99.99% AWS-to-GCP topology. Both tunnels from the first AWS VPN connection
target the same Customer Gateway IP, so both terminate on GCP interface 0.
Interface 1 has no tunnel and the GCP console correctly reports that the HA VPN
gateway is not fully configured for high availability.

A later growth iteration can add:

- a second AWS Customer Gateway referencing GCP interface 1;
- a second AWS Site-to-Site VPN connection;
- two additional AWS outside endpoints;
- two GCP tunnels on interface 1;
- two more Cloud Router interfaces and BGP peers.

This produces four tunnels and removes the current GCP HA topology warning.

## Routing

Cloud Router advertises `10.30.0.0/24`; AWS advertises `10.10.0.0/16`. Traffic
selectors for HA VPN are broad, while BGP controls actual reachable prefixes.
This distinction allows prefixes to change without recreating IPsec tunnels.

AWS route propagation is enabled only on the custom route table associated
with the private subnet. GCP uses regional dynamic routing, so learned routes
currently apply to `europe-west2` resources.

## Troubleshooting Lessons

- `google_compute_router_interface.router` requires the router name. Passing
  the full Terraform ID caused the provider to report an inconsistent result.
- Omitting `ip_range` is valid when `vpn_tunnel` is present, but GCP then
  auto-allocates a link-local range. AWS had already assigned the tunnel inside
  ranges, so each interface had to use AWS's `cgw_inside_address` with `/30`.
- Each BGP peer had to use AWS's `vgw_inside_address` explicitly.
- Changing an interface address while an existing peer retained the old local
  address produced an atomic Cloud Router validation error. A clean deployment
  created interfaces before peers and avoided the transient mismatch.
- AWS can report a tunnel `DOWN` while saying `IPSEC IS UP` when IPsec is
  established but BGP is not. GCP tunnel status and Cloud Router peer status
  must be inspected separately.

## Residual Risks

The GCP tunnels require IKEv2. AWS currently uses its default tunnel proposal
set rather than an explicitly narrowed cipher suite. Initial negotiation is
successful, but a long-lived rekey has not been observed. This is acceptable
for the short-lived lab and should be revisited before treating the design as a
production baseline.
