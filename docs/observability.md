# Observability and Evidence

## Current evidence

Phases 3-5 rely on several independent evidence sources:

| Evidence | What it proves | What it does not prove |
| --- | --- | --- |
| AWS/GCP tunnel and BGP state | IPsec and route exchange are established | Which tunnel carried one application request |
| Effective route tables | The next hop selected for a destination prefix | That security controls or the application succeed |
| Successful private ping | End-to-end ICMP reachability between workload IPs | Every intermediate hop or tunnel selection |
| Endpoint state and private ENI addresses | PrivateLink is provisioned inside the AWS subnet | That a particular request reached that ENI |
| STS assumed-role identity | OIDC trust and temporary credential exchange succeeded | Which network path carried the STS request by itself |
| Successful S3 operation | Credentials and S3 request were accepted | Private path selection without route/endpoint correlation |
| GCE startup journal and `aws --version` | The bootstrap script installed AWS CLI | The precise provider backbone path to Cloud Storage |

The private-path conclusion currently comes from correlation: no workload
public IPs, no AWS default Internet route, endpoint-specific DNS resolving to
`10.10.0.0/16`, the BGP route to that prefix, endpoint SG authorization and a
successful application response.

## Useful checks

Before testing, capture:

- source and destination private addresses;
- effective AWS and GCP routes;
- BGP peer and VPN tunnel state;
- Interface Endpoint state, DNS names, ENIs and private IPs;
- the expected IAM principal, without credentials or tokens.

After testing, record only non-secret results such as the assumed-role ARN,
credential expiration, bucket/object operation result, HTTP status, packet
loss and endpoint/tunnel metrics. Never store OIDC tokens, temporary access
keys, session tokens or VPN PSKs.

The GCE startup script can be inspected locally with:

```bash
sudo journalctl -u google-startup-scripts.service -b --no-pager
aws --version
```

## Phase 6 plan

Phase 6 will add deliberately scoped cloud-native telemetry:

- AWS VPC Flow Logs covering the EC2 and Interface Endpoint ENIs;
- CloudWatch queries correlating source, destination, port and action;
- GCP VPC Flow Logs for the workload subnet;
- Cloud Logging queries for the GCE-side flow;
- VPN tunnel byte/packet metrics sampled before and after a controlled test.

Sampling, aggregation and retention will be chosen before deployment to avoid
unbounded log ingestion. Flow logs can prove that each cloud observed a flow,
but they still do not expose every hop inside provider-managed S3, STS or VPN
services. Application results and route state remain complementary evidence.
