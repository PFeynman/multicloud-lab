# Multicloud Private Connectivity Lab

<p align="center">
  <img src="docs/assets/readme-header.png" alt="Multicloud private connectivity across AWS, Google Cloud, and Azure" width="100%">
</p>

An incremental lab for studying private connectivity between AWS and Google
Cloud, with Azure planned for a later phase. The goal is to understand and
verify routing, IPsec VPNs, BGP, and observability rather than merely deploy a
working architecture.

## Use of Generative AI

This lab is developed with generative AI acting as a technical mentor and pair
engineer. Its role includes:

- explaining networking concepts and architectural trade-offs;
- reviewing user-written Terraform and helping the user diagnose errors rather
  than diagnosing or fixing them autonomously;
- providing links to primary provider and Terraform documentation for further
  study;
- proposing small, independently verifiable changes;
- running non-mutating validation and inspection commands;
- correlating routes, identities, endpoints, and observed network behavior;
- maintaining diagrams, references, and the chronological lab journal.

The user drives the learning process by writing the infrastructure code,
reasoning through architectural decisions, and verifying each result against
observed cloud and network behavior. The AI supports this work through review,
diagnostic guidance, and links to primary documentation for further study.
Suggestions are not accepted on authority: they are evaluated through
Terraform plans, provider documentation, cloud state, telemetry, and practical
network tests.

Credentials, identity tokens, temporary access keys, VPN pre-shared keys, and
Terraform state are never intentionally provided to the model or committed to
the repository. A phase is considered complete because its behavior has been
verified, not merely because its configuration was generated or reviewed by AI.

## Lab Roadmap

The lab advances through small iterations. Each phase includes reasoned design
decisions, verifiable tests, and updates to the documentation, diagrams, and
lab journal. Before creating billable resources, their cost and deletion
requirements are reviewed.

**Current status: Phases 0 through 5 are complete.** Later phases are a roadmap,
not authorization to deploy them.

| Phase | Work and objective | Status |
| --- | --- | --- |
| 0 - Account preparation | Prepare AWS and GCP accounts, credentials, isolation, budgets, and Terraform providers; verify identities and a no-change plan. | Complete |
| 1 - Lab networks | Define the subnet model and create dedicated AWS and GCP VPCs; verify addressing and isolation. | Complete |
| 2 - VMs and local routing | Create one minimal VM in each cloud and study local routes and access controls. | Complete |
| 3 - Site-to-Site VPN | Select and configure an AWS <-> GCP IPsec VPN; understand gateways, tunnels, BGP, and routes. | Complete |
| 4 - Private connectivity | Test communication between the VMs' private addresses and verify the routes and rules that allow it. | Complete |
| 5 - Private service access | Access S3 from both clouds, federate the GCP workload identity into AWS, and bootstrap AWS CLI from Cloud Storage without a public IP. | Complete |
| 6 - Observability | Add Flow Logs, logs, and metrics to correlate connections and gather evidence of the traffic path. | Pending |
| 7 - Private and Internet traffic | Compare cross-cloud and Internet-bound connections and demonstrate the selected route. | Pending |
| 8 - Advanced BGP and growth | Expand to four tunnels and study route selection, failover, and BGP advertisements. | Pending |
| 9 - Failure diagnosis | Introduce controlled routing and VPN failures, diagnose them from telemetry, and restore connectivity. | Pending |
| 10 - Azure | Prepare Azure and add a VNet using `10.20.0.0/16` to the private connectivity design. | Pending |
| 11 - Advanced architectures | Study hub-and-spoke and transit routing with AWS Transit Gateway, Azure Virtual WAN, and GCP Network Connectivity Center; review costs before deployment. | Pending |
| 12 - Dedicated connectivity | Study AWS Direct Connect, Azure ExpressRoute, and Google Cloud Interconnect conceptually; do not deploy them unless their cost is reasonable for the lab. | Pending |

Each later phase will be refined when it begins. The VPN decision required BGP
as early as Phase 3, so phase boundaries reflect the actual learning sequence.

## Current State

The VPN maintains two IPsec tunnels and two BGP sessions. AWS learns
`10.30.0.0/24`, and GCP learns `10.10.0.0/16`. Private connectivity between
`10.10.0.10` and `10.30.0.10` has been tested in both directions. Both tunnels
deliberately terminate on interface `0` of the HA VPN gateway, so this topology
does not yet implement the complete HA model.

Phase 5 introduces four service flows:

- EC2 obtains credentials from an instance profile and accesses S3 through an
  S3 Gateway Endpoint associated with its route table.
- The GCP VM reaches an AWS S3 Interface Endpoint across the VPN.
- The VM obtains an OIDC identity token from its metadata server and calls the
  STS Interface Endpoint to assume an AWS role and receive temporary
  credentials.
- During startup, the VM downloads AWS CLI from Cloud Storage through Private
  Google Access and installs it before SSH administration begins.

The GCP VM has no public IP and no Cloud NAT. Its explicit
`0.0.0.0/0 -> default-internet-gateway` route makes Private Google Access
usable, but it does not provide general Internet access. Traffic destined for
`10.10.0.0/16` follows the more-specific BGP route through the VPN.

- AWS account: local profile `multicloud-lab`, region `eu-west-2`.
- GCP project: `multicloud-lab-prp`, region `europe-west2`.
- One Terraform root in `infra/` manages both clouds.
- Terraform state remains local during these early phases.

The AWS Default VPC and every unrelated GCP project are out of scope.

## Requirements

- Terraform `>= 1.16.0, < 2.0.0`
- AWS CLI v2 with an active session for profile `multicloud-lab`
- Google Cloud CLI using configuration `multicloud-lab`
- Application Default Credentials with quota project `multicloud-lab-prp`
- A local `artifacts/awscliv2.zip` used to publish AWS CLI to the GCS bucket.
  The preflight downloads the Linux x86-64 archive from AWS if it is missing
  and reuses existing files. The binary is not versioned; signature verification
  remains a manual step before applying the configuration.

## Safe Verification

Before any Terraform operation:

```bash
./scripts/preflight.sh
terraform -chdir=infra init
terraform -chdir=infra validate
terraform -chdir=infra plan
```

After deployment, the plan should report no changes. Before applying a new
iteration, review its resources and costs.

`scripts/verify-phase1.sh` remains useful as a historical check of the isolated
topology, but its route expectations no longer describe Phases 3 through 5.
Current tests should correlate BGP routes, endpoint state, assumed identity,
and S3 operations. Never print or preserve OIDC tokens, temporary access keys,
session credentials, or PSKs.

Local state is sensitive. Existing state and backup files must retain `0600`
permissions; the preflight fails if it detects broader permissions. There is no
remote state backup yet, so losing this workstation could require importing
resources before they can be safely destroyed.

To remove the lab, run the preflight followed by
`terraform -chdir=infra destroy` and review the destruction plan. The GCP APIs
remain enabled. A full destroy has been verified to remove the networks as well
as the VMs; provider inventories must then confirm cleanup. Check VPNs, VPC
endpoints and their ENIs, buckets and objects, roles and instance profiles,
disks, routes, and service accounts.

## Connect to the GCP VM

```bash
gcloud compute ssh multicloud-lab-vm \
  --project=multicloud-lab-prp \
  --zone=europe-west2-a \
  --tunnel-through-iap
```

Authentication currently uses temporary SSH keys in instance metadata. OS
Login is deferred to a later iteration.

## Connect to the AWS VM

```bash
aws ec2-instance-connect ssh \
  --instance-id $(terraform -chdir=infra output -raw aws_instance_id) \
  --os-user ec2-user \
  --connection-type eice \
  --eice-options endpointId=$(terraform -chdir=infra output -raw eice_id) \
  --profile multicloud-lab \
  --region eu-west-2
```

When Terraform creates or replaces the EC2 instance,
`terraform_data.remove_stale_aws_vm_host_key` removes the previous key for
`10.10.0.10` from `~/.ssh/known_hosts`. This prevents conflicts between
different incarnations of the instance without disabling
`StrictHostKeyChecking`. On the first connection to a new instance, SSH asks
the user to accept its new host key.

The synchronization runs only when the instance ID changes. A no-change
`terraform apply` and `terraform destroy` do not modify `known_hosts`.

## Documentation

- [Account preparation](docs/account-preparation.md)
- [Architecture](docs/architecture.md)
- [Routing](docs/routing.md)
- [VPN and IPsec](docs/vpn.md)
- [Observability and evidence](docs/observability.md)
- [Costs](docs/costs.md)
- [Lab journal](docs/lab-journal.md)
- [Bibliography and references](docs/references.md)
