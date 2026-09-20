# AGENTS.md

Guidance for AI coding agents working in this repository. Keep it short and accurate.

## What this is
OpenTofu-managed AWS foundation for the TodoList app: one cost-conscious `dev` EKS environment
(VPC, EKS, Aurora, ECR, secrets, ALB/DNS, cluster add-ons, and CI runners).

## Commands
- Init + plan:
  `tofu -chdir=environments/dev init -backend-config=backend.hcl && tofu -chdir=environments/dev plan`
- Format/validate: `tofu fmt -check -recursive` and `tofu -chdir=<root> validate`
- Apply/destroy require explicit authorization (protected remote state, cost).
- The pipeline runs `tofu plan` on PR and `tofu apply` on approval (`.github/workflows/infra.yml`).

## Layout
- `bootstrap/` — S3 state bucket (separate lifecycle).
- `modules/` — vpc, eks, rds, ecr, eso, alb, dns, arc, app-secrets, metrics-server, cluster-autoscaler, infra-runner.
- `environments/dev/` — the dev root.
- `docs/` — decisions, costs, vendored charts; start at `docs/README.md`.

## Conventions
- Remote state (S3 + native locking); never commit state, tfvars, or `backend.hcl`.
- Helm charts are vendored under each module's `charts/` (no network at plan time).
- No account IDs, ARNs, or secrets in committed files.
- One owner per Kubernetes object; the application pipeline never runs `tofu`.
- Helm releases use `atomic = true`; the state bucket is `prevent_destroy`.

## Safety
- The EKS API endpoint is private by default; operators opt in with explicit CIDRs.
- Teardown pauses app deploys and removes controller-owned load balancers before destroying the stack.
