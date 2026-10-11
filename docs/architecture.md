# Architecture

## Phase 3 - IPsec and dynamic routing control plane

AWS has a regional VPC CIDR. GCP has a global custom-mode VPC with a regional
subnet; `10.30.0.0/16` is a planning reservation, not a VPC attribute.
Nested boxes show resource scope. Solid arrows show network or control-plane
connections; dashed arrows show configuration attachments and peer mappings.

```mermaid
flowchart LR
  ADMIN["Administrator workstation"]

  subgraph AWS["AWS eu-west-2"]
    direction LR

    subgraph VPC_AWS["Lab VPC 10.10.0.0/16"]
      direction LR

      subgraph AWS_SUBNET["Private subnet 10.10.0.0/24 - eu-west-2a"]
        direction LR
        EICE["EC2 Instance Connect Endpoint<br/>private ENI"]
        EC2["EC2 instance<br/>t4g.nano<br/>10.10.0.10<br/>no public IP"]

        EICE -->|"SSH TCP/22"| EC2
      end

      EICE_SG["EICE security group<br/>egress TCP/22 to VM SG"]
      EC2_SG["VM security group<br/>ingress TCP/22 from EICE SG"]
      AWS_RT["Private route table<br/>associated subnet: 10.10.0.0/24<br/>10.10.0.0/16 -> local<br/>10.30.0.0/24 -> propagated VGW"]
      VGW["Virtual Private Gateway<br/>ASN 65433"]

      EICE_SG -.->|"attached"| EICE
      EC2_SG -.->|"attached"| EC2
      VGW -.->|"route propagation"| AWS_RT
    end

    CGW["Customer Gateway<br/>peer IP: GCP HA VPN interface 0<br/>ASN 65432"]
    VPN["Site-to-Site VPN connection<br/>2 AWS tunnel endpoints"]

    VGW -->|"AWS VPN endpoint"| VPN
    CGW -.->|"remote endpoint definition"| VPN
  end

  subgraph GCP["GCP project multicloud-lab-prp"]
    direction LR

    IAP["IAP TCP forwarding<br/>35.235.240.0/20<br/>provider-managed service"]

    subgraph VPC_GCP["Custom-mode VPC - 10.30.0.0/16 planning space"]
      direction LR

      subgraph GCP_SUBNET["Private subnet 10.30.0.0/24 - europe-west2"]
        GCE["Compute Engine instance<br/>e2-micro<br/>10.30.0.10<br/>no public IP<br/>tag: iap-ssh"]
      end

      GCP_ROUTE["Automatic subnet route<br/>10.30.0.0/24"]
      GCP_FW["Firewall allow-iap-ssh<br/>TCP/22 from 35.235.240.0/20"]
      HA_GW["HA VPN gateway - europe-west2<br/>interface 0 active<br/>interface 1 unused"]

      subgraph ROUTER["Cloud Router - europe-west2 - ASN 65432"]
        direction TB
        ROUTER_IF1["Router interface 1<br/>AWS tunnel 1 inside /30"]
        BGP_PEER1["BGP peer 1<br/>AWS ASN 65433"]
        ROUTER_IF2["Router interface 2<br/>AWS tunnel 2 inside /30"]
        BGP_PEER2["BGP peer 2<br/>AWS ASN 65433"]

        ROUTER_IF1 -->|"BGP"| BGP_PEER1
        ROUTER_IF2 -->|"BGP"| BGP_PEER2
      end

      GCP_FW -.->|"target tag iap-ssh"| GCE
    end

    EXT_GW["External VPN gateway<br/>interface 0: AWS tunnel 1 outside IP<br/>interface 1: AWS tunnel 2 outside IP"]
    TUNNEL1["GCP VPN tunnel 1 - europe-west2<br/>IKEv2 + IPsec<br/>HA VPN interface 0"]
    TUNNEL2["GCP VPN tunnel 2 - europe-west2<br/>IKEv2 + IPsec<br/>HA VPN interface 0"]

    TUNNEL1 -->|"HA VPN endpoint"| HA_GW
    TUNNEL2 -->|"HA VPN endpoint"| HA_GW
    EXT_GW -.->|"peer interface 0"| TUNNEL1
    EXT_GW -.->|"peer interface 1"| TUNNEL2
    TUNNEL1 -.->|"router attachment"| ROUTER_IF1
    TUNNEL2 -.->|"router attachment"| ROUTER_IF2

    subgraph GCP_SERVICES["Enabled project APIs - not in the traffic path"]
      SERVICE_USAGE["Service Usage API"]
      CRM["Cloud Resource Manager API"]
      COMPUTE_API["Compute Engine API"]
    end
  end

  ADMIN -->|"AWS CLI + temporary SSH key"| EICE
  ADMIN -->|"gcloud SSH tunnel"| IAP
  IAP -->|"SSH TCP/22 allowed by VPC firewall"| GCE
  VPN ==>|"IPsec tunnel 1 + BGP"| TUNNEL1
  VPN ==>|"IPsec tunnel 2 + BGP"| TUNNEL2
```

No Internet default route, Internet gateway or NAT is deployed in either lab
network. The VPN control plane is healthy and exchanges both cloud prefixes.
The VMs remain reachable for administration through EICE and IAP. Workload
traffic between them has not been authorized or tested yet.

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

## VPN control plane

```mermaid
sequenceDiagram
  participant GCP as Cloud Router ASN 65432
  participant T1 as IPsec tunnel 1
  participant T2 as IPsec tunnel 2
  participant AWS as VGW ASN 65433
  GCP->>T1: Advertise 10.30.0.0/24
  GCP->>T2: Advertise 10.30.0.0/24
  T1->>AWS: BGP established
  T2->>AWS: BGP established
  AWS-->>T1: Advertise 10.10.0.0/16
  AWS-->>T2: Advertise 10.10.0.0/16
```

Both tunnels terminate on GCP HA VPN interface `0` because one AWS Customer
Gateway can reference only one GCP outside IP. GCP therefore warns that the HA
VPN gateway is not fully redundant. This is expected: interface `1` remains
unused until a second AWS VPN connection adds tunnels 3 and 4.

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
