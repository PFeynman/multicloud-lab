# Account Preparation

## AWS

The local profile `multicloud-lab` uses temporary credentials obtained with
`aws login` and targets `eu-west-2`. Its effective principal is currently the
IAM user `Administrator`; this is not the root user, but it still has broad
account permissions.

The preflight script verifies the lab account and rejects ambient AWS credential
environment variables because they could take precedence over the named profile.
By user decision, the provider does not set `allowed_account_ids`; run preflight
before Terraform operations.

Local Terraform state is intentionally retained for the initial phases. State
and backup files must use mode `0600`; this protects confidentiality on the
workstation but does not provide remote recovery or locking.

Authenticate or renew the session with:

```bash
aws login --profile multicloud-lab
```

The AWS Default VPC in London is explicitly out of scope:

- VPC CIDR: `172.31.0.0/16`
- Four default subnets with automatic public IPv4 assignment
- Internet Gateway and default route `0.0.0.0/0`
- Default security group

These default resources have no hourly cost while unused. They must not be
imported, referenced, changed or deleted by this lab.

## Google Cloud

The dedicated CLI configuration `multicloud-lab` selects:

- Account: the human account used during Phase 0
- Project: `multicloud-lab-prp`
- Region: `europe-west2`

Terraform authenticates with user Application Default Credentials. The ADC
quota project is `multicloud-lab-prp`. ADC is stored outside this repository at
the standard gcloud location and must never be committed.

Preflight verifies the gcloud account, project and region, then checks the ADC
account and quota project independently. This matters because Terraform reads
ADC directly and does not authenticate through the active gcloud configuration.

Google enabled a set of default APIs when the project was created, including
Cloud Logging, Cloud Monitoring, Cloud Storage and BigQuery-related APIs. They
were retained because API availability alone has no cost and they are managed
project defaults. Terraform declares Compute Engine, Service Usage and Cloud
Resource Manager APIs. The latter two use the google.bootstrap provider with
user_project_override=false to avoid quota-project bootstrap dependencies.
Cloud Resource Manager was initially enabled with gcloud during recovery;
its required enablement is now represented in Terraform. All three APIs remain
enabled after destroying the lab networks.

Cloud changes must use Terraform. Use a mutating CLI command only if necessary
and no viable Terraform solution exists; explain the limitation first.
See [Google Terraform bootstrap guidance](https://firebase.google.com/docs/projects/terraform/get-started)
for the provider-without-quota-override pattern.

## Security Boundary

The chosen initial model uses temporary human credentials rather than role or
service-account impersonation. Explicit account and project values protect
against accidental targeting, but they do not provide least-privilege IAM.
This tradeoff is accepted for the initial personal lab and should be revisited
before treating the setup as a production pattern.
