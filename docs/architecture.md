# Architecture

## Phase 5 - Private service access and workload federation

AWS uses VPC CIDR `10.10.0.0/16`; GCP uses a global custom-mode VPC with a
regional `10.30.0.0/24` subnet. The two networks exchange routes through two
IPsec tunnels and BGP. Phase 4 proved workload connectivity. Phase 5 adds
private access to S3 from both clouds and federates the GCE workload identity
into AWS without storing long-lived AWS credentials.

```mermaid
flowchart LR
  ADMIN["Administrator"]

  subgraph AWS["AWS eu-west-2"]
    S3["Amazon S3<br/>private test bucket"]

    subgraph AWS_VPC["VPC 10.10.0.0/16"]
      subgraph AWS_SUBNET["Private subnet 10.10.0.0/24 - eu-west-2a"]
        EC2["EC2 t4g.nano<br/>10.10.0.10<br/>no public IP<br/>IAM instance profile"]
        EICE["EC2 Instance Connect Endpoint"]
        S3_ENI["S3 Interface Endpoint ENI<br/>TCP/443 from 10.30.0.0/24"]
        STS_ENI["STS Interface Endpoint ENI<br/>TCP/443 from 10.30.0.0/24"]
      end

      AWS_RT["Private route table<br/>10.10.0.0/16 -> local<br/>10.30.0.0/24 -> VGW<br/>S3 prefix list -> Gateway Endpoint"]
      S3_GW["S3 Gateway Endpoint"]
      VGW["Virtual Private Gateway<br/>ASN 65433"]
    end

    AWS_ROLE["Federated IAM role<br/>Google OIDC trust<br/>temporary S3 permissions"]
    AWS_EC2_ROLE["EC2 IAM role<br/>S3 permissions"]
    VPN["Site-to-Site VPN<br/>two IPsec tunnels"]

    EICE -->|"SSH TCP/22"| EC2
    EC2 -->|"HTTPS using instance profile"| S3_GW
    S3_GW --> S3
    AWS_EC2_ROLE -.->|"instance profile"| EC2
    S3_ENI --> S3
    STS_ENI --> AWS_ROLE
    VGW --> VPN
    VGW -.->|"route propagation"| AWS_RT
    S3_GW -.->|"prefix-list route"| AWS_RT
  end

  subgraph GCP["GCP project multicloud-lab-prp"]
    GCS["Cloud Storage bucket<br/>awscliv2.zip"]
    IAP["IAP TCP forwarding"]

    subgraph GCP_VPC["Custom VPC - 10.30.0.0/16 planning space"]
      subgraph GCP_SUBNET["Subnet 10.30.0.0/24 - europe-west2<br/>Private Google Access enabled"]
        GCE["GCE e2-micro<br/>10.30.0.10<br/>no public IP<br/>GCP service account"]
      end

      GCP_RT["Effective routes<br/>10.10.0.0/16 -> VPN/BGP<br/>0.0.0.0/0 -> default internet gateway"]
      HA_GW["HA VPN gateway<br/>interface 0 active<br/>interface 1 unused"]
      ROUTER["Cloud Router<br/>ASN 65432<br/>two BGP peers"]
    end
  end

  ADMIN -->|"IAP SSH"| GCE
  ADMIN -->|"EICE SSH"| EICE
  GCE -->|"Private Google Access"| GCS
  GCE ==>|"HTTPS to endpoint private IP over VPN"| VPN
  VPN ==> S3_ENI
  VPN ==> STS_ENI
  VPN ==>|"two tunnels and BGP"| HA_GW
  HA_GW --- ROUTER
```

The diagram shows logical service flows rather than every IAM or firewall
attachment. Both Interface Endpoints use one ENI in `eu-west-2a` and share a
security group accepting TCP/443 from `10.30.0.0/24`. Private DNS is disabled,
so the GCP client uses endpoint-specific DNS names. This single-AZ layout is
appropriate for the lab but is not a production availability design.

## Phase 4 workload flow

```mermaid
sequenceDiagram
  participant EC2 as EC2 10.10.0.10
  participant VPN as IPsec VPN and BGP routes
  participant GCE as GCE 10.30.0.10
  EC2->>VPN: ICMP echo request to 10.30.0.10
  VPN->>GCE: GCP firewall permits ICMP from 10.10.0.0/24
  GCE-->>VPN: Stateful echo reply
  VPN-->>EC2: AWS security group permits return traffic
  GCE->>VPN: ICMP echo request to 10.10.0.10
  VPN->>EC2: AWS security group permits ICMP from 10.30.0.0/24
  EC2-->>GCE: Stateful echo reply
```

The successful tests prove private workload reachability and correct security
controls. Route and tunnel state correlate the path, but packet-level proof is
deferred until VPC Flow Logs are enabled in Phase 6.

## EC2 to S3

```mermaid
sequenceDiagram
  participant EC2 as EC2 10.10.0.10
  participant IMDS as AWS IMDSv2
  participant GW as S3 Gateway Endpoint
  participant S3 as Amazon S3
  EC2->>IMDS: Obtain instance-profile credentials
  EC2->>GW: HTTPS selected by S3 prefix-list route
  GW->>S3: Authorized S3 API request
  S3-->>EC2: Bucket or object response
```

The EC2 security group permits HTTPS egress to the S3 managed prefix list. The
Gateway Endpoint is associated with the private subnet route table and has no
hourly endpoint charge. Gateway Endpoints are not transitive through a VPN, so
this path cannot serve the GCP workload.

## GCP federation and S3

```mermaid
sequenceDiagram
  participant GCE as GCE 10.30.0.10
  participant MDS as GCP metadata server
  participant VPN as IPsec VPN
  participant STS as STS Interface Endpoint
  participant IAM as AWS federated role
  participant S3EP as S3 Interface Endpoint
  participant S3 as Amazon S3

  GCE->>MDS: Request identity token for lab audience
  MDS-->>GCE: Google-signed OIDC token
  GCE->>VPN: HTTPS to endpoint-specific STS DNS
  VPN->>STS: AssumeRoleWithWebIdentity
  STS->>IAM: Validate aud, oaud and sub conditions
  IAM-->>GCE: Temporary AWS credentials
  GCE->>VPN: S3 request using temporary credentials
  VPN->>S3EP: HTTPS to endpoint-specific S3 DNS
  S3EP->>S3: Authorized bucket operation
  S3-->>GCE: Bucket or object response
```

The AWS trust pins the Google service account numeric identity and custom
audience. No static AWS key and no customer-managed AWS OIDC provider are
needed for the built-in `accounts.google.com` provider. Tokens and temporary
credentials are deliberately absent from repository files and documentation.

## GCP startup bootstrap

```mermaid
sequenceDiagram
  participant Agent as GCE guest agent running as root
  participant PGA as Private Google Access
  participant GCS as Cloud Storage
  participant Disk as VM temporary filesystem

  Agent->>PGA: gcloud storage cp over HTTPS
  PGA->>GCS: Fetch awscliv2.zip with VM service account
  GCS-->>Disk: AWS CLI archive
  Agent->>Disk: Extract and install under /usr/local
  Agent->>Disk: Remove temporary archive and directory
```

The startup script runs as root from a transient metadata-script location and
uses absolute paths under `/tmp`. The VM service account has
`roles/storage.objectViewer` on the bootstrap bucket. The explicit default
route and Private Google Access make Google API destinations reachable without
assigning a public IP. They do not provide general Internet access without an
external IP or Cloud NAT.

## Security and availability scope

- The S3 IAM policy intentionally grants broad `s3:*` access for this ephemeral
  learning iteration. It is not a least-privilege production example.
- The VPC endpoints currently use their default permissive endpoint policies.
- The Interface Endpoint security group accepts the whole GCP lab subnet.
- Both Interface Endpoints and both initial VPN tunnels lack the complete
  multi-AZ/multi-interface topology expected from a production design.
- Cloud-native flow telemetry is not enabled yet; application success plus
  routing and endpoint state cannot prove every packet hop by themselves.

## Address plan

| Environment | CIDR | Role |
| --- | --- | --- |
| AWS VPC | `10.10.0.0/16` | Deployed AWS address space |
| AWS subnet | `10.10.0.0/24` | EC2 and endpoint ENIs |
| AWS VM | `10.10.0.10/32` | Test workload |
| GCP planning space | `10.30.0.0/16` | Conceptual reservation |
| GCP subnet | `10.30.0.0/24` | Regional workload subnet |
| GCP VM | `10.30.0.10/32` | Test workload |
| Azure VNet | `10.20.0.0/16` | Reserved for Phase 10 |
