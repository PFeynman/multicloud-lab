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
