# Platform

OpenTofu-managed AWS foundation for the TodoList app: cost-conscious `dev` and `prod` EKS
environments (VPC, EKS, Aurora, ECR, secrets, ALB/DNS, cluster add-ons, Argo CD, and CI runners).
Prod mirrors dev's small footprint to demonstrate a promotion path, not scale.

## Documentation

Architecture, decisions (ADRs), the platform contract, the runbook, costs, and the hardening backlog
live in the **platform handbook** (the `platform-docs` repository). Start there. This repository keeps
only what is code-adjacent.

## Layout

```text
platform/
├── bootstrap/                # S3 remote-state bucket (separate lifecycle)
├── modules/                  # vpc, eks, rds, ecr, eso, alb, dns, arc, infra-runner,
│                             # app-secrets, metrics-server, cluster-autoscaler, argocd, argocd-app
├── environments/             # dev/ and prod/ roots (separate state keys)
├── .github/workflows/        # platform pipeline (plan on PR/push, apply on approval)
└── README.md
```

## Commands

```bash
tofu -chdir=environments/dev init -backend-config=backend.hcl
tofu -chdir=environments/dev plan
tofu fmt -check -recursive
tofu -chdir=environments/dev validate
```

- Apply/destroy require explicit authorization (protected remote state, cost).
- The pipeline runs `tofu plan` on PR/push and `tofu apply` on approval
  (`.github/workflows/platform.yml`).

## Conventions

- Remote state (S3 + native locking); never commit state, tfvars, or `backend.hcl`.
- Helm charts are vendored under each module's `charts/` (no network at plan time).
- No account IDs, ARNs, or secrets in committed files.
- One owner per Kubernetes object; the application pipeline never runs `tofu`.
- Helm releases use `atomic = true`; the state bucket is `prevent_destroy`.
- The EKS API endpoint is private by default; operators opt in with explicit CIDRs.
