# Costs

## Phase 0 Baseline

Phase 0 had no deployed network or compute resources.

| Provider | Guardrail | Scope |
| --- | --- | --- |
| AWS | Existing monthly budget, `1 USD` | Entire AWS account |
| AWS | Email alert above `0.01 USD` actual spend | Entire AWS account |
| GCP | Monthly budget, `10 EUR` | Project `multicloud-lab-prp` only |
| GCP | Actual spend alerts at 50%, 80%, 100% | Project only |
| GCP | Forecasted spend alert at 100% | Project only |

Budgets are notifications, not hard spending caps. Billing data and alerts can
also be delayed, so every paid resource must still be reviewed before apply
and checked after destroy.

The AWS Default VPC components do not incur hourly charges while unused. The
GCP project, enabled APIs and Cloud Billing association do not incur charges by
themselves.

## Future Cost Gates

Before introducing each item, record its regional price, hourly cost for the
planned session and deletion condition:

- VPN connections, gateways and public tunnel addresses
- VM runtime, boot disks and public IPv4 addresses
- NAT services, if selected
- Inter-cloud data transfer
- Flow Logs ingestion, storage and retention
- CloudWatch and Cloud Logging storage or queries

## Phase 1

The lab deploys two VPCs, two IPv4 subnets, an AWS route table and its
association, plus registrations for Compute, Service Usage and Cloud Resource
Manager APIs. Expected idle infrastructure cost: zero. No VMs, disks, public
IPs, NAT, VPN or paid telemetry are deployed.

Sources reviewed on 2026-10-02: [AWS VPC pricing overview](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
and [GCP network pricing](https://cloud.google.com/vpc/network-pricing).

Destroy removes the managed network resources. Compute, Service Usage and
Cloud Resource Manager APIs remain enabled; API availability alone has no cost.

## Phase 2

Phase 2 adds one small VM and boot disk in each cloud plus private
administrative access components. Prices vary with region, currency conversion
and runtime; the expected combined order of magnitude while both VMs run is
approximately `EUR 0.30-0.45/day`.

| Provider | Resource | Billing behavior |
| --- | --- | --- |
| AWS | `t4g.nano` EC2 | Per-second compute while running, about EUR 0.10-0.15/day including its disk |
| AWS | 8 GiB `gp3` root EBS | Provisioned storage until the volume is deleted |
| AWS | EC2 Instance Connect Endpoint | No additional endpoint hourly charge |
| GCP | `e2-micro` GCE | Compute while running, about EUR 0.20-0.30/day including its disk |
| GCP | 10 GB `pd-standard` boot disk | Provisioned storage until the disk is deleted |
| GCP | IAP TCP forwarding and firewall rule | No fixed hourly charge for this lab usage |

There are no public IPv4 addresses, NAT services, VPN gateways or enabled flow
logs. Normal SSH traffic is negligible, but provider data transfer pricing can
still apply. The AWS EBS volume is deliberately unencrypted for this ephemeral
lab VM; no sensitive data may be stored on it. The GCP disk uses provider-managed
encryption by default.

`terraform destroy` removes both VMs, their auto-delete boot disks, the EICE,
firewall/security-group resources and both networks. The GCP APIs remain
enabled because `disable_on_destroy = false`; they have no standalone cost.
After destruction, read-only provider inventory must confirm that compute,
disks and endpoint resources are gone.

## Phase 3

Phase 3 adds one AWS Site-to-Site VPN connection and two billed GCP Cloud VPN
tunnels. Cloud Router, route propagation and the gateway objects do not add a
separate hourly charge in this topology.

| Provider | Resource | Approximate charge |
| --- | --- | --- |
| AWS | One Site-to-Site VPN connection | About USD 0.05/hour |
| AWS | Managed public tunnel IPv4 addresses | Standard public IPv4 hourly pricing |
| GCP | Two Cloud VPN tunnels | USD 0.05/hour per tunnel |
| Both | Inter-cloud egress | Variable by direction and transferred volume |

The VPN control plane is approximately USD 0.16/hour or USD 3.84/day before
currency conversion and data transfer. Including Phase 2 compute and disks,
the expected lab total is approximately `EUR 3.5-4.5/day`. This remains active
while idle, so the normal session ends with `terraform destroy`.

Destroy removes the AWS VPN connection, Virtual Private Gateway, Customer
Gateway, GCP tunnels, HA VPN gateway, external gateway and Cloud Router. The
GCP APIs remain enabled without standalone cost. Small connectivity tests add
negligible egress, but later throughput tests require a separate estimate.
