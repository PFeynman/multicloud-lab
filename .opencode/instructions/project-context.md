# Project context and roadmap

## Purpose

This is a personal learning lab for understanding multicloud networking by building, observing, breaking, and diagnosing real infrastructure.

The user already has professional AWS/Terraform experience. Explanations should therefore focus on networking mechanics, provider differences, routing decisions, failure modes, and operational implications rather than introductory cloud concepts.

## Account isolation

### AWS

- Personal AWS account is essentially empty apart from AWS-created defaults.
- Do not use the Default VPC.
- Create a dedicated VPC and resources exclusively for this lab.
- Existing/default resources must be ignored unless the user explicitly chooses otherwise.

### Google Cloud

- The user has an existing GCP project used for unrelated APIs.
- That existing project must never be modified or used for this lab.
- Phase 0 must create/configure a separate GCP project with its own billing association and only the required APIs.
- Provider configuration and CLI checks should make accidental use of the unrelated project difficult.

### Azure

- Azure is future scope only.
- Do not create subscriptions/resource groups/VNets or otherwise deploy Azure resources until explicitly requested.

## Address plan

- AWS: `10.10.0.0/16`
- Azure reserved: `10.20.0.0/16`
- GCP: `10.30.0.0/16`

Preserve non-overlapping address space as the lab evolves.

## Roadmap

- Phase 0: safely prepare AWS and a dedicated GCP project, CLIs, credentials, billing/cost safeguards, Terraform providers.
- Phase 1: create dedicated AWS and GCP networks.
- Phase 2: deploy minimal workloads and study local routing.
- Phase 3: establish AWS <-> GCP Site-to-Site IPsec VPN.
- Phase 4: prove private connectivity.
- Phase 5: add cloud-native flow visibility and observability.
- Phase 6: demonstrate and compare private versus public traffic paths.
- Phase 7: introduce BGP and dynamic route exchange.
- Phase 8: deliberately create routing/VPN failures and diagnose them from evidence.
- Phase 9: introduce Azure using `10.20.0.0/16`.
- Phase 10: explore transit/hub-and-spoke services and architectures.
- Phase 11: study production dedicated-connectivity alternatives conceptually unless their cost is explicitly accepted.

Possible optional later phase: AWS Gateway/Interface VPC Endpoints, PrivateLink, and GCP Private Service Connect to compare service-private-access paths with VPN and Internet paths.
