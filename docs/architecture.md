# Architecture

## Phase 2 - private workloads and administrative access

AWS has a regional VPC CIDR. GCP has a global custom-mode VPC with a regional
subnet; `10.30.0.0/16` is a planning reservation, not a VPC attribute.

```mermaid
flowchart TB
  ADMIN["Administrator workstation"]

  subgraph AWS["AWS eu-west-2"]
    subgraph VPC["Lab VPC 10.10.0.0/16"]
      SUB["Subnet 10.10.0.0/24 - eu-west-2a"]
      EICE["EC2 Instance Connect Endpoint<br/>private ENI + EICE SG"]
      EC2["EC2 t4g.nano<br/>10.10.0.10, no public IP<br/>VM SG"]
      RT["Explicit route table<br/>10.10.0.0/16 -> local"]
      SUB -->|associated| RT
      EICE -->|"TCP/22, SG to SG"| EC2
    end
    DEFAULT["Default VPC 172.31.0.0/16 - out of scope"]
  end

  subgraph GCP["GCP multicloud-lab-prp"]
    IAP["IAP TCP forwarding<br/>35.235.240.0/20"]
    subgraph NET["Lab VPC - custom mode, global"]
      GS["Subnet 10.30.0.0/24 - europe-west2"]
      GR["Automatic subnet route: 10.30.0.0/24"]
      FW["Ingress firewall<br/>TCP/22 from IAP<br/>target tag: iap-ssh"]
      GCE["GCE e2-micro<br/>10.30.0.10, no public IP<br/>tag: iap-ssh"]
      GS --- GR
      FW --> GCE
    end
  end

  ADMIN -->|"AWS CLI + temporary SSH key"| EICE
  ADMIN -->|"gcloud SSH tunnel"| IAP
  IAP --> FW
```

No Internet default route, Internet gateway, NAT or VPN is deployed in either
lab network. GCP default Internet routes are deleted during network creation.
The VMs are reachable for administration only through provider-managed private
access paths; they cannot communicate with each other yet.

AWS DNS resolution is enabled and DNS hostnames are disabled. The GCP VPC uses
regional dynamic routing mode and MTU 1460; its subnet is IPv4-only and Private
Google Access is disabled. These values are explicit so later phases can show
which requirement causes each change.

## Administrative traffic flows

```mermaid
sequenceDiagram
  participant User as Administrator
  participant EICE as AWS EICE
  participant EC2 as EC2 10.10.0.10
  User->>EICE: AWS API authorization and SSH tunnel
  EICE->>EC2: TCP/22 from EICE private ENI
  Note over EICE,EC2: preserve_client_ip=false
  EC2-->>User: SSH through the established tunnel
```

The observed AWS SSH connection was
`10.10.0.205:22854 -> 10.10.0.10:22`. AWS confirmed that `10.10.0.205`
belonged to the endpoint ENI. The EICE and VM security groups reference each
other for TCP/22; no broad source CIDR is allowed.

```mermaid
sequenceDiagram
  participant User as Administrator
  participant IAP as GCP IAP proxy
  participant GCE as GCE 10.30.0.10
  User->>IAP: gcloud SSH with IAP tunnel
  IAP->>GCE: TCP/22 from 35.235.240.0/20
  GCE-->>User: SSH through the established tunnel
```

The observed GCP SSH connection was
`35.235.242.2:40383 -> 10.30.0.10:22`. The source belongs to the documented
IAP range and matched the firewall rule targeting the VM's `iap-ssh` tag.
Authentication currently uses temporary SSH keys in instance metadata; OS
Login remains a possible hardening iteration.

## Address plan

| Environment | CIDR | Status |
| --- | --- | --- |
| AWS VPC | `10.10.0.0/16` | Deployed |
| AWS subnet | `10.10.0.0/24` | Deployed |
| AWS VM | `10.10.0.10/32` | Deployed |
| GCP planning space | `10.30.0.0/16` | Reserved conceptually |
| GCP subnet | `10.30.0.0/24` | Deployed |
| GCP VM | `10.30.0.10/32` | Deployed |
| Azure VNet | `10.20.0.0/16` | Future phase |

Dual stack is deferred. Additional subnets can be introduced later; migration
to `for_each` should use `moved` blocks to preserve existing state addresses.
