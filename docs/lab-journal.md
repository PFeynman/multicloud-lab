# Lab Journal

This journal records outcomes, decisions and reusable lessons. Resource status
and cost estimates describe the observation at the time of each entry, not a
current inventory. Historical results are retained as the lab evolves.

## 2026-10-01

### Phase 0 - Account bootstrap

- **Complete:** prepared AWS profile `multicloud-lab` with temporary credentials
  and dedicated GCP project `multicloud-lab-prp` with billing, isolated gcloud
  configuration and user ADC using the lab quota project.
- Selected AWS `eu-west-2` and GCP `europe-west2`, one Terraform root and local
  state. AWS defaults and unrelated GCP projects remain outside lab ownership.
- Verified identities, billing, budgets and preflight; Terraform validation and
  a no-change plan passed. The initial AWS regional inventory contained no
  billable lab resources; expected infrastructure cost was zero.
- Retained the existing AWS budget and added a GCP project budget of `EUR 10`.
  Budgets notify after billing data arrives; they are not hard spending caps.
- **Lesson:** CLI configuration isolation is not IAM isolation, and enabled
  APIs do not themselves imply deployed billable infrastructure.
- **Next:** design dedicated networks before adding workloads.

## 2026-10-02

### Phase 1 - Isolated networks

- **Complete:** deployed AWS VPC `10.10.0.0/16`, subnet `10.10.0.0/24` in
  `eu-west-2a`, and an explicit associated route table; deployed a GCP custom
  VPC with IPv4 subnet `10.30.0.0/24` in `europe-west2`. Neither network had an
  Internet default route or inter-cloud connectivity.
- **Network-model lesson:** AWS's automatic VPC-local `/16` route covers its
  subnets, but each subnet needs the intended route-table association. GCP
  creates routes per regional subnet; `10.30.0.0/16` is only planning space,
  not a GCP VPC CIDR attribute.
- A partial apply created AWS resources before GCP API management failed because
  Cloud Resource Manager was disabled. Recovery preserved the successful
  resources: Terraform apply is not transactional.
- Provider checks confirmed the intended subnet associations and only local
  routes. The final plan reported no changes. Expected idle cost was zero.
- Chose to omit AWS `allowed_account_ids`; explicit profile selection and
  preflight remain the account-targeting controls.

### Phase 1 follow-up - API management

- **Complete:** represented Service Usage and Cloud Resource Manager alongside
  Compute in Terraform, with explicit dependencies and `disable_on_destroy =
  false`. A bootstrap Google provider without quota-project override avoids
  support-API bootstrap dependencies.
- The initial Cloud Resource Manager recovery used gcloud; subsequent API
  management moved into Terraform. Reviewed apply and final no-change plan
  confirmed the configuration, without additional networking cost.
- **Next:** review VM sizing, private administration and cost.

## 2026-10-03

### Phase 1 - Review before workloads

- **Complete:** made DNS, regional routing, MTU 1460, IPv4 and disabled Private
  Google Access explicit; added diagnostic outputs and a read-only network
  verifier. Validation, provider checks and the final no-change plan passed.
- Restricted state and backup permissions to `0600`. Preflight now checks AWS,
  gcloud and ADC identities independently, including ADC quota project.
- Selected private administration through AWS EICE and GCP IAP, with OS Login
  initially planned. Preferred `t4g.nano` ARM64 and `e2-micro` x86 workloads.
- **Lesson:** Terraform ADC and the active gcloud configuration are separate
  authentication contexts and must be checked independently.

## 2026-10-05

### Phase 2 - Private workloads and SSH

- **Complete:** deployed EC2 `t4g.nano` with Amazon Linux 2023 at `10.10.0.10`
  and Debian 12 GCE `e2-micro` at `10.30.0.10`, both without public IPs. Boot
  disks were auto-delete: 8 GiB AWS `gp3` and 10 GB GCP `pd-standard`.
- AWS requires IMDSv2, uses metadata hop limit 1 and standard burst credits.
  Unencrypted EBS was accepted for this ephemeral, non-sensitive workload.
  GCE initially had no attached service account.
- EICE uses dedicated security groups and `preserve_client_ip = false`.
  Observed SSH source `10.10.0.205` was correlated with its ENI by AWS API.
  IAP SSH source `35.235.242.2` matched the firewall's `35.235.240.0/20` range.
  GCP used temporary metadata SSH keys; OS Login was deferred.
- **Diagnostic lesson:** installing SSH authentication material did not make
  GCE reachable until the ingress firewall existed. Authentication and network
  authorization are independent.
- Both guests had default gateways, but cloud routes provided no Internet
  egress. HTTP to `1.1.1.1` timed out. AWS IMDSv1 returned `401`; GCP metadata
  remained reachable through its special link-local path.
- A full destroy also removed the Phase 1 networks, demonstrating that cleanup
  applies to the whole root rather than only the latest phase. A reviewed
  deployment recreated the topology. Formatting, validation and final plan
  checks passed.
- Last observed workloads were privately administrable but isolated from each
  other and Internet. Estimated compute/disk cost: `EUR 0.30-0.45/day`.
- **Next:** choose VPN topology, routing and availability model.

## 2026-10-11

### Phase 3 - IPsec VPN and BGP control plane

- **Complete:** connected AWS VGW ASN `65433` and GCP Cloud Router ASN `65432`
  using one AWS Site-to-Site VPN connection, two IKEv2 tunnels and two BGP peers.
  AWS route propagation was enabled on the private subnet route table.
- Selected HA VPN/BGP over the earlier Classic VPN/static-route proposal.
  AWS-generated PSKs and inside addresses are referenced directly by GCP;
  secrets remain in local state, not configuration or outputs.
- Both tunnels terminate on GCP HA VPN interface `0`: one AWS Customer Gateway
  represents one GCP outside IP. Interface `1` remains unused, so the topology
  warning is expected and the complete 99.99% HA design is not implemented.
- **Diagnosis:** standalone router interfaces required the router name rather
  than its full Terraform ID. GCP's automatically allocated link-local ranges
  did not match AWS's inside addresses; explicit AWS-derived `/30` interfaces
  and peer IPs resolved the mismatch. Updating interfaces with attached old
  peers exposed Cloud Router's atomic validation constraints.
- Provider evidence showed both IPsec tunnels and BGP peers up. GCP learned
  `10.10.0.0/16` with AS path `65433`, priority 100; AWS installed active
  propagated `10.30.0.0/24 -> VGW`. Final Terraform checks passed with no changes.
- **Lesson:** healthy IPsec/BGP establishes control-plane reachability, not
  permission for workload traffic. No cross-cloud application test occurred in
  this phase.
- Estimated total running cost: `EUR 3.5-4.5/day`, dominated by VPN charges.

### Phase 4 - Private workload authorization

- **In progress:** added AWS ICMP ingress/egress for GCP `10.30.0.0/24` and a
  GCP ICMP ingress rule for AWS `10.10.0.0/24`, reusing existing BGP routes.
- Chose subnet ranges over individual `/32` rules to support future lab VMs.
  AWS security groups and GCP firewalls permit stateful replies; GCP also has
  implied allow-egress, unlike the explicit AWS workload egress rules.
- Initial unanswered pings prompted separate checks of effective routes and
  packet authorization. Bidirectional completion was recorded the next day.

## 2026-10-12

### Phase 4 - Private connectivity completion

- **Complete:** private ICMP succeeded between `10.10.0.10` and `10.30.0.10`.
  Private addresses, learned routes, no workload public IPs and no AWS Internet
  default route supported the VPN-path conclusion.
- Flow logs were not enabled; the evidence did not identify a particular tunnel
  for each packet. The rules added no direct cost beyond existing VPN and test
  traffic charges.

### Phase 5 - EC2 access to S3

- Added an EC2 IAM role and instance profile, private test bucket with public
  access blocked, and S3 Gateway Endpoint. EC2 HTTPS egress is scoped to the S3
  managed prefix list. Broad `s3:*` permissions were accepted for the lab.
- S3 timed out before the endpoint existed; afterward,
  `aws s3api list-buckets` succeeded with instance-profile credentials.
- **Routing lesson:** associate the route table through the Gateway Endpoint,
  not an `aws_route_table_association` gateway target. AWS then manages the S3
  prefix-list route. Gateway Endpoints are regional and not VPN-transitive.

### Phase 5 - GCP network path to S3

- Added a single-AZ S3 Interface Endpoint in `eu-west-2a`, with TCP/443 ingress
  from `10.30.0.0/24`. Private DNS is disabled; GCP explicitly uses endpoint DNS.
- A GCP request returned HTTP `403`: service reachability worked before AWS
  authorization was configured. This distinguished network failure from denied
  access. Identity federation remained pending.

## 2026-10-13

### Phase 5 - Workload identity design

- Selected Google-to-AWS OIDC federation rather than copying static AWS keys.
  Attached a dedicated Google service account and designed a workload-specific
  audience, ultimately `urn:multicloud-lab:gcp-to-aws:s3`.
- GCE metadata can issue an identity token for the attached service account
  without Internet access. AWS uses its built-in `accounts.google.com` provider;
  no customer-managed OIDC provider resource is needed.
- **Claim-mapping lesson:** when Google `azp` is present, AWS
  `accounts.google.com:aud` maps to `azp`, `:oaud` to Google `aud`, and `:sub` to
  Google `sub`. The trust pins the service-account numeric identity and audience.
  Tokens were not retained in documentation.

## 2026-10-16

### Phase 5 - Private STS design

- Chose an STS Interface Endpoint so GCE could exchange its OIDC token for
  temporary AWS credentials without general Internet egress.
- Accepted two Interface Endpoint hourly charges for the learning value of a
  private service path. GCP Cloud NAT was deferred to the public/private-path
  comparison phase.
- STS requires explicit endpoint DNS with private DNS disabled; the same VPN
  return route and shared endpoint security group support S3 and STS.

## 2026-10-17

### Phase 5 - IAM trust and bootstrap preparation

- Added the federated AWS role, broad lab S3 policy attachment and STS Interface
  Endpoint. Both endpoints share one SG; a rule belongs to one SG, not directly
  to multiple endpoints.
- **Diagnostic lesson:** IAM rejected the trust with `MalformedPolicyDocument`
  because a full Terraform service-account object was interpolated where a
  scalar was required. Referencing `unique_id` supplied the intended claim value.
  Terraform validation alone does not establish IAM policy validity.
- The failed apply left successfully created endpoints present and billable.
  Began preparing AWS CLI distribution to the private GCP workload; repeatable
  bootstrap through Cloud Storage was developed the following day.

## 2026-10-18

### Phase 5 - Cloud Storage bootstrap

- Created uniform-access bucket `multicloud-lab-test`, uploaded the AWS CLI ZIP
  and granted the VM service account `roles/storage.objectViewer`.
- Enabled Private Google Access and explicit route
  `0.0.0.0/0 -> default-internet-gateway`. **Routing lesson:** Private Google
  Access does not create routes. This combination reaches Google APIs from an
  internal-only VM but does not provide arbitrary Internet access without an
  external IP or Cloud NAT. Bucket IAM remained a separate authorization layer.
- Added a metadata startup script to download, extract and install AWS CLI.
  Guest-agent execution is root; absolute `/tmp` paths avoid dependence on the
  working directory. Startup logs showed a successful download and installation;
  a subsequent check reported AWS CLI `2.38.1` on Debian 12.
- Local journal evidence remained available despite Cloud Logging export lacking
  `logging.logEntries.create`. IPv4 checks were used for the IPv4-only subnet.

### Phase 5 - End-to-end completion

- **Complete, user-reported:** GCE obtained a metadata OIDC token, assumed
  `multicloud-lab-gcp-vm-role` through STS PrivateLink, then used temporary AWS
  credentials through S3 PrivateLink to list buckets/objects and download an
  object. No tokens, credentials or PSKs were committed.
- Last observed topology included VPN, two workloads, both Interface Endpoints
  and test buckets. Estimated total cost was `EUR 4-5/day`, plus variable storage,
  requests and transfer; cleanup requires user-run destroy and provider checks.
- Accepted limitations: broad IAM/default endpoint policies, single-AZ endpoint
  ENIs, both tunnels on GCP interface `0`, and no VPC Flow Logs yet.
- The local startup-script version/cleanup improvement was not applied and would
  replace GCE. **Next roadmap phase:** bounded cloud-native observability.

## 2026-10-19

### Workflow improvement - Iteration 1: methodical mentoring

- **Complete:** aligned `AGENTS.md` and existing OpenCode instructions around
  proactive primary-source guidance, same-iteration bibliography updates and
  journal maintenance grouped by date.
- Required evidence provenance and progressive, user-led diagnosis. Code-edit
  delegation never authorizes apply, destroy or cloud/state mutations.
- Corrected stale roadmap assumptions and clarified that cleanup does not reset
  completed learning phases. Instruction consistency and whitespace checks passed.

### Terraform review - Iteration 2: file organization

- **Complete:** user separated AWS endpoints into `aws-endpoints.tf`, GCP APIs
  into `gcp-services.tf`, and renamed storage bootstrap to `gcp-vm-bootstrap.tf`.
- Source comparison confirmed preserved resource labels, attributes and
  references; formatting and validation passed. HashiCorp's module/file semantics
  were recorded in `docs/references.md`.
- State listed no resources, so no live no-change plan was used as evidence;
  equivalence was checked in source. Empty state does not prove cloud cleanup.
  **Next:** introduce a small set of topology locals separately.

### Workflow improvement - Concise journal

- **Complete:** required journal detail to match learning value, retaining
  decisions, outcomes and consequential failures rather than execution logs.
- Applied the policy retrospectively across the journal, preserving chronology,
  historical results and meaningful diagnostic lessons. Consistency and whitespace
  checks passed. No infrastructure changes or live cost checks were performed.
