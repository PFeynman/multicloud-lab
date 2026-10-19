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

## 2026-10-05 - Phase 2: private workloads and SSH access

### Objective

Deploy one minimal VM in each cloud, keep both workloads off the public
Internet, and prove that provider-managed private administration paths can
reach them without adding Internet egress.

### Built

- AWS `t4g.nano` Amazon Linux 2023 ARM64 instance at `10.10.0.10`, without a
  public IP, using an 8 GiB `gp3` auto-delete root volume.
- AWS EC2 Instance Connect Endpoint with a dedicated security group. The VM
  security group accepts TCP/22 only from the EICE security group, and the
  endpoint egress rule references the VM security group.
- AWS IMDSv2 is required, metadata hop limit is 1 and burst credits use
  `standard` mode. The EBS encryption exception was accepted for this
  ephemeral VM containing no sensitive data.
- GCP Debian 12 `e2-micro` instance at `10.30.0.10`, without an access config
  or service account, using a 10 GB auto-delete `pd-standard` boot disk.
- GCP classic VPC firewall rule allowing TCP/22 from IAP's
  `35.235.240.0/20` range only to instances tagged `iap-ssh`.
- Private administration through AWS EICE and GCP IAP TCP forwarding. GCP
  currently uses temporary SSH keys in instance metadata; OS Login is deferred.

### Decisions and Concepts

- A separate firewall rule represents each security intent. The IAP SSH rule
  will not be expanded with future application source ranges or ports.
- `google_compute_firewall` was chosen over hierarchical or network firewall
  policies because one VPC rule is sufficient and avoids premature policy and
  association complexity.
- EICE uses `preserve_client_ip = false`, enabling security-group-to-security-
  group authorization and causing the VM to observe the endpoint ENI as source.
- A guest default gateway does not prove Internet reachability. Cloud route
  tables remain authoritative for traffic leaving the virtual network.
- Both clouds expose metadata through `169.254.169.254`, but AWS IMDSv2 uses a
  session token while GCP requires the `Metadata-Flavor: Google` header.
- An attempted full `terraform destroy` emptied state and removed both Phase 1
  networks as well as the initial AWS workload. A subsequent reviewed plan
  recreated the known AWS topology and both networks before adding GCP.

### Tests and Evidence

- Terraform formatting and validation passed; final plan reported no changes.
- AWS instance reported ARM64 and private address `10.10.0.10`; IMDSv1 returned
  HTTP 401 because IMDSv2 is required. A connection to `1.1.1.1:80` timed out.
- AWS CLI opened SSH through EICE without a public IP. The VM observed
  `10.10.0.205:22854 -> 10.10.0.10:22`; AWS API correlated `10.10.0.205` with
  ENI `eni-013fb211393396053` belonging to the endpoint.
- GCP API confirmed the VM was running at `10.30.0.10`, had no public access
  config or service account, and had only the `iap-ssh` network tag.
- GCP API confirmed the only VPC route was `10.30.0.0/24`; there was no
  Internet default route. No firewall existed before the explicit IAP rule.
- SSH through IAP succeeded. The VM observed
  `35.235.242.2:40383 -> 10.30.0.10:22`, correlating the source with IAP's
  `35.235.240.0/20` range and the destination with the firewall rule.
- GCP reported `x86_64`, `10.30.0.10/32`, gateway `10.30.0.1` and a special
  route to metadata address `169.254.169.254`. HTTP to `1.1.1.1` timed out
  after five seconds with curl exit code 28.
- The guest route table exposed the special path to GCP metadata. GCP requires
  the `Metadata-Flavor: Google` request header, and no workload OAuth
  credentials are available because the VM has no service account.

### Problems and Diagnosis

- The first GCP SSH attempt inserted temporary metadata keys but could not
  connect because the VPC had no ingress firewall rule. This demonstrated that
  authentication material does not establish network reachability.
- Querying the new firewall initially used its Terraform intent name rather
  than its effective cloud name. Terraform state identified the deployed name
  `multicloud-lab-allow-iap-ssh`, which was then verified successfully.

### Result and Cost

Phase 2 is complete. Both private VMs are isolated from the public Internet and
from each other, but remain administrable through provider-managed tunnels.
There is no VPN or inter-cloud route yet. Seventeen managed resources plus the
AWS AMI data source are present in Terraform state.

Expected running cost is approximately `EUR 0.30-0.45/day` for both VMs and
disks. No NAT, public IPv4, VPN or flow-log charges exist. Normal cleanup is a
reviewed `terraform destroy`, followed by read-only inventory of VMs, disks and
the EICE.

### Next Step

Begin Phase 3 only after reviewing VPN alternatives, static versus dynamic
routing implications, tunnel count, availability model and regional cost. No
VPN resources are authorized by this Phase 2 completion.

## 2026-10-11 - Phase 3: IPsec VPN and BGP control plane

### Objective

Establish managed IPsec between AWS and GCP, bring up dynamic route exchange,
and verify both providers agree on tunnel, BGP and route state. Workload traffic
is intentionally deferred to Phase 4.

### Built

- AWS Customer Gateway representing GCP HA VPN interface 0 and ASN `65432`.
- AWS Virtual Private Gateway using ASN `65433`, attached to the lab VPC.
- One AWS Site-to-Site VPN connection with two generated tunnel endpoints,
  PSKs and link-local `/30` ranges.
- Route propagation from the Virtual Private Gateway into the custom private
  subnet route table.
- GCP HA VPN gateway, external peer gateway representing two AWS outside IPs,
  and two IKEv2 tunnels terminating on GCP interface 0.
- GCP Cloud Router with two numbered interfaces and two BGP peers.

### Decisions and Concepts

- HA VPN with BGP replaced the earlier Classic VPN/static-routing proposal.
- The initial growth stage uses two tunnels from one AWS VPN connection. It
  gains dynamic routing and tunnel redundancy but does not use GCP interface 1
  and does not qualify for the complete 99.99% topology.
- AWS-generated PSKs and inside addresses are referenced directly by GCP
  resources rather than copied into configuration or outputs.
- AWS advertises its VPC `/16`; GCP advertises the deployed regional subnet
  `/24`, not the conceptual GCP `/16` planning reservation.
- Routing and packet authorization remain separate. Healthy BGP does not prove
  that security groups and firewalls permit workload traffic.

### Tests and Evidence

- Terraform formatting and validation passed; final plan reported no changes.
- Both GCP tunnels reported `ESTABLISHED` and `Tunnel is up and running`.
- Both GCP BGP peers reported `UP` and `Established`; each learned one route
  and advertised `10.30.0.0/24`.
- Cloud Router selected `10.10.0.0/16` with AS path `65433` and priority 100.
- Both AWS tunnels reported `UP`, `1 BGP ROUTES` and one accepted route.
- The AWS private route table contained active propagated route
  `10.30.0.0/24 -> Virtual Private Gateway` alongside its local `/16` route.
- GCP learned the AWS `/16` from both peers. No cross-cloud ping or application
  request was performed in this phase.

### Problems and Diagnosis

- Passing the Cloud Router Terraform ID to standalone interface resources
  caused an inconsistent-result provider error; using the router name allowed
  the resources to persist correctly.
- Automatic GCP link-local allocation did not match AWS-assigned inside tunnel
  addresses. Explicit `cgw_inside_address/30` and `vgw_inside_address` values
  aligned each Cloud Router interface and peer with AWS.
- Updating interface addresses while old BGP peers remained attached caused a
  Cloud Router atomic validation error. A clean deployment created the final
  dependency order successfully.
- The second tunnel initially targeted GCP interface 1, but both tunnels from
  one AWS VPN connection target the single Customer Gateway address on GCP
  interface 0. Correcting the interface brought IPsec up.
- GCP warns that the HA VPN gateway is not configured correctly because
  interface 1 is unused. This is an expected availability warning, not a
  tunnel or BGP fault.

### Result and Cost

Phase 3 is complete. The IPsec and BGP control plane is healthy in both clouds,
and each VPC has an active route to the other's deployed address range. The
topology has two working tunnels but is intentionally not fully HA.

Expected total running cost is approximately `EUR 3.5-4.5/day`, dominated by
the AWS VPN connection and two GCP tunnels. All infrastructure is normally
destroyed at the end of each session to stop hourly charges.

### Next Step

Phase 4 will authorize one explicit cross-cloud flow between `10.10.0.10` and
`10.30.0.10`, run the network test from both directions where useful, and
correlate source, destination, route and tunnel evidence. No Phase 4 firewall
or security-group change is included in this iteration.

## 2026-10-11 - Phase 4: private workload connectivity

### Objective

Authorize and test ICMP between EC2 `10.10.0.10` and GCE `10.30.0.10` using the
private routes learned during Phase 3.

### Built and Learned

- Added AWS security-group ingress and egress ICMP rules scoped to the GCP
  subnet `10.30.0.0/24`.
- Added a GCP firewall rule allowing ICMP from AWS subnet `10.10.0.0/24` to the
  VPC workloads.
- Reused the existing propagated and dynamic routes; no static inter-cloud
  route was needed.
- Confirmed that AWS security groups are stateful and that GCP also has implied
  allow-egress plus stateful return handling.
- Chose subnet ranges rather than individual `/32` addresses so future lab VMs
  can participate without one firewall rule per instance.

### Problems and Diagnosis

The first ping did not receive replies. Diagnosis separated routing from
authorization and checked effective routes, rules in state and the different
AWS/GCP firewall models instead of changing multiple components at once.

### Result

This iteration established the intended Phase 4 policy. Final bidirectional
verification and the phase close were recorded the following day.

## 2026-10-12 - Phase 4 completion and Phase 5 start

### Phase 4 Evidence

- Private ICMP communication between `10.10.0.10` and `10.30.0.10` succeeded.
- Neither workload had a public IP; AWS had no default Internet route.
- AWS and GCP already exposed the corresponding propagated/dynamic routes, so
  the successful test correlated private addresses, route selection, VPN and
  workload authorization.
- Flow logs were not enabled, so the evidence did not identify a specific
  tunnel for each packet.

Phase 4 is complete.

### Phase 5 Objective

Allow each workload to reach Amazon S3 privately, then extend the GCP path with
temporary AWS credentials rather than long-lived keys.

### AWS S3 Path

- Added an EC2 IAM role, shared S3 policy and instance profile.
- The policy deliberately allows broad `s3:*` access for this ephemeral lab.
- Added a private S3 test bucket with public access blocked.
- Added an S3 Gateway Endpoint associated with the private subnet route table.
- Restricted EC2 HTTPS egress to the endpoint's S3 managed prefix list.
- A direct S3 request timed out before the endpoint existed. After the Gateway
  Endpoint and route-table association were correct, `aws s3api list-buckets`
  succeeded with instance-profile credentials.

An initial attempt treated the Gateway Endpoint like a route-table association
target and AWS rejected it. The correct model is to pass the route table to the
Gateway Endpoint resource, which causes AWS to manage the prefix-list route.

### GCP Network Path to S3

- Added an S3 Interface Endpoint with one ENI in `eu-west-2a`.
- Added a dedicated endpoint security group permitting TCP/443 from
  `10.30.0.0/24`.
- Disabled private DNS and used the endpoint-specific S3 DNS name explicitly.
- A request from GCP returned HTTP `403`, proving DNS, VPN routing, endpoint SG,
  TLS and S3 service reachability before GCP had AWS credentials.

The `403` was useful positive network evidence: the service responded and the
remaining problem was authorization, not routing.

## 2026-10-13 - Phase 5: workload identity design

### Decisions

- Selected workload identity federation instead of copying static AWS access
  keys to GCP.
- Attached a dedicated Google service account to the GCE instance.
- Chose a workload-specific OIDC audience,
  `urn:multicloud-lab:gcp-to-aws:s3`.
- Used the GCE metadata identity endpoint because it can issue an identity token
  for the attached service account without Internet access.
- Used AWS's built-in Google identity provider, `accounts.google.com`, rather
  than creating an `aws_iam_openid_connect_provider` resource.

### Claim Mapping

AWS's Google-specific mapping was designed around these token claims:

- Google `azp` maps to the AWS condition key `accounts.google.com:aud`.
- Google `aud` maps to `accounts.google.com:oaud` when `azp` is present.
- Google `sub` maps to `accounts.google.com:sub`.

The role trust therefore pins both the service account numeric identity and the
custom audience. Tokens themselves were decoded only for diagnosis and were
not committed or copied into documentation.

## 2026-10-16 - Phase 5: private STS path

### Problem

OIDC provides identity but the GCP VM still needs network reachability to AWS
STS to exchange that identity for temporary AWS credentials.

### Decision

- Compared Internet egress through NAT with an STS Interface Endpoint.
- Retained a fully private AWS service path by adding STS PrivateLink.
- Deferred GCP Cloud NAT to the later private-versus-public traffic phase.
- Accepted the hourly cost of two Interface Endpoints because the private path
  has greater learning value for this iteration.

The GCP VM must call endpoint-specific STS DNS because private DNS is disabled.
The same security group and VPN return route used by the S3 endpoint support
the STS endpoint.

## 2026-10-17 - Phase 5: IAM and bootstrap preparation

### Built and Diagnosed

- Added the AWS federated role and attached the same broad lab S3 policy.
- Added the STS Interface Endpoint in the AWS private subnet.
- Reused one endpoint security group; one ingress-rule resource belongs to one
  SG, while both endpoints can attach that SG.
- An apply partially created endpoint resources but IAM rejected the trust
  policy with `MalformedPolicyDocument`.
- The policy had interpolated the entire Terraform service-account resource
  where IAM required a scalar string. Referencing the service account
  `unique_id` produced the expected JSON condition values.
- Began preparing the AWS CLI v2 archive for the GCP VM. An SCP attempt exposed
  incorrect remote-destination syntax and motivated a repeatable bootstrap
  path through Cloud Storage instead.

Partial Terraform applies were treated as non-transactional: successful
endpoints remained present and billable while the IAM error was corrected.

## 2026-10-18 - Phase 5: Cloud Storage bootstrap and end-to-end validation

### Cloud Storage Bootstrap

- Created GCS bucket `multicloud-lab-test` with uniform bucket-level access.
- Uploaded `awscliv2.zip` as a Terraform-managed object.
- Granted the VM service account `roles/storage.objectViewer` on the bucket.
- Enabled Private Google Access on subnet `10.30.0.0/24`.
- Added explicit route `0.0.0.0/0 -> default-internet-gateway` because the VPC
  deletes default routes on creation.
- Confirmed that this route plus Private Google Access reaches Google APIs but
  does not provide general Internet access to a VM without an external IP or
  Cloud NAT.
- Added a metadata startup script that downloads the archive, extracts it under
  `/tmp` and installs AWS CLI under `/usr/local`.

The guest agent runs the startup script as root. Its working directory is not a
portable interface, so the final script uses absolute paths. Startup logs
showed a successful Cloud Storage copy and AWS CLI installation; a later check
reported AWS CLI `2.38.1` on Debian 12. Cloud Logging export itself lacked
`logging.logEntries.create`, but the local systemd journal retained the output.

### Problems and Diagnosis

- Private Google Access alone did not create a route. The VM initially timed
  out against Cloud Storage until the explicit default route was present.
- `storage.googleapis.com` initially exposed IPv6 results while the subnet was
  IPv4-only; an IPv4 check after routing was added returned an HTTP response.
- Terraform initially could not find `../artifacts/awscliv2.zip`; the local
  archive and configured source path had to be aligned.
- After network reachability, bucket IAM was a separate requirement. Routing
  and authorization were tested independently.

### End-to-End AWS Test

The user validated the complete private sequence from GCE:

1. Request a Google OIDC identity token from the metadata server.
2. Call the STS Interface Endpoint across the VPN.
3. Assume `multicloud-lab-gcp-vm-role` with web identity.
4. Receive expiring AWS credentials.
5. Call the S3 Interface Endpoint across the VPN.
6. List buckets and objects and download an object from S3.

No token, access key, session token or VPN PSK was persisted in the repository.

### Result, Cost and Remaining Resources

Phase 5 is complete. EC2 accesses S3 through a free Gateway Endpoint and its
instance profile. GCE bootstraps AWS CLI from Cloud Storage, federates its
Google identity into AWS and reaches STS and S3 through private Interface
Endpoints over the VPN.

The active lab costs approximately `EUR 4-5/day`, dominated by the AWS VPN,
two GCP VPN tunnels, two AWS Interface Endpoints and the two small VMs. S3/GCS
storage, requests and test traffic add small variable charges. The VPN,
Interface Endpoints, VMs, disks and buckets remain running until the user
executes `terraform destroy` and provider inventories confirm cleanup.

### Limitations and Next Step

- IAM and endpoint policies are intentionally broad for the lab.
- Interface Endpoints are single-AZ and the VPN still uses only GCP HA VPN
  interface `0`.
- The latest local startup-script cleanup change would replace the GCE instance
  if applied; no apply was performed as part of documentation closure.
- There are no VPC Flow Logs yet. Phase 6 will add bounded cloud-native
  observability and correlate one controlled flow across both clouds.

## 2026-10-19

### Workflow improvement - Iteration 1: methodical mentoring and documentation

- **Objective:** make primary-source guidance, evidence provenance and journal
  maintenance proactive while preserving user ownership of implementation.
- **Status:** complete; checked instruction consistency and `git diff --check`.
- Updated `AGENTS.md` and the four existing files under
  `.opencode/instructions/`; `opencode.json` already loads those files and did
  not require a change.
- Removed the contradiction between requested-only documentation edits and
  proactive journal/bibliography maintenance. Documentation updates now require
  no separate request, while explicit read-only instructions remain respected.
- Defined a substantive iteration, including design, diagnosis, validation,
  blocked work and workflow improvements. Future entries reuse the actual day's
  heading with named iteration subsections rather than adding one per message.
- Required proactive primary documentation with reading guidance, same-iteration
  bibliography updates, and clear separation of observations, user reports,
  configuration intent and inference.
- Strengthened guided diagnosis: one hypothesis/check at a time, giving the
  user room to reason before revealing a complete diagnosis or repair.
- Clarified that delegation of a code edit never permits apply, destroy, state
  mutation or mutating cloud commands. Added protection for sensitive diagnostic
  output and provenance requirements for material cost estimates.
- Corrected stale BGP/PrivateLink roadmap wording and made phase detection
  independent of deployment cleanup.
- No infrastructure changes or cloud inventory checks were performed. Current
  running resources and ongoing cost were not verified in this iteration.
- **Next step:** restart OpenCode to load the instructions, then begin the
  separately agreed Terraform organization and locals review. No refactor or
  next roadmap phase is implemented by this iteration.

### Terraform review - Iteration 2: file organization

- **Objective:** separate AWS endpoints, GCP API enablement and GCP bootstrap
  into cohesive files while preserving resource labels and configuration.
- **Status:** complete for file-only organization; user moved the resources,
  source comparison and configuration checks passed. No deployment was required.
- Consulted HashiCorp's configuration structure documentation and recorded it
  in `docs/references.md`. All files remain in the same root module, `infra/`.
- Proposed extracting endpoint blocks from `aws-network.tf` into
  `aws-endpoints.tf`, API resources from `gcp-network.tf` into `gcp-services.tf`,
  and renaming `gcp-cs.tf`; the user chose `gcp-vm-bootstrap.tf` as its name.
- Keep locals, dependency changes and unused-data-source removal separate from
  this file-only change so its semantic equivalence can be reviewed directly.
- Expected evidence: unchanged resource blocks and addresses, passing format
  and validation checks, and no plan differences attributable to file moves.
- The first validation found an undeclared Compute API resource because the
  editor buffer for `gcp-services.tf` had not been saved. The user saved it;
  `terraform fmt -check -recursive` and `terraform validate` then passed.
- The bootstrap file has the identical Git blob hash as the former `gcp-cs.tf`.
  Extracted endpoint and API blocks match their originals when ignoring
  whitespace. Resource labels, attributes and references are preserved.
- `git diff --check` passed. `terraform state list` returned no addresses, so
  a live no-change plan cannot be used as evidence of this refactor. No plan
  was run; source equivalence supports the file-only conclusion.
- Live inventory and running costs were not verified; empty state is not proof
  of cloud cleanup. File organization itself adds no billable resources.
- **Next step:** separately introduce the agreed small set of topology locals.
