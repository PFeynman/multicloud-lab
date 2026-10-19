# Cloud safety and cost rules

## Safety boundaries

- Never delete or alter resources merely because they appear unused.
- Only operate on resources clearly belonging to this repository/lab.
- Never use the AWS Default VPC.
- Never use or modify the user's pre-existing GCP API project.
- Confirm active AWS identity/profile and GCP account/project before impactful operations.
- Prefer explicit provider configuration and variables over ambient assumptions.
- Never put credentials, service-account keys, private SSH keys, access tokens, Terraform state, or sensitive tfvars in Git.
- Treat state, plans, logs and diagnostic output as potentially sensitive. Prefer targeted queries over broad state dumps. Never reproduce credentials, tokens, VPN PSKs, private keys or sensitive state values in responses, documentation or retained evidence; redact them before preservation.
- Do not expose SSH/RDP or arbitrary services to `0.0.0.0/0` unless explicitly justified and accepted.

## Cost philosophy

This is a learning lab, not a zero-cost lab. The objective is to keep costs reasonable, visible and controlled while allowing paid resources whenever they provide meaningful learning value.

Do not avoid, block, or overcomplicate a technically appropriate solution merely because it has a small cost. In particular, do not sacrifice observability or the realism of the networking exercise just to save a few cents.

When choosing between alternatives, use this priority:

1. Learning value.
2. Technical correctness.
3. Observability and ability to validate behavior.
4. Simplicity.
5. Cost.

Prefer the cheaper alternative when it provides approximately the same learning value, but do not optimize obsessively for zero cost. Paid resources such as VPN gateways, public IPv4 addresses, small VMs, VPC endpoints, Private Service Connect, flow logs, logging and monitoring are acceptable when useful to the lab.

## Cost awareness

For material estimates, state the region, currency/conversion assumption and
review date, and consult a primary pricing source. Label estimates as approximate
and record the source in `docs/references.md`.

Before introducing a resource with a meaningful recurring or variable cost, explain briefly:

- what is charged and how;
- its approximate hourly/daily cost or expected cost for the lab session;
- whether traffic, requests or logs introduce variable costs;
- whether it keeps generating cost while idle;
- what must be deleted to stop billing and whether `terraform destroy` removes it.

For resources costing only cents during a normal lab session, a short warning is enough. Do not repeatedly request approval for small expected costs.

Use these thresholds as guidance for newly introduced resources:

- `< EUR 1/day`: normal lab expense; proceed when technically justified.
- `EUR 1-5/day`: acceptable; mention the expected cost clearly.
- `EUR 5-10/day`: discuss the cost before deployment and consider alternatives.
- `> EUR 10/day`: stop and ask for explicit approval before deployment.

These thresholds apply to the expected cost of the resources being introduced, not historical accumulated lab spend. Highlight separately any variable cost that could unexpectedly scale beyond these ranges, especially log ingestion/retention and data egress.

Pay particular attention to Site-to-Site/Cloud VPN gateways and tunnels, NAT gateways/services, public IPv4 addresses, compute/disks, cross-cloud egress, CloudWatch/Cloud Logging, load balancers, AWS Interface VPC Endpoints/PrivateLink and GCP Private Service Connect.

Do not introduce expensive production-grade services when a substantially cheaper option teaches the same concept, unless comparing those services is itself the lesson.

## Cleanup is the primary cost-control mechanism

The normal lifecycle should be:

`terraform apply -> experiment -> observe -> document -> terraform destroy`

The goal is to avoid accidentally leaving resources running for days or weeks, not to avoid spending money during an active experiment.

Design resources so normal cleanup is possible with Terraform. After destruction, use provider CLI/API inventory and billing-relevant checks to verify that resources such as gateways, public IPs, disks, log sinks/groups and forwarding rules are gone.
