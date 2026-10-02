# Lab Journal

## 2026-10-01 - Phase 0: account bootstrap

### Built

- Installed Google Cloud CLI `587.0.0`.
- Created isolated gcloud configuration `multicloud-lab`.
- Created GCP project `multicloud-lab-prp` with billing enabled.
- Configured user ADC with the lab project as quota project.
- Created local AWS profile `multicloud-lab` using temporary `aws login`
  credentials and region `eu-west-2`.
- Verified the existing account-wide AWS budget and created a project-scoped
  GCP budget.
- Added a provider-only Terraform root with local state.

### Learned

- CLI configuration isolation and IAM isolation are separate controls.
- A cloud project or enabled API does not itself imply billable resources.
- Budgets alert after billing data arrives; they do not enforce a hard cap.
- Provider defaults must be inventoried and kept outside Terraform ownership.

### Decisions

- Regions: AWS `eu-west-2`, GCP `europe-west2`.
- Terraform: one multicloud root and local state for the initial phases.
- Authentication: temporary human credentials, without static keys.
- AWS Default VPC: preserve and ignore.
- GCP auto-enabled APIs: document and preserve.
- Azure: not prepared or deployed yet.

### Problems and Diagnosis

- The first GCP project ID, `multicloud-lab`, was globally unavailable. No
  resource was created; `multicloud-lab-prp` succeeded.
- gcloud could not validate a default region before a project was selected.
  The region was set after the dedicated project became active.
- The selected GCP billing account uses EUR, so the requested budget became
  `10 EUR` rather than `10 USD`.

### Tests

- Verified AWS identity with STS and confirmed it is not root.
- Verified GCP active account, project, region and ADC token acquisition.
- Verified GCP billing and project-only budget filter.
- Inventoried AWS London: no EC2, EBS, Elastic IP, NAT, VPN, Transit Gateway or
  CloudWatch Logs resources were present.
- Ran the identity preflight successfully.
- Initialized Terraform providers, validated the configuration and confirmed
  an empty plan with no changes.

### Result and Cost

Phase 0 cloud preparation is functional. No lab infrastructure is deployed and
the expected current infrastructure cost is zero.

### Next Step

Review the proposed VPC and subnet model for Fase 1. Fase 1 must not begin until
it is explicitly approved.

## 2026-10-02 - Phase 1: isolated networks

### Built

- User implemented explicit Terraform resources for an AWS VPC, subnet,
  route table and association; GCP custom VPC, subnet and Compute API.
- Applied the reviewed plan. Seven managed resources are now in local state.

### Learned and Decisions

- AWS VPC CIDR is `10.10.0.0/16`; first subnet is `10.10.0.0/24` in eu-west-2a.
- GCP `10.30.0.0/16` is conceptual planning space; regional subnet is /24.
- IPv4 only; dual stack deferred to a future iteration.
- No Internet access initially. Public subnets versus NAT will be studied later.
- AWS creates the `10.10.0.0/16 -> local` route automatically in every route
  table belonging to the VPC. This route covers communication between all
  subnets whose CIDRs are contained in the VPC CIDR.
- A route table association is per subnet. If we add another AWS subnet, the
  existing local route already covers it, but we must explicitly associate
  that subnet with the intended custom route table; otherwise it uses the
  VPC's main route table.
- GCP creates one subnet route for each subnet range. A future
  `10.30.1.0/24` subnet would therefore add a second route alongside the
  existing `10.30.0.0/24` route.
- GCP subnets are regional, not zonal. Instances in different zones of
  `europe-west2` can use the same `10.30.0.0/24` subnet.
- The different route prefixes reflect the providers' network models: AWS
  assigns `10.10.0.0/16` to the VPC, while GCP assigns `10.30.0.0/24` to the
  subnet and treats our `/16` only as an address-planning reservation.
- A route establishes reachability but does not grant traffic by itself;
  security groups, network ACLs and GCP firewall rules are separate controls.
- User chose to omit allowed_account_ids; identity protection remains in preflight.
- Compute API remains enabled after destroy. Cloud Resource Manager is a
  bootstrap prerequisite enabled with gcloud outside Terraform.

### Problems and Diagnosis

- Sandbox networking prevented preflight; reran with approved access.
- Initial apply created AWS but failed on GCP API management with a 403:
  Cloud Resource Manager was disabled. Enabled it only in the lab project.
- Regenerated and reviewed the plan, then retried. Compute API registration
  was tainted and replaced without disabling the API (disable_on_destroy=false).
- Partial apply retains successful resources in state; recovery does not
  require destroying the successfully created AWS network.

### Tests

- Preflight verified AWS account, GCP project and ADC.
- Reviewed initial plan: 7 additions, no changes or deletions.
- AWS API confirmed subnet association and only the active local /16 route.
- GCP API confirmed only the /24 subnet route, with no Internet default route;
  subnet is IPV4_ONLY in europe-west2.
- Final Terraform plan exited 0 with no changes.
- No workload connectivity or destroy test yet; there are no VMs.

### Result and Cost

Phase 1 complete. Both lab networks are deployed and isolated from Internet
and each other. Expected idle infrastructure cost is zero for this scope.
AWS Default VPC and other GCP projects were not modified.

### Next Step

Discuss Phase 2 VM sizing, administration access and cost before implementing.
No Phase 2 resources are authorized or deployed by this iteration.

## 2026-10-02 - Phase 1 follow-up: API management

- User requires cloud mutations through Terraform; CLI mutations are reserved
  for cases with no viable Terraform alternative, explained in advance.
- Declared Service Usage and Cloud Resource Manager alongside Compute, with
  explicit dependencies. Kept disable_on_destroy=false for all three APIs.
- Added google.bootstrap without user project quota override for support APIs.
- Corrected the earlier CLI recovery approach: the bootstrap provider pattern
  should have been evaluated before enabling Cloud Resource Manager manually.
- No change to network architecture or expected idle cost. Phase 2 remains pending.
- Verification: preflight and validate passed; reviewed plan added only the two
  support API resources. Apply succeeded; nine resources are now managed.
  Final plan exited 0 with no changes. No mutating gcloud command was used.

## 2026-10-03 - Phase 1 review before workloads

- Reviewed all Terraform and documentation; no functional topology defect or
  drift was found across the nine managed resources.
- Restricted local state and backup permissions from `0644` to `0600`.
- Made current network defaults explicit: AWS DNS settings; GCP regional
  routing, MTU, IPv4 stack and disabled Private Google Access.
- Added non-sensitive Terraform outputs needed by repeatable verification.
- Strengthened preflight to verify gcloud and ADC identities separately, the
  ADC quota project, region and state file permissions.
- Added a read-only Phase 1 verification script for subnet properties,
  associations and effective AWS/GCP routes.
- Applied `0 add, 1 change, 0 destroy`: the only API update made GCP's effective
  default MTU 1460 explicit; five non-sensitive outputs were added to state.
- The first verification run exposed incorrect `jq` pipe precedence in the new
  script. Corrected the expressions and reran successfully against both clouds.
- Final validation passed and Terraform reported no changes.
- Preserved the decisions to use local state and omit `allowed_account_ids`.
- Phase 2 access decision: private administration through EC2 Instance Connect
  Endpoint on AWS and IAP with OS Login on GCP; no VM Internet egress.
- Phase 2 instance preference: AWS `t4g.nano` (ARM) and GCP `e2-micro` (x86).
