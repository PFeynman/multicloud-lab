# Routing

## Phase 2 Baseline

Neither cloud has a cloud-level default route to the Internet. A route creates
reachability but does not authorize traffic; AWS security groups and GCP
firewall rules independently control which matching flows are accepted.

## AWS

The private subnet `10.10.0.0/24` is associated with an explicit route table.
Its only active route is the automatic VPC-local route:

| Destination | Target | Purpose |
| --- | --- | --- |
| `10.10.0.0/16` | `local` | Communication within the AWS VPC |

The EC2 guest has address `10.10.0.10` and reports a default gateway supplied
by the VPC. That guest route does not create an Internet path: the VPC route
table has no `0.0.0.0/0`, Internet Gateway or NAT target.

Administrative SSH does not depend on Internet routing. EC2 Instance Connect
Endpoint opens a private tunnel and its ENI reaches the instance through the
VPC-local route. With `preserve_client_ip = false`, the VM observed source
`10.10.0.205`, the EICE ENI address, and destination `10.10.0.10:22`.

## GCP

The custom-mode VPC has one automatic subnet route:

| Destination | Next hop | Purpose |
| --- | --- | --- |
| `10.30.0.0/24` | VPC subnet | Communication with the regional subnet |

The default Internet routes were deleted when the VPC was created. Inside the
guest, Linux reports `10.30.0.10/32` and these relevant routes:

```text
default via 10.30.0.1 dev ens4
10.30.0.1 dev ens4 scope link
169.254.169.254 via 10.30.0.1 dev ens4
```

GCE's `/32` guest model and guest default gateway do not imply that a matching
cloud route exists. A request to `http://1.1.1.1` timed out because the VPC has
no `0.0.0.0/0` route. The special link-local route still provides access to
the GCP metadata server when requests include `Metadata-Flavor: Google`.

IAP TCP forwarding also does not require a VM public IP or Internet default
route. The ingress firewall allows TCP/22 only from `35.235.240.0/20` to VMs
tagged `iap-ssh`. The VM observed source `35.235.242.2`, proving that the
connection arrived through the IAP proxy range.

## Inter-cloud State

There is no route from AWS to `10.30.0.0/16` and no route from GCP to
`10.10.0.0/16`. The two VMs are privately administrable but cannot communicate
with each other. Phase 3 will introduce the VPN components and explicit route
decisions; no VPN design is implied by the current route tables.
