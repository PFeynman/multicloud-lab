# Observability, evidence, diagrams, and documentation

## Network evidence

The goal is not merely connectivity; it is to understand and prove path selection.

Distinguish directly observed results, user-reported evidence, configuration
intent and inference. Record the provenance of important conclusions. Do not
present a Terraform declaration, successful apply or historical observation as
proof of current runtime behavior.

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

Proactively update `docs/lab-journal.md` at the end of every substantive
iteration, including design, diagnosis, validation and blocked work. Do not wait
for a request or the end of a roadmap phase. Group entries by actual date:
reuse that day's heading and add clearly named iteration subsections, retaining
the order of events and the phase for each subsection. Preserve historical
entries; do not rewrite prior results to match later knowledge.

Use reliable conversation timestamps for historical work when available. Do not
infer activity dates from commits or file modification times. If a historical
date is unknown, say so or use the recording date explicitly. For explicit
read-only/no-edit requests, provide the proposed entry instead of editing.

Each iteration subsection should concisely capture the relevant items below
(omit inapplicable details rather than adding boilerplate):

- date/phase;
- objective;
- status: complete, in progress or blocked, and any missing evidence;
- resources/configuration added or changed;
- concepts learned;
- decisions and rationale;
- commands/tests performed;
- telemetry/evidence observed;
- problems and diagnosis;
- approximate cost and resources still running;
- next proposed step.

Label resources and costs as last observed, user-reported or currently verified.
An empty Terraform state is not by itself proof of cloud cleanup. Record only
commands actually run, results actually observed and user actions explicitly
reported. Mention updated document paths in the closing response. Do not create
an entry for every conversational turn or automatically commit documentation.

Documentation should explain reasoning and evidence, not merely restate Terraform resources.

## Bibliography and external sources

Maintain `docs/references.md` as the project bibliography.

Before introducing a new service, architectural choice, provider-specific
behavior, Terraform resource semantics or meaningful cost estimate, proactively
consult authoritative documentation. Give the user a small, relevant reading
list with canonical links, the sections to focus on and why they matter. Do not
wait for the user to request sources or replace explanation with a link dump.
Reuse already verified sources when applicable; recheck time-sensitive claims.
Distinguish documented behavior from inference, and disclose unavailable or
unverified sources rather than inventing support.

- Add every external technical source materially consulted or shared to
  `docs/references.md` in the same iteration, reusing existing entries instead
  of duplicating them. For explicit read-only/no-edit requests, provide the
  pending bibliography entries instead.
- Group references by phase and topic. Record the source title, canonical URL,
  why it is relevant and the date reviewed when behavior or pricing can change.
- Prefer primary sources such as official provider documentation, product
  documentation, pricing pages and Terraform Registry provider pages.
- Do not add search-result, redirect, session-specific or temporary URLs.
- Distinguish current provider recommendations from deliberate lab choices,
  especially when the lab uses a legacy or non-production topology for
  educational reasons.
- Keep the bibliography linked from `README.md`.
