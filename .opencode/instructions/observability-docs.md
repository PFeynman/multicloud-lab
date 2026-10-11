# Observability, evidence, diagrams, and documentation

## Network evidence

The goal is not merely connectivity; it is to understand and prove path selection.

For representative flows, preserve enough evidence to answer:

- What was the source and destination?
- Which route matched?
- Was the path private or public?
- Was the VPN tunnel healthy and carrying traffic?
- Did the destination cloud observe the corresponding flow?
- What can and cannot be concluded from each log/metric?

Use cloud-native telemetry progressively:

### AWS
- VPC Flow Logs
- CloudWatch Logs/queries where useful
- Site-to-Site VPN tunnel state and traffic metrics/logs when supported
- route tables and propagated routes

### GCP
- VPC Flow Logs
- Cloud Logging queries
- Cloud Monitoring VPN metrics
- Cloud VPN / Cloud Router state
- Network Intelligence Center capabilities when they add real diagnostic value

CLI tools (`curl`, `ping`, `ip route`, `traceroute`, `tcpdump`) are supporting evidence, not the only evidence.

Avoid excessive logging configuration for a tiny lab. Choose sampling, aggregation, filters, and retention consciously to keep costs low.

## Diagrams

Maintain Mermaid diagrams in `docs/architecture.md` or related docs.

Diagrams should show the details needed to reason about traffic:

- CIDRs/subnets
- route tables/routes
- gateways
- VPN tunnels
- Cloud Router/BGP when introduced
- workloads and relevant addresses
- public egress path

When useful, include a separate sequence/flow diagram for a private request and a public request.

## Lab journal

Append a concise entry to `docs/lab-journal.md` after each completed iteration containing:

- date/phase;
- objective;
- resources/configuration added or changed;
- concepts learned;
- decisions and rationale;
- commands/tests performed;
- telemetry/evidence observed;
- problems and diagnosis;
- approximate cost and resources still running;
- next proposed step.

Documentation should explain reasoning and evidence, not merely restate Terraform resources.

## Bibliography and external sources

Maintain `docs/references.md` as the project bibliography.

- Whenever an external technical link is shared with the user, add it to
  `docs/references.md` in the same iteration.
- Group references by phase and topic. Record the source title, canonical URL,
  why it is relevant and the date reviewed when behavior or pricing can change.
- Prefer primary sources such as official provider documentation, product
  documentation, pricing pages and Terraform Registry provider pages.
- Do not add search-result, redirect, session-specific or temporary URLs.
- Distinguish current provider recommendations from deliberate lab choices,
  especially when the lab uses a legacy or non-production topology for
  educational reasons.
- Keep the bibliography linked from `README.md`.
