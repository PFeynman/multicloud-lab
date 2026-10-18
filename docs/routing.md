# Routing

## Historical baseline

Phase 2 intentionally had no cloud-level default route and no inter-cloud
route. Phase 3 introduced BGP. Phase 4 authorized workload traffic, and Phase 5
added routes for private service access. Guest default gateways alone never
proved cloud reachability; provider route tables remain authoritative.

## Current AWS routes

The AWS private subnet `10.10.0.0/24` uses one explicit route table:

| Destination | Target | Origin and purpose |
| --- | --- | --- |
| `10.10.0.0/16` | `local` | Automatic VPC-local route |
| `10.30.0.0/24` | Virtual Private Gateway | Propagated BGP route to GCP |
| S3 managed prefix list | S3 Gateway Endpoint | Private EC2-to-S3 path |

There is no AWS `0.0.0.0/0`, Internet Gateway or NAT route. The EC2 instance
can reach S3 because AWS inserts the service prefix-list route when the Gateway
Endpoint is associated with this route table. Its security group independently
permits TCP/443 only to that prefix list.

The S3 and STS Interface Endpoint ENIs are inside `10.10.0.0/24`. Traffic from
GCP reaches those private addresses through the advertised AWS `/16`; return
traffic uses the propagated `10.30.0.0/24` route. Security groups are stateful,
so accepted inbound endpoint connections allow their response traffic.

## Current GCP routes

The GCP VPC has these relevant effective routes:

| Destination | Next hop | Purpose |
| --- | --- | --- |
| `10.30.0.0/24` | Subnet | Automatic local subnet route |
| `10.10.0.0/16` | HA VPN/Cloud Router | Dynamic route learned from AWS |
| `0.0.0.0/0` | Default internet gateway | Required route shape for Private Google Access |
| `169.254.169.254/32` | GCE metadata path | Link-local metadata and identity service |

The VPC was created with `delete_default_routes_on_create = true`; Phase 5 adds
one explicit replacement default route. The VM still has no external IP and no
Cloud NAT. Therefore this route does not offer arbitrary Internet egress.
Private Google Access allows eligible Google APIs, including Cloud Storage, to
use the route from a VM with only an internal address.

## Route selection examples

### GCE to AWS endpoints

The Interface Endpoint private IP belongs to `10.10.0.0/16`. The learned `/16`
is more specific than `0.0.0.0/0`, so GCP selects the VPN route. AWS returns to
`10.30.0.10` through its propagated `/24`. The GCP default internet gateway is
not in this flow.

### GCE to Cloud Storage

Public Google API addresses match `0.0.0.0/0`. The next hop is the default
internet gateway, but Private Google Access authorizes the special Google API
path for the internal-only VM. A successful download does not imply that an
arbitrary public destination is reachable.

### GCE to metadata

The metadata request selects the link-local path to `169.254.169.254`; neither
the VPN nor Private Google Access is involved. This is where the VM obtains its
Google-signed OIDC identity token.

### EC2 to S3

The S3 managed prefix-list route is more specific than any absent default
route, selecting the Gateway Endpoint. Gateway Endpoints are not transitive,
which is why GCP needs a separate S3 Interface Endpoint.

## Routing versus authorization

Routes select a next hop; they do not grant access. The verified flows also
depend on:

- AWS security-group ICMP rules for Phase 4;
- the GCP ICMP firewall rule;
- endpoint SG ingress TCP/443 from `10.30.0.0/24`;
- EC2 instance-profile permissions;
- Google Cloud Storage bucket IAM;
- OIDC claims matching the AWS role trust policy;
- temporary-role permissions for S3.

Phase 6 will add flow logs so route reasoning can be correlated with observed
source, destination, action and interface data.
