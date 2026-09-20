# Infrastructure documentation

Audience: engineers and AI agents working on the AWS foundation. Start here.

| Document | Purpose |
|---|---|
| [`runbook.md`](runbook.md) | Operational guide: provision, deploy, access, troubleshoot, teardown/recreate, recovery, and DEV-VERIFY evidence. |
| [`decisions.md`](decisions.md) | ADR-style decisions: ownership, region, sizing/budget, versions, Aurora, CI access, DNS/TLS, state/pipeline, add-ons, and secrets. |
| [`costs.md`](costs.md) | Cost drivers, estimates, and the budget model. |
| [`vendored-charts.md`](vendored-charts.md) | Helm chart sources, versions, and checksums. |
| [`hardening.md`](hardening.md) | FUTURE-HARDENING backlog: proposed improvements, each an individually approvable task. |

See the repository [`README.md`](../README.md) for the ownership boundary and layout, and
[`AGENTS.md`](../AGENTS.md) for agent-facing commands and conventions.

## Conventions
- English throughout.
- No account IDs, ARNs, or secrets in committed docs.
